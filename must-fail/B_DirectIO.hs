{-# LANGUAGE Haskell2010 #-}
-- | Must fail: with the abstract monad, not even IO can be used directly.
-- That is the difference from example A.1, where the IO type allowed
-- anything.
-- Expected error: [GHC-25897]
module Main (main) where

import Capabilities

summary :: (Net m, Console m) => Url -> m ()
summary url = do
  page <- httpGet url
  putStrLn (firstLine page)

main :: IO ()
main = return ()
