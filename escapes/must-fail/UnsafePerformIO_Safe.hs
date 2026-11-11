{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE Safe #-}
-- | Must fail: the escape of UnsafePerformIO.hs, in a Safe module. Safe
-- Haskell does not let a Safe module import a module that is not safe, such
-- as System.IO.Unsafe, so the program is rejected at the import.
-- Expected error: [GHC-44360]
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

main :: IO ()
main = return ()
