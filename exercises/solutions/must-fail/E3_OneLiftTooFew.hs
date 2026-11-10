{-# LANGUAGE Haskell2010 #-}
-- | Solution to exercise 3a: C1 with one 'lift' too few. GHC rejects it
-- because 'putStrLn' is an IO action and, one layer below the top of the
-- stack, an action of 'StateT Int IO' is expected.
-- Expected error: [GHC-83865]
module Main (main) where

import Capabilities (Url, firstLine)
import Control.Monad.Trans.Class (lift)
import Control.Monad.Trans.Reader (ReaderT, ask, runReaderT)
import Control.Monad.Trans.State (StateT, get, modify, runStateT)

data Config = Config { server :: Url }

type App = ReaderT Config (StateT Int IO)

fetch :: Url -> App String
fetch url = do
  lift (modify (+ 1))
  return ("<title of " ++ url ++ ">\nrest")

summary :: String -> App ()
summary path = do
  cfg <- ask
  page <- fetch (server cfg ++ path)
  n <- lift get
  lift (putStrLn (firstLine page ++ " (request " ++ show n ++ ")"))

main :: IO ()
main = do
  ((), requests) <- runStateT (runReaderT (summary "/docs") cfg) 0
  putStrLn ("Requests made: " ++ show requests)
  where
    cfg = Config "https://example.org"
