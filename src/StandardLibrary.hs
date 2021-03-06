{-# LANGUAGE ConstraintKinds #-}

module StandardLibrary 
  ( module Data.Function
  , module Data.List
  , module Data.List.NonEmpty
  , module Data.HashMap.Strict
  , module Data.Sequence
  , module ClassyPrelude.Yesod
  , Mono
  , concatMap, catMaybes, mapMaybe
  , (—)
  , Pend, (<|), (|>)
  ) where

import Data.List ((\\), delete, deleteBy, nub, nubBy, transpose)
import Data.List.NonEmpty (NonEmpty(..), (!!), group, groupBy, head, tail, last, init)
import Data.Function ((&))
import Data.HashMap.Strict (HashMap)
import Data.Sequence ((!?))
import ClassyPrelude.Yesod hiding (Status, addClass, delete, deleteBy, group, groupBy, (\\), head, tail, last, init, concatMap, catMaybes, (<|), mapMaybe)

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Sequence      as Seq

-- | A 'MonoFoldable' containing a certain 'Element'.
type Mono o a = (MonoFoldable o, a ~ Element o)

-- | 'asum' . 'fmap'
concatMap :: ∀ l f a b. (Alternative l, Foldable f, Functor f) 
          => (a -> l b) -> f a -> l b
concatMap f = asum . fmap f

-- | Reduces a collection of Maybes to its Just values.
catMaybes :: ∀ m a. MonadPlus m => m (Maybe a) -> m a
catMaybes xs = do
    x <- xs
    case x of
        Just a  -> return a
        Nothing -> mzero

-- | 'catMaybes' . 'fmap'
mapMaybe :: ∀ m a b. MonadPlus m => (a -> Maybe b) -> m a -> m b
mapMaybe f = catMaybes . fmap f

-- | @(—) = ('-')@
-- Allows for sections, as in @(—3)@.
(—) :: ∀ a. Num a => a -> a -> a
(—) = (-) 

-- | Defines prepend and append operations.
class Pend a where
    -- | Prepend
    infixl 5 <|
    (<|) :: ∀ b. b -> a b -> a b
    -- | Append
    infixr 5 |>
    (|>) :: ∀ b. a b -> b -> a b
instance Pend [] where
    (<|) = (:)
    x |> y = x <> [y]
instance Pend NonEmpty where
    (<|) = (NonEmpty.<|)
    (x:|xs) |> x' = x :| xs |> x'
instance Pend Seq where
    (<|) = (Seq.<|)
    (|>) = (Seq.|>)
