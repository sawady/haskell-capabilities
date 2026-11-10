{-# LANGUAGE Haskell2010 #-}
-- The function without a signature is on purpose, as in B: build.sh records
-- the type GHC infers for it in outputs/solution-E2_Clock-ghci.txt.
{-# OPTIONS_GHC -Wno-missing-signatures #-}
-- | Solution to exercise 2: a new capability, Clock, in tagless final.
module Main (main) where

import Capabilities
import Control.Monad.Trans.State (State, modify, runState)

-- | The new capability: reading the time, as seconds since some instant.
-- A single-parameter class, Haskell 2010, like the ones in "Capabilities".
class Monad m => Clock m where
  now :: m Int

-- | No signature: GHC infers @(Clock m, Net m, Console m) => Url -> m ()@.
-- Nothing else changed: summary and summaryWithFile in B do not mention
-- Clock and keep their types.
stampedSummary url = do
  t <- now
  page <- httpGet url
  printLine ("[" ++ show t ++ "s] " ++ firstLine page)

-- * B's pure interpreter, with one more instance: a fixed clock

-- | Copied from B_TaglessFinal, which is a program and cannot be imported.
newtype Test a = Test { runTest :: State [String] a }

instance Functor Test where
  fmap f (Test s) = Test (fmap f s)

instance Applicative Test where
  pure = Test . pure
  Test f <*> Test x = Test (f <*> x)

instance Monad Test where
  Test s >>= k = Test (s >>= runTest . k)

instance Net Test where
  httpGet url = return ("test page for " ++ url)

instance Console Test where
  printLine line = Test (modify (++ [line]))

-- | Granting the new capability to an interpreter is one instance. Neither
-- of B's interpreters (App and Test) has it, so neither could run
-- stampedSummary as they are.
instance Clock Test where
  now = return 42

main :: IO ()
main = do
  let ((), output) = runState (runTest (stampedSummary "https://example.org")) []
  mapM_ putStrLn output
