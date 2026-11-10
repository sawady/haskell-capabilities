{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE FlexibleContexts #-}
-- The Net instances for the transformers stay here, as in C2.
{-# OPTIONS_GHC -Wno-orphans #-}
-- | Solution to exercise 4: C2's program, unchanged, run without IO.
--
-- Only the base of the stack changes: instead of 'Base', which wraps IO,
-- 'Fake' records the requested URLs in a list. In C1 the same is not
-- possible without changing the code of summary: its type names the stack
-- ('App', with IO at the bottom) and its body prints with
-- @lift (lift putStrLn)@.
module Main (main) where

import Capabilities (Net (..), Url, firstLine)
import Control.Monad.Reader (MonadReader, ReaderT, ask, runReaderT)
import Control.Monad.State (MonadState, State, StateT, get, modify, runState, runStateT)
import Control.Monad.Trans.Class (lift)

data Config = Config { server :: Url }

-- | Copied unchanged from C2_Mtl.
summary :: (MonadReader Config m, MonadState Int m, Net m) => String -> m String
summary path = do
  cfg <- ask
  modify (+ 1)
  page <- httpGet (server cfg ++ path)
  n <- get
  return (firstLine page ++ " (request " ++ show n ++ ")")

-- * A pure base monad with the Net capability

-- | The network answers from a fixed text and records each requested URL.
newtype Fake a = Fake { runFake :: State [Url] a }

instance Functor Fake where
  fmap f (Fake s) = Fake (fmap f s)

instance Applicative Fake where
  pure = Fake . pure
  Fake f <*> Fake x = Fake (f <*> x)

instance Monad Fake where
  Fake s >>= k = Fake (s >>= runFake . k)

instance Net Fake where
  httpGet url = Fake (modify (++ [url]) >> return ("<title of " ++ url ++ ">\nrest"))

-- | The same instances as in C2, so that Net goes through each layer.
instance Net m => Net (ReaderT r m) where
  httpGet = lift . httpGet

instance Net m => Net (StateT s m) where
  httpGet = lift . httpGet

main :: IO ()
main = do
  let ((results, requests), urls) = runState (runFake (runStateT (runReaderT program cfg) 0)) []
  mapM_ putStrLn results
  putStrLn ("Requests made: " ++ show requests)
  putStrLn ("URLs requested: " ++ show urls)
  where
    cfg = Config "https://example.org"
    program = mapM summary ["/docs", "/blog"]
