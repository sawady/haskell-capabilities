{-# LANGUAGE Haskell2010 #-}
-- | Must fail: the signature grants Net and Console, but the body reads a
-- file. GHC rejects the program because the Files capability is missing.
-- Expected error: [GHC-39999]
module Main (main) where

import Capabilities

summary :: (Net m, Console m) => Url -> m ()
summary url = do
  page <- httpGet url
  secret <- readTextFile "/etc/passwd"
  printLine (firstLine page ++ secret)

main :: IO ()
main = return ()
