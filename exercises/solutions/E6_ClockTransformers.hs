{-# LANGUAGE Haskell2010 #-}
-- | Solution to exercise 6, part C1: the Clock capability as one more layer
-- of the transformers stack of C1_Transformers.
--
-- What changed: the type of the stack, the code that reaches the layers
-- below the new one, and the function that runs the stack. The clock goes
-- just above IO, so reading it takes two 'lift', and printing, which used
-- to take two, now takes three. Had it gone on top, every 'ask' would have
-- become @lift ask@ and every 'lift' one more: where the layer goes decides
-- which lines change.
module Main (main) where

import Capabilities (Url, firstLine)
import Control.Monad.Trans.Class (lift)
import Control.Monad.Trans.Reader (ReaderT, ask, runReaderT)
import Control.Monad.Trans.State (StateT, get, modify, runStateT)

data Config = Config { server :: Url }

-- | The stack: configuration, on top of a counter, on top of the clock, on
-- top of IO. The clock is a reader of the time it answers: simulated, it
-- always says 42, as in exercise 2.
type App = ReaderT Config (StateT Int (ReaderT Int IO))

-- | Unchanged: the counter is still one layer down.
fetch :: Url -> App String
fetch url = do
  lift (modify (+ 1))
  return ("<title of " ++ url ++ ">\nrest")

summary :: String -> App ()
summary path = do
  cfg <- ask
  page <- fetch (server cfg ++ path)
  n <- lift get
  t <- lift (lift ask)                     -- the new layer: two layers down
  lift (lift (lift (putStrLn ("[" ++ show t ++ "s] " ++ firstLine page ++ " (request " ++ show n ++ ")"))))

main :: IO ()
main = do
  ((), requests) <- runReaderT (runStateT (runReaderT (summary "/docs" >> summary "/blog") cfg) 0) 42
  putStrLn ("Requests made: " ++ show requests)
  where
    cfg = Config "https://example.org"
