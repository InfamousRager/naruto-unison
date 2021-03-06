{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE QuasiQuotes #-}
{-# OPTIONS_GHC -fno-warn-unused-matches #-}

-- | Interface for the PureScript game client.
module Handler.Forum
    ( getProfileR
    , getForumsR
    , getBoardR
    , getTopicR
    , postTopicR
    , getNewTopicR
    , postNewTopicR
    , selectWithAuthors, makeCitelink
    ) where

import StandardLibrary
import qualified Data.Time.Format    as Format
import qualified Data.Time.LocalTime as LocalTime
import qualified Data.Text           as Text

import Calculus
import Core.Import
import Game.Characters (cs)

staffTag :: Char
staffTag = '*'

userRanks :: [Text]
userRanks = [ "Academy Student"
            , "Genin"
            , "Chūnin"
            , "Missing-Nin"
            , "Anbu"
            , "Jōnin"
            , "Sannin"
            , "Jinchūriki"
            , "Akatsuki"
            , "Kage"
            , "Hokage"
            ]

selectWithAuthors :: ∀ a. (HasAuthor a, AppPersistEntity a) 
                  => [Filter a] -> [SelectOpt a] -> Handler [Cite a]
selectWithAuthors selectors opts = runDB (selectList selectors opts) >>=
                                   traverse go
  where
    go (Entity citeKey citeVal) = runDB $ do
        citeAuthor <- get404 author
        citeLatest <- if | author == latest -> return citeAuthor 
                         | otherwise        -> get404 latest
        return Cite{..}
      where
        author = getAuthor citeVal
        latest = getLatest citeVal

userRank :: User -> Text
userRank User{..} = case userPrivilege of
    Normal -> maybe "Hokage" fst . uncons $ drop level userRanks
    _      -> tshow userPrivilege
  where 
    level = userXp `quot` 5000

data NewTopic = NewTopic Topic (TopicId -> Post)

toBody :: Textarea -> [Text]
toBody = Text.splitOn "\n" . unTextarea

newTopicForm :: User -> ForumBoard -> UserId -> UTCTime 
             -> AForm Handler NewTopic
newTopicForm User{..} topicBoard postAuthor postTime = makeNewTopic
    <$> areq textField "Title" Nothing
    <*> areq textareaField "Post" Nothing
  where
    topicAuthor = postAuthor
    topicLatest = postAuthor
    topicTime   = postTime
    topicStaff  = userPrivilege /= Normal
    topicPosts  = 1
    makeNewTopic rawTitle area = NewTopic Topic{..} $ \postTopic -> Post{..}
      where
        topicTitle = filter (/= staffTag) rawTitle
        postBody = toBody area

newPostForm :: TopicId -> UserId -> UTCTime -> AForm Handler Post
newPostForm postTopic postAuthor postTime = makePost . toBody
    <$> areq textareaField "" Nothing
  where
    makePost postBody = Post{..}

getProfileR :: Text -> Handler Html
getProfileR name = do
    muser                  <- runDB $ selectFirst [UserName ==. name] []
    Entity _ user@User{..} <- maybe notFound return muser
    let (level, xp)         = quotRem userXp 5000
    defaultLayout $ do
        setTitle . toHtml $ "User: " ++ userName
        $(widgetFile "tooltip/tooltip")
        $(widgetFile "forum/profile")

data BoardIndex = BoardIndex ForumBoard Int (Maybe (Cite Topic))
inCategory :: ForumCategory -> BoardIndex -> Bool
inCategory category (BoardIndex x _ _) = category == boardCategory x

-- | Renders the forums.
getForumsR :: Handler Html
getForumsR = do
    citelink <- liftIO makeCitelink
    allBoards <- traverse indexBoard enums
    let boards category = filter (inCategory category) allBoards
    defaultLayout $ do
        setTitle "Naruto Unison Forums"
        $(widgetFile "forum/browse")
  where
    indexBoard board = do
        posts <- selectWithAuthors [TopicBoard ==. board] [Desc TopicTime]
        pure $ BoardIndex board (length posts) (listToMaybe posts) 

-- | Renders a 'ForumBoard'.
getBoardR :: ForumBoard -> Handler Html
getBoardR board = do
    timestamp <- liftIO makeTimestamp
    topics    <- selectWithAuthors [TopicBoard ==. board] []
    defaultLayout $ do
        setTitle . toHtml $ "Forum: " ++ boardName board
        $(widgetFile "forum/board")

getTopicR :: TopicId -> Handler Html
getTopicR topicId = do
    (who, _)  <- requireAuthPair
    time      <- liftIO getCurrentTime
    timestamp <- liftIO makeTimestamp
    zone      <- liftIO LocalTime.getCurrentTimeZone
    Topic{..} <- runDB $ get404 topicId
    posts     <- selectWithAuthors [PostTopic ==. topicId] []
    (widget, enctype) <- generateFormPost . renderTable $
                         newPostForm topicId who time
    defaultLayout $ do
        setTitle . toHtml $ "Topic: " ++ topicTitle
        $(widgetFile "forum/topic")

postTopicR :: TopicId -> Handler Html
postTopicR topicId = do
    (who, _)  <- requireAuthPair
    time      <- liftIO getCurrentTime
    timestamp <- liftIO makeTimestamp
    ((result, _), _) <- runFormPost . renderTable $ newPostForm topicId who time
    case result of
        FormSuccess post -> runDB $ do
            insert400_ post
            update topicId [ TopicPosts +=. 1
                           , TopicTime   =. time
                           , TopicLatest =. who
                           ]
        _ -> return ()
    Topic{..} <- runDB $ get404 topicId
    posts     <- selectWithAuthors [PostTopic ==. topicId] []
    (widget, enctype) <- generateFormPost . renderTable $
                         newPostForm topicId who time
    defaultLayout $ do
        setTitle . toHtml $ "Topic: " ++ topicTitle
        $(widgetFile "forum/topic")

getNewTopicR :: ForumBoard -> Handler Html
getNewTopicR board = do
    (who, user) <- requireAuthPair
    time        <- liftIO getCurrentTime
    (widget, enctype) <- generateFormPost . renderTable $
                         newTopicForm user board who time
    defaultLayout $ do
        setTitle "New Topic"
        $(widgetFile "forum/new")

postNewTopicR :: ForumBoard -> Handler Html
postNewTopicR board = do
    (who, user) <- requireAuthPair
    time        <- liftIO getCurrentTime
    ((result, widget), enctype) <- runFormPost . renderTable $ 
                                   newTopicForm user board who time
    case result of
        FormSuccess (NewTopic topic makePost) -> do
            topicId <- runDB $ insert400 topic
            let post = makePost topicId
            runDB $ insert400_ post
            redirect $ TopicR topicId
        _ -> defaultLayout $ do
            setTitle "New Topic"
            $(widgetFile "forum/new")

userlink :: User -> Widget
userlink User{..} = $(widgetFile "widgets/userlink")

topiclink :: Cite Topic -> Widget
topiclink Cite{..} = $(widgetFile "widgets/topiclink")

makeTimestamp :: IO (UTCTime -> Widget)
makeTimestamp = do
    time   <- getCurrentTime
    zone   <- LocalTime.getCurrentTimeZone
    return . pureTimestamp zone $ utctDay time

makeCitelink :: IO (Cite Topic -> Widget)
makeCitelink = do
    timestamp <- makeTimestamp
    return $ \cite@Cite{..} -> $(widgetFile "widgets/citelink")

pureTimestamp :: LocalTime.TimeZone -> Day -> UTCTime -> Widget
pureTimestamp zone today unzoned = $(widgetFile "widgets/timestamp")
  where
    zoned = LocalTime.utcToLocalTime zone unzoned
    time  = Format.formatTime Format.defaultTimeLocale format zoned
    format
      | utctDay unzoned == today = "%l:%M %p"
      | otherwise                = "%m/%d/%y"
