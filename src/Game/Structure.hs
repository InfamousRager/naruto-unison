{-# LANGUAGE DeriveGeneric, DeriveAnyClass, FlexibleInstances #-}

-- | Data structures for gameplay.
module Game.Structure
  ( half, sync
  , teamSize, gameSize, gameIndices
  , Transform, TrapTransform
  , TurnBased(..), decrTurn
  , Labeled(..), lEq, lMatch
  , Affected(..)
  , Class(..), allClasses
  , Copied(..)
  , Effect(..), helpful, sticky, boost
  , Target(..)
  , four0s
  , Ninja(..), newNinja, ninjaReset, insertCd, adjustCd
  , Face(..)
  , Game(..), newGame, setTime, gameNinja, setNinja, fn
  , Skill(..), newSkill, Requirement(..)
  , Character(..)
  , ChannelTag(..)
  , Act(..), ActPath(..), actFromPath
  , Chakras(..), χØ, ChakraType(..)
  , Channel(..), Channeling(..), isAction, isControl, isOngoing
  , Defense(..), Barrier(..)
  , Delay(..)
  , Slot, allied, allies, alliesP, alliedP, enemies, enemiesP, spar
  , Status(..), Bomb(..), Copying(..)
  , Player(..)
  , Trap(..), TrapType(..), Trigger(..)
  , Variant(..), variantCD, noVariant
  , Victor(..)
  , allSlots, allySlots, enemySlots, opponentSlots
  , bySlot, outSlot, outSlot', choose, skillTargets
  , botActs
  ) where
  
import qualified Data.Sequence as S
import qualified Data.Text as T

import GHC.Generics
import Data.Aeson
import Data.Foldable
import Data.List
import Data.Maybe      (maybeToList)
import Data.Sequence   (adjust', fromList, index, Seq, update)
import Data.Text       (splitOn, Text)
import Data.Text.Read
import Data.Time.Clock
import Yesod           (PathPiece, toPathPiece, fromPathPiece)

import Calculus
import Core.Model
import Core.Unicode

teamSize ∷ Int -- ^ Each player controls 3 'Ninja's.
teamSize = 3
gameSize ∷ Int -- ^ There are 6 total 'Ninja's in a game.
gameSize = teamSize * 2 
gameIndices ∷ [Int]
gameIndices = [0..gameSize-1]

half ∷ Int → Int -- ^ Converts from per-player sub-turns to total turns.
half = uncurry (+) ∘ (`quotRem` 2) ∘ abs 

sync ∷ Int → Int -- ^ Converts from total turns to per-player sub-turns.
sync n
  | n ≥ 0     = 2 * n
  | otherwise = (-2) * n - 1

-- | The type signature of game actions. Processed into 'Game' → 'Game'.
type Transform = ( Skill -- Skill
                 → Slot  -- Source (Src)
                 → Slot  -- Actor  (C)
                 → Game  -- Before
                 → Slot  -- Target (T)
                 → Game  -- After
                 )

-- | The type signature of 'Trap' actions.
type TrapTransform = ( Int  -- Amount (optional argument for traps)
                      → Slot -- Source (optional argument for traps)
                      → Game -- Before
                      → Game -- After
                      )

-- | A type that decreases every turn.
class TurnBased a where
    getDur ∷ a → Int     
    setDur ∷ Int → a → a  

decrTurn ∷ TurnBased a ⇒ a → Maybe a
decrTurn a
  | dur ≡ 0   = Just a
  | dur ≤ 1   = Nothing
  | otherwise = Just $ setDur (dur - 1) a
  where dur = getDur a

class Labeled a where
    getL   ∷ a → Text
    getSrc ∷ a → Slot

lEq ∷ Labeled a ⇒ a → a → Bool
lEq a b = getL a ≡ getL b ∧ getSrc a ≡ getSrc b

lMatch ∷ Labeled a ⇒ Text → Slot → a → Bool
lMatch l src a = getL a ≡ l ∧ getSrc a ≡ src

-- | Qualifiers of 'Skill's and 'Status'es.
data Class = Invisible
           | InvisibleTraps
           | Soulbound
           -- Tags
           | Bane
           | Summon
           -- Distance
           | Melee
           | Ranged
           -- Type
           | Chakra
           | Physical
           | Mental
           -- Limits
           | Nonstacking
           | Single
           | Multi
           | Extending
           -- Prevention
           | Bypassing
           | Uncounterable
           | Unreflectable
           | Unremovable
           | Necromancy
           -- Fake (Hidden)
           | All
           | Hidden
           | Affliction
           | NonAffliction
           | NonMental
           | Shifted
           | Unshifted
           | Direct
           | BaseTrap
           | NewRandoms
           -- Chakra (Hidden)
           | Bloodline
           | Genjutsu
           | Ninjutsu
           | Taijutsu
           | Random
           deriving (Enum, Eq, Show, Bounded)

show' ∷ Class → String
show' NonMental       = "Non-mental"
show' NonAffliction   = "Non-affliction"
show' InvisibleTraps  = show Invisible
show' a               = show a

cJson ∷ Class → String
cJson InvisibleTraps  = cJson Invisible
cJson a               = show a

lower ∷ String → String
lower = T.unpack ∘ T.toLower ∘ T.pack

instance ToJSON Class where toJSON = toJSON ∘ cJson
allClasses ∷ [Class] -- ^ Enumerated list of 'Class'es
allClasses = [minBound .. maxBound]

-- | Effects of 'Status'es.
data Effect = Afflict    !Int        -- ^ Deals damage every turn
            | AntiCounter            -- ^ Cannot be countered or reflected
            | Bleed      !Class !Int -- ^ Adds to damage received
            | Bless      !Int        -- ^ Adds to healing 'Skill's
            | Block                  -- ^ Treats source as 'Immune'
            | Boost      !Int        -- ^ Scales effects from allies
            | Build      !Int        -- ^ Adds to destructible defense 'Skill'
            | Counter    !Class      -- ^ Counters the first 'Skill's
            | CounterAll !Class      -- ^ 'Counter's without being removed
            | Duel                   -- ^ 'Immune' to everyone but source
            | Endure                 -- ^ Health cannot go below 1
            | Enrage                 -- ^ Ignore status effects
            | Exhaust    !Class      -- ^ 'Skill's cost an additional random chakra
            | Expose                 -- ^ Cannot reduce damage or be 'Immune'
            | Focus                  -- ^ Immune to 'Stun's
            | Heal       !Int        -- ^ Heals every turn
            | Immune     !Class      -- ^ Invulnerable to enemy 'Skill's
            | ImmuneSelf             -- ^ Immune to internal damage
            | Isolate                -- ^ Unable to affect others
            | Link       !Int        -- ^ Increases damage and healing from source
            | Nullify    !Effect     -- ^ Prevents effects from being applied
            | Parry      !Class !Int -- ^ 'Counter' and trigger a 'Skill'
            | ParryAll   !Class !Int -- ^ 'Parry's without being removed
            | Pierce                 -- ^ Damage skills turn into piercing
            | Plague                 -- ^ Immune to healing and curing
            | Reduce     !Class !Int -- ^ Reduces damage by a flat amount
            | Reapply                -- ^ Shares harmful skills with source
            | Redirect   !Class      -- ^ Transfers harmful 'Skill's
            | Reflect                -- ^ Reflects the first 'Skill'
            | ReflectAll             -- ^ 'Reflect' without being removed
            | Restrict               -- ^ Forces AoE attacks to be single-target
            | Reveal                 -- ^ Makes 'Invisible' effects visible
            | Scale      !Class !Rational -- ^ Scales damage dealt
            | Seal                   -- ^ Immune to friendly 'Skill's
            | Share                  -- ^ Shares all harmful non-damage effects
            | Silence                -- ^ Unable to cause non-damage effects
            | Snapshot   !Ninja      -- ^ Saves a snapshot of the current state
            | Snare      !Int        -- ^ Increases cooldowns
            | SnareTrap  !Class !Int -- ^ Negates next skill and increases CD
            | Strengthen !Class !Int -- ^ Adds to all damage dealt
            | Stun       !Class      -- ^ Unable to use 'Skill's
            | Swap       !Class      -- ^ Target swaps enemies and allies
            | Taunt                  -- ^ Forced to attack the source
            | Uncounter              -- ^ Cannot counter or reflect
            | Unexhaust              -- ^ Decreases chakra costs by 1 random  
            | Unreduce   !Int        -- ^ Reduces damage reduction 'Skill's
            | Ward       !Class !Rational -- ^ Reduces damage by a fraction
            | Weaken     !Class !Int -- ^ Lessens damage dealt
            -- | Copies a skill into source's skill slot
            | Copy { copyDuration ∷ !Int 
                   , copyClass    ∷ !Class
                   , copyTo       ∷ !Int   -- ^ skill slot of source to copy into
                   , copyNonHarm  ∷ !Bool  -- ^ includes non-harmful 'Skill's
                   }
            deriving (Eq)

low ∷ Class → String
low = lower ∘ show'

instance Show Effect where
    show (Afflict a) = "Receives " ⧺ show a ⧺ " affliction damage each turn."
    show AntiCounter = "Cannot be countered or reflected."
    show (Bleed clas a)
      | a ≥ 0 = show a ⧺ " additional damage taken from " ⧺ low clas ⧺ " skills."
      | otherwise = "Reduces all " ⧺ low clas ⧺  " damage received by " ⧺ show (-a) ⧺ "."
    show (Bless a) = "Healing skills heal an additional " ⧺ show a ⧺ " health."
    show Block = "Unable to affect the source of this effect."
    show (Boost a) = "Active effects from allies are " ⧺ show a ⧺ " times as powerful." 
    show (Build a)
      | a ≥ 0     = "Destructible skills provide " ⧺ show a ⧺ " additional points of defense."
      | otherwise =  "Destructible skills provide " ⧺ show (-a) ⧺ " fewer points of defense."
    show (Copy _ clas _ _) = show' clas ⧺ " skills will be temporarily acquired by the source of this effect."
    show (Counter All)  = "Counters the first skill."
    show (Counter clas) = "Counters the first " ⧺ low clas ⧺ "skill."
    show (CounterAll All) = "Counters all skills."
    show (CounterAll clas) = "Counters all " ⧺ low clas ⧺ "skills."
    show Duel = "Invulnerable to everyone but the source of this effect."
    show Endure = "Health cannot go below 1."
    show Enrage = "Ignores harmful status effects other than chakra cost changes."
    show (Exhaust clas) = show' clas ⧺ " skills cost 1 additional random chakra."
    show Expose = "Unable to reduce damage or become invulnerable."
    show Focus = "Immune to stuns."
    show (Heal a) = "Gains " ⧺ show a ⧺ " health each turn."
    show (Immune clas) = "Invulnerable to " ⧺ low clas ⧺ " skills."
    show ImmuneSelf = "Immune to self-damage."
    show Isolate = "Unable to affect others."
    show (Link a) = "Receives " ⧺ show a ⧺ " additional damage from the source of this effect."
    show (Nullify _) = "Protected from certain effects."
    show (Parry All _) = "Counters the first skill."
    show (Parry clas _) = "Counters the first " ⧺ low clas ⧺ " skill." 
    show (ParryAll All _) = "Counters all skill."
    show (ParryAll clas _) = "Counters all " ⧺ low clas ⧺ " skills." 
    show Pierce = "Non-affliction skills deal piercing damage."
    show Plague = "Cannot be healed or cured."
    show Reapply = "Harmful skills received are also reflected to the source of this effect."
    show (Reduce clas a) 
        | a ≥ 0     = "Reduces " ⧺ low clas ⧺ " damage received by " ⧺ show a ⧺ ". Does not affect piercing or affliction damage."
        | otherwise = "Increases " ⧺ low clas ⧺ " damage received by " ⧺ show (-a) ⧺ ". Does not affect piercing or affliction damage."
    show (Redirect clas) = "Redirects " ⧺ low clas  ⧺ " harmful skills to the source of this effect."
    show Reflect = "Reflects the first harmful non-mental skill."
    show ReflectAll = "Reflects all non-mental skills."
    show Reveal = "Reveals invisible skills to the enemy team. This effect cannot be removed."
    show Restrict = "Skills that normally affect all opponents must be targeted."
    show (Scale clas a)
      | a ≥ 1 = show' clas ⧺ " damage multiplied by " ⧺ show a ⧺ "."
      | otherwise = show' clas ⧺ " damage multiplied by " ⧺ show a ⧺ ". Does not affect affliction damage."
    show Seal = "Immune to effects from allies."
    show Share = "If a harmful non-damage effect is received, it is also applied to the source of this effect."
    show Silence = "Unable to cause non-damage effects."
    show (Snare a)
        | a ≥ 0 = "Cooldowns increased by " ⧺ show a ⧺ "."
        | otherwise = "Cooldowns decreased by " ⧺ show (-a) ⧺ "."
    show (SnareTrap _ _) = "Next skill used will be negated and go on a longer cooldown."
    show (Snapshot _) = "Will be restored to an earlier state when this effect ends."
    show (Strengthen clas a) = show' clas ⧺ " damaging skills deal " ⧺ show a ⧺ " additional damage."
    show (Stun Affliction) = "Unable to deal affliction damage."
    show (Stun NonAffliction) = "Unable to deal non-affliction damage."
    show (Stun clas) = "Unable to use " ⧺ low clas ⧺ " skills."
    show (Swap clas) = "Next " ⧺ low clas ⧺ " skill will target allies instead of enemies and enemies instead of allies."
    show Taunt = "Forced to target the source of this effect."
    show Uncounter = "Unable to benefit from counters or reflects."
    show Unexhaust = "All skills cost 1 fewer random chakra."
    show (Unreduce a) = "Damage reduction skills reduce " ⧺ show a ⧺ " fewer damage."
    show (Ward clas a) = "Reduces " ⧺ low clas ⧺ " damage received by " ⧺ show (100 * a) ⧺ ". Does not affect piercing or affliction damage."
    show (Weaken clas a) = show' clas ⧺ " skills deal " ⧺ show a ⧺ " fewer damage. Does not affect affliction damage."
instance ToJSON Effect where 
    toJSON a = object
      [ "effectDesc"    .= tshow a 
      , "effectHelpful" .= helpful a
      , "effectSticky"  .= sticky a 
      , "effectTrap"    .= False
      ]

helpful ∷ Effect → Bool
helpful (Afflict _)      = False
helpful AntiCounter      = True
helpful (Bleed _ a)      = a < 0
helpful (Bless _)        = True
helpful Block            = False
helpful (Boost _)        = True
helpful (Build a)        = a > 0
helpful (Copy _ _ _ _)   = False
helpful (Counter All)    = True
helpful (Counter _)      = True
helpful (CounterAll All) = True
helpful (CounterAll _)   = True
helpful Duel             = True
helpful Endure           = True
helpful Enrage           = True
helpful (Exhaust _)      = False
helpful Expose           = False
helpful Focus            = True
helpful (Heal _)         = True
helpful (Immune _)       = True
helpful ImmuneSelf       = True
helpful Isolate          = False
helpful (Link _)         = False
helpful (Nullify _)      = False
helpful (Parry All _)    = False
helpful (Parry _ _)      = True
helpful (ParryAll All _) = True
helpful (ParryAll _ _)   = True
helpful Pierce           = True
helpful Plague           = False
helpful Reapply          = False
helpful (Reduce _ a)     = a > 0
helpful (Redirect _)     = True
helpful Reflect          = True
helpful ReflectAll       = True
helpful Restrict         = False
helpful Reveal           = False
helpful (Scale _ a)      = a ≥ 1
helpful Seal             = False
helpful Share            = False
helpful Silence          = False
helpful (Snapshot _)     = True
helpful (Snare a)        = a < 0
helpful (SnareTrap _ _)  = False
helpful (Strengthen _ _) = True
helpful (Stun _)         = False
helpful (Swap _)         = False
helpful Taunt            = False
helpful (Unreduce _)     = False
helpful Uncounter        = False
helpful Unexhaust        = True
helpful (Ward _ _)       = True
helpful (Weaken _ _)     = False

sticky ∷ Effect → Bool
sticky Block            = True
sticky (Copy _ _ _ _)   = True
sticky (Counter All)    = True
sticky (Counter _)      = True
sticky (CounterAll All) = True
sticky (CounterAll _)   = True
sticky Enrage           = True
sticky (Immune _)       = True
sticky (Parry All _)    = True
sticky (Parry _ _)      = True
sticky (ParryAll All _) = True
sticky (ParryAll _ _)   = True
sticky (Redirect _)     = True
sticky Reapply          = True
sticky Reflect          = True
sticky ReflectAll       = True
sticky Restrict         = True
sticky Reveal           = True
sticky (Snapshot _)     = True
sticky (Swap _)         = True
sticky _                = False

boost ∷ Int → Effect → Effect
boost b (Afflict      a) = Afflict      $ a * b
boost b (Bleed      c a) = Bleed      c $ a * b
boost b (Build        a) = Build        $ a * b
boost b (Heal         a) = Heal         $ a * b
boost b (Reduce     c a) = Reduce     c $ a * b
boost b (Snare        a) = Snare        $ a * b
boost b (Strengthen c a) = Strengthen c $ a * b
boost b (Unreduce     a) = Unreduce     $ a * b
boost b (Ward       c a) = Ward       c $ a * (toRational b)
boost b (Weaken     c a) = Weaken     c $ a * b
boost _ ef = ef

four0s ∷ Seq Int -- ^ [0, 0, 0, 0]
four0s = S.replicate 4 0

-- | A single action of a 'Ninja'.
data Act = Act { actC ∷ !Slot               -- ^ self index (0-5)
               , actS ∷ !(Either Int Skill) -- ^ skill index (0-3) or 'Skill'
               , actT ∷ !Slot               -- ^ target index (-1-5)
               } deriving (Eq)
data ActPath = ActPath { actPathC ∷ !Int -- ^ to 'actC'
                       , actPathS ∷ !Int -- ^ to Left 'actS'
                       , actPathT ∷ !Int -- ^ to 'actT'
                       } deriving (Eq, Show, Read)
instance PathPiece ActPath where
  toPathPiece ActPath{..} = T.pack ∘ intercalate "," 
                          $ map show [actPathC, actPathS, actPathT]
  fromPathPiece raw   = case pieces of
      [c, s, t] → case makeAct c s t of
                       Right act → Just act
                       Left  _   → Nothing
      _         → Nothing
    where pieces    = splitOn "," raw
          makeAct c s t = do
              (c',_) ← decimal c
              (s',_) ← decimal s
              (t',_) ← decimal t
              return $ ActPath c' s' t'

actFromPath ∷ ActPath → Act
actFromPath ActPath{..} = Act (Slot actPathC) (Left actPathS) (Slot actPathT)

data Affected = Applied
              | Channeled
              | Countered
              | Delayed
              | Disrupted
              | Parrying
              | Redirected
              | Reflected
              | Swapped
              | Trapped
              deriving (Enum, Show, Eq)

-- | Destructible barrier.
data Barrier = Barrier { barrierAmount ∷ !Int
                       , barrierSrc    ∷ !Slot
                       , barrierL      ∷ !Text
                       , barrierWhile  ∷ !(Game → Game)
                       , barrierDone   ∷ !(Int → Game → Game)
                       , barrierDur    ∷ !Int
                       } deriving (Eq, Generic, ToJSON)
instance TurnBased Barrier where 
    getDur     = barrierDur
    setDur d a = a { barrierDur = d }
instance Labeled Barrier where 
    getL   = barrierL
    getSrc = barrierSrc

-- | Collection of all five chakras.
data Chakras = Chakras { blood ∷ !Int
                       , gen   ∷ !Int
                       , nin   ∷ !Int
                       , tai   ∷ !Int
                       , rand  ∷ !Int
                       } deriving (Eq, Show, Read, Generic, ToJSON)
instance PathPiece Chakras where
  toPathPiece a     = T.pack $ show a
  fromPathPiece raw = case pieces of
      [b, g, n, t] → case makeChakras b g n t of
                       Right chakras → Just chakras
                       Left  _   → Nothing
      _         → Nothing
    where pieces    = splitOn "," raw
          makeChakras b g n t = do
              (b',_) ← decimal b
              (g',_) ← decimal g
              (n',_) ← decimal n
              (t',_) ← decimal t
              return $ Chakras b' g' n' t' 0

χØ ∷ Chakras
χØ = Chakras 0 0 0 0 0

-- | Types of chakra in 'Chakras'.
data ChakraType = Blood | Gen | Nin | Tai | Rand deriving (Enum, Eq, Show)

-- | An 'Act' channeled over multiple turns.
data Channel = Channel { channelRoot  ∷ !Slot
                       , channelSkill ∷ !Skill
                       , channelT     ∷ !Slot
                       , channelDur   ∷ !Channeling
                       } deriving (Eq, Generic, ToJSON)
instance TurnBased Channel where 
    getDur     = getDur ∘ channelDur
    setDur d a = a { channelDur = setDur d $ channelDur a }

-- | Types of channeling for 'Skill's.
data Channeling = Instant
                | Passive
                | Action  !Int
                | Control !Int
                | Ongoing !Int
                deriving (Eq, Show, Generic, ToJSON)
instance TurnBased Channeling where
    getDur Instant       = 0
    getDur Passive       = 0
    getDur (Action d)    = d
    getDur (Control d)   = d
    getDur (Ongoing d)   = d
    setDur _ Instant     = Instant
    setDur _ Passive     = Passive
    setDur d (Action _)  = Action d
    setDur d (Control _) = Control d
    setDur d (Ongoing _) = Ongoing d

isAction  ∷ Channeling → Bool
isAction (Action _)   = True
isAction _            = False
isControl ∷ Channeling → Bool
isControl (Control _) = True
isControl _           = False
isOngoing ∷ Channeling → Bool
isOngoing (Ongoing _) = True
isOngoing _           = False

data ChannelTag = ChannelTag { tagRoot    ∷ !Slot
                             , tagSrc     ∷ !Slot 
                             , tagSkill   ∷ !Skill
                             , tagGhost   ∷ !Bool
                             , tagDur     ∷ !Int
                             } deriving (Eq, Generic, ToJSON)
instance TurnBased ChannelTag where 
    getDur     = tagDur
    setDur d a = a { tagDur = d }
instance Labeled ChannelTag where
    getL   = label ∘ tagSkill
    getSrc = tagRoot

-- | An out-of-game character.
data Character = Character { characterName   ∷ !Text
                           , characterBio    ∷ !Text
                           , characterSkills ∷ ![[Skill]]
                           , characterHooks  ∷ ![(Trigger, Ninja → Int → Ninja)]
                           } deriving (Generic, ToJSON)
instance Eq Character where
  a == b = characterName a ≡ characterName b

-- | A 'Skill' obtained from a different character.
data Copied = Copied { copiedSkill ∷ !Skill
                     , copiedDur   ∷ !Int
                     } deriving (Eq)
instance TurnBased Copied where 
    getDur     = copiedDur
    setDur d a@Copied{..} = a { copiedDur = d
                              , copiedSkill = f $ copying copiedSkill 
                              }
        where f (Shallow b _) = copiedSkill { copying = Shallow b d }
              f (Deep    b _) = copiedSkill { copying = Deep    b d }
              f NotCopied     = copiedSkill

instance ToJSON Copied where
    toJSON = toJSON ∘ copiedSkill

data Copying = Shallow Slot Int | Deep Slot Int | NotCopied deriving (Eq, Generic, ToJSON)

-- | Destructible defense.
data Defense = Defense { defenseAmount ∷ !Int
                       , defenseSrc    ∷ !Slot
                       , defenseL      ∷ !Text
                       , defenseDur    ∷ !Int
                       } deriving (Eq, Generic, ToJSON)
instance TurnBased Defense where 
    getDur     = defenseDur
    setDur d a = a { defenseDur = d }
instance Labeled Defense where 
    getL   = defenseL
    getSrc = defenseSrc
-- | Applies a 'Transform' after several turns.
data Delay = Delay { delayC     ∷ !Slot
                   , delaySkill ∷ !Skill
                   , delayEf    ∷ !(Game → Game)
                   , delayDur   ∷ !Int
                   } deriving (Eq)
instance TurnBased Delay where 
    getDur     = delayDur
    setDur d a = a { delayDur = d }
instance Labeled Delay where 
    getL   = label ∘ delaySkill
    getSrc = delayC

data Face = Face { faceIcon ∷ !Text
                 , faceSrc  ∷ !Slot
                 , faceDur  ∷ !Int
                 } deriving (Eq, Generic, ToJSON)
instance TurnBased Face where 
    getDur     = faceDur
    setDur d a = a { faceDur = d }

-- | Game state.
data Game = Game { gamePlayers ∷ !(Key User, Key User)
                 , gameNinjas  ∷ Seq Ninja -- I'm like 20% sure about this
                 , gameChakra  ∷ !(Chakras, Chakras)
                 , gameDelays  ∷ ![Delay]
                 , gameDrain   ∷ !(Int, Int) -- ^ resets each turn to (0, 0)
                 , gameSteal   ∷ !(Int, Int) -- ^ resets each turn to (0, 0)
                 , gameTraps   ∷ Seq (Game → Game) -- 15% for this one
                 , gameTime    ∷ !UTCTime
                 , gamePlaying ∷ !Player    -- ^ starts at 'PlayerA'
                 , gameVictor  ∷ !(Maybe Victor)
                 } deriving (Eq)
gameNinja ∷ Slot → Game → Ninja
gameNinja (Slot i) Game{..} = gameNinjas `index` i
setNinja ∷ Slot → Ninja → Game → Game
setNinja (Slot i) n game@Game{..} = game { gameNinjas = update i n gameNinjas }
fn ∷ Slot → (Ninja → Ninja) → Game → Game
fn (Slot i) f game@Game{..} = game { gameNinjas = adjust' f i gameNinjas }


setTime ∷ UTCTime → Game → Game
setTime gameTime game = game { gameTime }

-- | Constructs a 'Game' with starting values from a time, teams, and 'User's.
newGame ∷ UTCTime → [Character] → Key User → Key User → Game
newGame t ns a b = Game { gamePlayers = (a, b)
                        , gameNinjas  = fromList $ zipWith newNinja ns allSlots
                        , gameChakra  = (χØ, χØ)
                        , gameDelays  = []
                        , gameDrain   = (0, 0)
                        , gameSteal   = (0, 0)
                        , gameTraps   = ø
                        , gameTime    = t
                        , gamePlaying = PlayerA
                        , gameVictor  = Nothing
                        }

-- | In-game character, indexed between 0 and 5.
data Ninja = Ninja { nId        ∷ !Slot                 -- ^ 'gameNinja' index
                   , nCharacter ∷ !Character
                   , nHealth    ∷ !Int                  -- ^ starts at 100
                   , nCooldowns ∷ !(Seq (Seq Int))      -- ^ starts at 'S.empty'
                   , nCharges   ∷ !(Seq Int)            -- ^ starts at 4 0s
                   , nVariants  ∷ !(Seq [Variant])      -- ^ starts at 4 0s
                   , nCopied    ∷ !(Seq (Maybe Copied)) -- ^ starts at 4 Nothings
                   , nDefense   ∷ ![Defense]      
                   , nBarrier   ∷ ![Barrier]
                   , nStatuses  ∷ ![Status]       
                   , nChannels  ∷ ![Channel]
                   , newChans   ∷ ![Channel]
                   , nTraps     ∷ !(Seq Trap)
                   , nFace      ∷ ![Face]
                   , nParrying  ∷ ![Skill]
                   , nTags      ∷ ![ChannelTag]
                   , nLastSkill ∷ !(Maybe Skill)
                   } deriving (Eq)

insertCd' ∷ Int → Int → Seq Int → Seq Int
insertCd' v toCd cds
  | len > v   = update v toCd cds
  | otherwise = (cds ◇ S.replicate (v - len) 0) ▷ toCd
  where len = length cds

insertCd ∷ Int → Int → Int → Seq (Seq Int) → Seq (Seq Int)
insertCd s v toCd cds
  | len > s   = adjust' (insertCd' v toCd) s cds
  | otherwise = (cds ◇ S.replicate (s - len) (S.singleton 0)) 
              ▷ insertCd' v toCd ø
  where len = length cds

adjustCd' ∷ Int → (Int → Int) → Seq Int → Seq Int
adjustCd' v f cds
  | len > v   =  adjust' f v cds
  | otherwise = (cds ◇ S.replicate (v - len) 0) ▷ f 0
  where len = length cds

adjustCd ∷ Int → Int → (Int → Int) → Seq (Seq Int) → Seq (Seq Int)
adjustCd s v f cds
  | len > s   = adjust' (adjustCd' v f) s cds
  | otherwise = (cds ◇ S.replicate (s - len) (S.singleton 0)) 
              ▷ adjustCd' v f ø
  where len = length cds


-- | Constructs a 'Ninja' with starting values from an index and character name.
newNinja ∷ Character → Slot → Ninja
newNinja c nId = Ninja { nId        = nId
                       , nHealth    = 100
                       , nCharacter = c
                       , nDefense   = []
                       , nBarrier   = []
                       , nStatuses  = []
                       , nCharges   = four0s
                       , nCooldowns = ø
                       , nVariants  = S.replicate 4 [noVariant]
                       , nCopied    = S.replicate 4 Nothing
                       , nChannels  = []
                       , newChans   = []
                       , nTraps     = ø
                       , nFace      = []
                       , nParrying  = []
                       , nTags      = []
                       , nLastSkill = Nothing
                       }

-- | Factory resets a 'Ninja' to its default values from 'newNinja'
ninjaReset ∷ Ninja → Ninja
ninjaReset Ninja{..} = newNinja nCharacter nId

-- | Player vs. opponent.
data Player = PlayerA | PlayerB deriving (Enum, Show, Eq)
instance ToJSON Player where toJSON = toJSON ∘ fromEnum
data Victor = VictorA | VictorB | Tie deriving (Enum, Show, Eq)
instance ToJSON Victor where toJSON = toJSON ∘ fromEnum

data Requirement = Usable
                 | Unusable
                 | HasI Int Text
                 | HasU Text 
                 deriving (Eq, Generic, ToJSON)

-- | A move that a 'Character' can perform.
data Skill = Skill  { label   ∷ !Text
                    , desc    ∷ !Text
                    , require ∷ !Requirement   -- ^ defaults to 'Usable'
                    , classes ∷ ![Class]
                    , cost    ∷ !Chakras       -- ^ defaults to 'S.empty'
                    , cd      ∷ !Int           -- ^ defaults to 0
                    , varicd  ∷ !Bool          -- ^ defaults to False
                    , charges ∷ !Int           -- ^ defaults to 0
                    , channel ∷ !Channeling    -- ^ defaults to 'Instant'
                    , start   ∷ ![(Target, Transform)]
                    , effects ∷ ![(Target, Transform)]
                    , disrupt ∷ ![(Target, Transform)]
                    , copying ∷ !Copying       -- ^ defaults to 'NotCopied'
                    , skPic   ∷ !Bool          -- ^ defaults to False
                    , changes ∷ !(Ninja → Skill → Skill) -- ^ defaults to 'id'
                    } deriving (Generic, ToJSON)
instance Eq Skill where
    (==) = f2all [eqs label, eqs desc]

-- | Default values of a 'Skill'. Used with record updates as a 'Skill' constructor.
newSkill ∷ Skill
newSkill = Skill { label   = "Unnamed"
                 , desc    = ""
                 , require = Usable
                 , classes = []
                 , cost    = χØ
                 , cd      = 0
                 , varicd  = False
                 , charges = 0
                 , channel = Instant
                 , start   = []
                 , effects = []
                 , disrupt = []
                 , changes = const id
                 , copying = NotCopied
                 , skPic   = False
                 }

-- | Applies 'Transform's when a 'Status' ends.
data Bomb = Done   -- ^ Applied with both 'Expire' and 'Remove'.
          | Expire -- ^ Applied when a 'Status' reaches the end of its duration. 
          | Remove -- ^ Applied when a 'Status' is removed prematurely.
          deriving (Enum, Eq, Show, Generic, ToJSON)

-- | A status effect affecting a 'Ninja'.
data Status = Status { statusL       ∷ !Text
                     , statusRoot    ∷ !Slot
                     , statusSrc     ∷ !Slot
                     , statusC       ∷ !Slot
                     , statusSkill   ∷ !Skill
                     , statusEfs     ∷ ![Effect]
                     , statusClasses ∷ ![Class]
                     , statusBombs   ∷ ![(Bomb, Transform)]
                     , statusMaxDur  ∷ !Int
                     , statusDur     ∷ !Int
                     } deriving (Generic, ToJSON)
instance Eq Status where
  (==) = f2all 
         [eqs statusL, eqs statusSrc, eqs statusMaxDur, eqs statusClasses]
instance TurnBased Status where 
    getDur     = statusDur
    setDur d a = a { statusDur = d }
instance Labeled Status where
    getL   = statusL
    getSrc = statusSrc

-- | Target destinations of 'Skill's.
data Target = Self           -- ^ User of 'Skill'
            | Ally           -- ^ Chosen ally
            | Allies         -- ^ All allies
            | RAlly          -- ^ Random ally
            | XAlly          -- ^ Chosen ally excluding 'Self'
            | XAllies        -- ^ 'Allies' excluding 'Self'
            | Enemy          -- ^ Chosen enemy
            | Enemies        -- ^ All enemies
            | REnemy         -- ^ Random enemy
            | XEnemies       -- ^ Enemies excluding 'Enemy'
            | Everyone       -- ^ All 'Ninja's
            | Specific !Slot -- ^ Specific ninja index (0-6)
            deriving (Eq, Generic, ToJSON)

data TrapType = TrapTo | TrapFrom | TrapPer deriving (Enum, Eq, Generic, ToJSON)

-- | A trap which gets triggered when a 'Ninja' meets the conditions of a 'Trigger'.
data Trap = Trap { trapType    ∷ !TrapType
                 , trapTrigger ∷ !Trigger
                 , trapL       ∷ !Text
                 , trapDesc    ∷ !Text
                 , trapSrc     ∷ !Slot
                 , trapEf      ∷ !TrapTransform
                 , trapClasses ∷ ![Class]
                 , trapTrack   ∷ !Int
                 , trapDur     ∷ !Int
                 } deriving (Generic, ToJSON)
instance Eq Trap where
    (==) = f2all 
           [eqs trapType, eqs trapTrigger, eqs trapL, eqs trapSrc, eqs trapDur]
instance TurnBased Trap where 
    getDur     = trapDur
    setDur d a = a { trapDur = d }
instance Labeled Trap where
    getL   = trapL
    getSrc = trapSrc

-- | Conditions on a 'Ninja' to spring a 'Trap'.
data Trigger = OnAction     !Class
             | OnBreak      !Text
             | OnChakra
             | OnCounter    !Class
             | OnCounterAll
             | OnDamage
             | OnDamaged    !Class
             | OnDeath
             | OnHarm    
             | OnHarmed     !Class
             | OnHealed
             | PerHealed
             | OnHelped
             | OnImmune
             | OnReflectAll
             | OnRes
             | OnStun
             | OnStunned    !Class
             | PerDamaged
             | TrackDamage
             | TrackDamaged
             deriving (Eq)
instance ToJSON Trigger where
    toJSON = toJSON ∘ tshow
instance Show Trigger where
    show (OnAction  All) = "Trigger: Use any skill"
    show (OnAction  cla) = "Trigger: Use " ⧺ low cla ⧺ " skills"
    show (OnBreak   l)   = "Trigger: Lose all destructible defense from '" ⧺ T.unpack l ⧺ "'"
    show OnChakra        = "Trigger: Steal or remove chakra" 
    show (OnCounter All) = "Next harmful skill is countered."
    show (OnCounter Uncounterable) = "Next skill is negated."
    show (OnCounter cla) = "Next harmful " ⧺ low cla ⧺ " skill is countered."
    show OnCounterAll    = "All skills are countered."
    show OnDamage        = "Trigger: Deal damage"
    show (OnDamaged All) = "Trigger: Receive damage"
    show (OnDamaged cla) = "Trigger: Receive " ⧺ low cla ⧺ " damage"
    show OnDeath         = "Trigger: Die"
    show OnHarm          = "Trigger: Use harmful skill"
    show (OnHarmed All)  = "Trigger: Be affected by a new harmful skill"
    show (OnHarmed cla)  = "Trigger: Be affected by a new " ⧺ low cla ⧺ " harmful skill"
    show OnHealed        = "Trigger: Receive healing"
    show OnHelped        = "Trigger: Be affected by a new skill from an ally"
    show OnImmune        = "Trigger: Become invulnerable"
    show OnReflectAll    = "All skills are reflected."
    show OnRes           = "Trigger: Reach 0 health"
    show OnStun          = "Trigger: Apply a stun"
    show (OnStunned _)   = "Trigger: Stunned"
    show PerDamaged      = show (OnDamaged All)
    show PerHealed       = show OnHealed
    show TrackDamage     = show OnDamage
    show TrackDamaged    = show PerDamaged

data Variant = Variant { variantV   ∷ !Int
                       , variantVCD ∷ !Bool
                       , variantL   ∷ !Text
                       , variantDur ∷ !Int
                       } deriving (Eq, Show, Generic, ToJSON)
instance TurnBased Variant where getDur        = variantDur
                                 setDur a vari = vari { variantDur = a }
variantCD ∷ Variant → Int
variantCD Variant{..}
  | variantVCD = variantV
  | otherwise  = 0

noVariant ∷ Variant
noVariant = Variant 0 False "" 0

-- * Ninja Slots

newtype Slot = Slot Int deriving (Eq)
instance ToJSON Slot where
  toJSON (Slot i) = toJSON i

par ∷ Int → Int -- ^ ٪ 2
par = (٪ 2)

bySlot ∷ Slot → (a → a) → (a, a) → (a, a)
bySlot (Slot a) = do2 $ even a
outSlot ∷ Slot → (a, a) → a
outSlot (Slot a) = out2 $ even a
outSlot' ∷ Slot → (a, a) → a
outSlot' (Slot a) = out2 $ odd a

spar ∷ Slot → Int
spar (Slot a) = a ٪ 2

allied' ∷ Int → Int → Bool -- ^ if both are on the same team
allied' a b = even a ≡ even b
allied ∷ Slot → Slot → Bool
allied (Slot a) (Slot b) = allied' a b
alliedP ∷ Player → Slot → Bool
alliedP p (Slot nId) = allied' (fromEnum p) nId

allies' ∷ Int → Seq Ninja → [Ninja]
allies' p = evens ∘ drop (par p) ∘ toList
allies ∷ Slot → Game → [Ninja]
allies (Slot p) = allies' p ∘ gameNinjas
alliesP ∷ Player → Seq Ninja → [Ninja]
alliesP = allies' ∘ fromEnum
enemies' ∷ Int → Seq Ninja → [Ninja]
enemies' p = evens ∘ drop (1 - par p) ∘ toList
enemies ∷ Slot → Game → [Ninja]
enemies (Slot p) = enemies' p ∘ gameNinjas
enemiesP ∷ Player → Seq Ninja → [Ninja]
enemiesP = enemies' ∘ fromEnum

allSlots ∷ [Slot]
allSlots = map Slot $ [ 0 .. gameSize - 1]

allySlots' ∷ Int → [Slot]
allySlots' a = map Slot $ [ a',  2 + a' .. gameSize - 1]
  where a' = a ٪ 2
allySlots ∷ Slot → [Slot]
allySlots (Slot a) = allySlots' a
enemySlots' ∷ Int → [Slot]
enemySlots' a = map Slot $ [1 - a', 3 - a' .. gameSize - 1]
  where a' = a ٪ 2
enemySlots ∷ Slot → [Slot]
enemySlots (Slot a) = enemySlots' a

opponentSlots ∷ Player → [Slot]
opponentSlots = enemySlots' ∘ fromEnum

evens ∷ [a] → [a] -- ^ selects every other element from list
evens [x]      = [x]
evens (x:_:xs) = x : evens xs
evens []       = []

ifPar ∷ Int → Int → [Int]
ifPar c t = [t | c ≤ gameSize ∧ t ≤ gameSize ∧ allied' c t]

choose ∷ (Maybe Slot, Maybe Slot) → Target → Slot → Slot → [Slot]
choose (a, e) targ (Slot c) (Slot t) = map Slot $ choose' (ms a, ms e) targ c t
  where ms (Just (Slot s)) = Just s
        ms Nothing         = Nothing

-- | Translates a 'Target' into a list of 'Ninja's.
choose' ∷ (Maybe Int, Maybe Int) → Target → Int → Int → [Int]
choose' _      Self     c _ = [c]
choose' _      Ally     c t = ifPar c t
choose' _      Allies   c _ = [par c, 2 + par c .. gameSize - 1]
choose' (r, _) RAlly    _ _ = maybeToList r
choose' _      XAlly    c t = delete c $ ifPar c t
choose' _      Enemy    c t = ifPar (c + 1) t
choose' _      Enemies  c _ = [1 - par c, 3 - par c .. gameSize-1]
choose' (_, r) REnemy   _ _ = maybeToList r
choose' _      Everyone _ _ = [0 .. gameSize - 1]
choose' _      XAllies  c _ = delete c [par c, 2 + par c .. gameSize - 1]  
choose' _      XEnemies c t = delete t [1 - par c, 3 - par c .. gameSize-1]
choose' _ (Specific (Slot a)) _ _ = [a]


botActs ∷ [Act]
botActs = [ Act (Slot 3) (Left 1) (Slot 2)
          , Act (Slot 5) (Left 1) (Slot 5) 
          , Act (Slot 1) (Left 3) (Slot 1)
          ]

skillTargets ∷ Skill → Slot → [Slot]
skillTargets Skill{..} c = filter target $ map Slot [0 .. gameSize - 1]
  where ts = map fst $ start ⧺ effects ⧺ disrupt
        harm = [Enemy, Enemies, REnemy, XEnemies] ⩀ ts
        target t | Everyone ∈ ts = True
                 | not $ allied c t = harm
                 | [XAlly, XAllies] ⩀ ts = c ≠ t
                 | [Ally, Allies, RAlly] ⩀ ts = True
                 | c ≡ t = not harm
                 | otherwise = False

-- * Function ignoring for derives
instance Eq     (a → b) where (==)   = const $ const True
instance ToJSON (a → b) where toJSON = const $ toJSON (Nothing ∷ Maybe Bool)