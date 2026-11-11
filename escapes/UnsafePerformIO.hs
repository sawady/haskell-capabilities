{-# LANGUAGE Haskell2010 #-}
-- | An escape that compiles: 'unsafePerformIO' runs an IO action as if it
-- were a pure value. 'summary' has exactly the type of B's summary, which
-- only grants Net and Console, and it reads the environment: nothing in the
-- type shows it.
--
-- Safe Haskell rejects it: the same program with @{-# LANGUAGE Safe #-}@ is
-- in must-fail/UnsafePerformIO_Safe.hs.
module Main (main) where

import Capabilities
import System.Environment (getEnvironment)
import System.IO.Unsafe (unsafePerformIO)

summary :: (Net m, Console m) => Url -> m ()
summary url = do
  page <- httpGet url
  printLine (firstLine page)
  let env = unsafePerformIO getEnvironment
  printLine ("  (read " ++ show (length env) ++ " environment variables without permission)")

-- | B's IO interpreter, with Net and Console and nothing else.
newtype App a = App { runApp :: IO a }

instance Functor App where
  fmap f (App io) = App (fmap f io)

instance Applicative App where
  pure = App . pure
  App f <*> App x = App (f <*> x)

instance Monad App where
  App io >>= k = App (io >>= runApp . k)

instance Net App where
  httpGet url = App (return ("<title of " ++ url ++ ">\nrest of the page"))

instance Console App where
  printLine = App . putStrLn

main :: IO ()
main = runApp (summary "https://example.org")
