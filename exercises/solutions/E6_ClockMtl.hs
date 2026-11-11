{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE FlexibleContexts #-}
-- The Net and Clock instances for the transformers stay here, as in C2.
{-# OPTIONS_GHC -Wno-orphans #-}
-- | Solution to exercise 6, part C2: the Clock capability in the mtl style
-- of C2_Mtl.
--
-- What changed: one more class, one more constraint in the signature of
-- the program, and the instances: one for the base monad and one per
-- transformer of the stack, the same as Net needed. With n capabilities of
-- our own and m transformers there are n × m of them: that is the n²
-- problem. The program does not need any 'lift', and neither the stack nor
-- the function that runs it changed.
--
-- 'MonadState' could not have been the clock: the counter already uses
-- @MonadState Int m@, and the functional dependency of the class allows a
-- single state type per monad.
module Main (main) where

import Capabilities (Net (..), Url, firstLine)
import Control.Monad.Reader (MonadReader, ReaderT, ask, runReaderT)
import Control.Monad.State (MonadState, StateT, get, modify, runStateT)
import Control.Monad.Trans.Class (lift)

data Config = Config { server :: Url }

-- | The new capability, a single-parameter class like 'Net'.
class Monad m => Clock m where
  now :: m Int

summary :: (MonadReader Config m, MonadState Int m, Net m, Clock m) => String -> m String
summary path = do
  cfg <- ask
  modify (+ 1)
  page <- httpGet (server cfg ++ path)
  n <- get
  t <- now
  return ("[" ++ show t ++ "s] " ++ firstLine page ++ " (request " ++ show n ++ ")")

-- * The base monad, now with Net and Clock

newtype Base a = Base { runBase :: IO a }

instance Functor Base where
  fmap f (Base io) = Base (fmap f io)

instance Applicative Base where
  pure = Base . pure
  Base f <*> Base x = Base (f <*> x)

instance Monad Base where
  Base io >>= k = Base (io >>= runBase . k)

instance Net Base where
  httpGet url = Base (return ("<title of " ++ url ++ ">\nrest"))

-- | A clock that always says 42, as in exercise 2.
instance Clock Base where
  now = Base (return 42)

-- | As in C2: one instance per transformer, so that Net goes through each
-- layer.
instance Net m => Net (ReaderT r m) where
  httpGet = lift . httpGet

instance Net m => Net (StateT s m) where
  httpGet = lift . httpGet

-- | And the same again for Clock.
instance Clock m => Clock (ReaderT r m) where
  now = lift now

instance Clock m => Clock (StateT s m) where
  now = lift now

main :: IO ()
main = do
  (results, requests) <- runBase (runStateT (runReaderT program cfg) 0)
  mapM_ putStrLn results
  putStrLn ("Requests made: " ++ show requests)
  where
    cfg = Config "https://example.org"
    program = mapM summary ["/docs", "/blog"]
