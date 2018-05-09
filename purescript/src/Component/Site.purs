module Component.Site 
  ( Effects
  , Query(..)
  , Stage(..)
  , component
  , module Component.Common
  ) where

import Prelude

import Component.CharacterSelect as Select
import Component.Play            as Play
import Halogen                   as HH
import Halogen.HTML              as H
import Halogen.HTML.Events       as E
import Network.HTTP.Affjax       as AX

import Data.Argonaut.Generic.Aeson (decodeJson)
import Control.Monad.Aff           (Aff)
import Data.Argonaut.Parser        (jsonParser)
import Data.Array                  ((:), intercalate, reverse)
import Data.Either         
import Data.Maybe          
import Data.Time.Duration          (Milliseconds(..))
import Halogen                     (Component, ParentDSL, ParentHTML)
import Halogen.HTML                (HTML)
import Network.HTTP.Affjax         (AJAX)

import FFI.Import                  (bg)
import FFI.Progress                (ANIMATION, progress)
import FFI.Sound                   (AUDIO, Sound(..), sound)

import Operators
import Structure           
import Component.Common    

type Effects e = (animation ∷ ANIMATION, ajax ∷ AJAX, audio ∷ AUDIO | e)

data Query a = HandleQueue Select.Selection a 
             | HandleGame  Play.Output      a
             | ReceiveMsg  SocketMsg        a

data ChildSlot = SelectSlot | PlaySlot
derive instance eqChildSlot  ∷ Eq ChildSlot
derive instance ordChildSlot ∷ Ord ChildSlot

data Stage = Waiting | Queueing | Playing | Practicing
derive instance eqStage ∷ Eq Stage

type State = { stage    ∷ Stage
             , gameInfo ∷ Either String GameInfo
             }

component ∷ ∀ m. Component HTML Query Unit SocketMsg (Aff (Effects m))
component =
  HH.parentComponent
    { initialState: const initialState
    , render
    , eval
    , receiver: const Nothing
    }
  where
  initialState ∷ State
  initialState = { stage:    Waiting
                 , gameInfo: Left ""
                 }

  render ∷ State → ParentHTML Query ChildQuery ChildSlot (Aff (Effects m))
  render {gameInfo, stage} = contents $ case gameInfo of
    Right gameInfo' → 
      [ H.img [_i "bg", _src bg ]
      , H.slot PlaySlot (Play.component (stage ≡ Practicing) gameInfo') 
                        unit (E.input HandleGame)
      ]
    Left error → 
      [ H.span [_c "error"] [H.text error]
      , H.slot SelectSlot Select.component unit (E.input HandleQueue)
      ]
    where contents | stage ≡ Queueing = H.div [_i "contents", _c "queueing"] 
                                      ∘ (H.div [_i "searching"] 
                                        [H.img [_src "/img/spin.gif"]]:_)
                   | otherwise        = H.div [_i "contents"]
  eval ∷ Query ~> ParentDSL State Query ChildQuery ChildSlot SocketMsg (Aff (Effects m))
  eval = case _ of
      HandleQueue (Select.Queued Practice team) next → do
        let teamList = intercalate "/" ∘ reverse $ characterName_ ↤ team
        {response} ← HH.liftAff $ AX.get ("/api/practicequeue/" ⧺ teamList)
        HH.modify _{ gameInfo = decodeJson response, stage = Practicing }
        HH.liftEff $ progress (Milliseconds 0.0) 1 1
        sound SFXStartFirst
        pure next
      HandleQueue (Select.Queued Quick team) next → do
        let teamList = intercalate "/" ∘ reverse $ characterName_ ↤ team
        HH.modify _{ stage = Queueing }
        sound SFXApplySkill
        HH.raise $ SocketMsg teamList
        pure next
      HandleQueue _ next →
        pure next
      HandleGame (Play.Finish _) next → do
        HH.modify _{ gameInfo = Left "", stage = Waiting }
        pure next
      HandleGame (Play.ActMsg msg) next → do
        HH.raise msg
        pure next
      ReceiveMsg (SocketMsg msg) next → do
        {stage} ← HH.get
        case stage of
          Queueing → do
            let result = jsonParser msg ≫= decodeJson
            HH.modify _{ gameInfo = result
                       , stage    = Playing 
                       }
            case result of
              Left _ → pure next
              Right (GameInfo {gamePar}) → do
                HH.liftEff $ progress turnTime (1 - gamePar) gamePar
                sound SFXStartFirst
                pure next
          Playing → do
            case jsonParser msg ≫= decodeJson of
              Left _ → pure next
              Right (game ∷ Game) → do
                _ ← HH.query PlaySlot (QueryPlay (ReceiveGame game) next)
                pure next
          _ → pure next 

turnTime ∷ Milliseconds
turnTime = Milliseconds 60000.0
