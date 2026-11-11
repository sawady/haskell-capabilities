{-# LANGUAGE Haskell2010 #-}
-- | Solution to exercise 6, part A: the Clock capability as a record of
-- functions over an abstract monad, as in part 3 of A_TypesOnly.
--
-- What changed: one more record, one more argument in the signature, and
-- one more argument in every call. Nothing else: no instance, no handler,
-- and the functions that do not read the time do not change.
module Main (main) where

import Capabilities (Url, firstLine)

data Net m = Net { httpGet :: Url -> m String }

data Console m = Console { printLine :: String -> m () }

-- | The new capability: reading the time, as seconds since some instant.
data Clock m = Clock { now :: m Int }

stampedSummary :: Monad m => Net m -> Console m -> Clock m -> Url -> m ()
stampedSummary net console clock url = do
  t <- now clock
  page <- httpGet net url
  printLine console ("[" ++ show t ++ "s] " ++ firstLine page)

-- | A simulated network and a clock that always says 42, as in exercise 2.
fakeFetch :: Url -> IO String
fakeFetch url = return ("<title of " ++ url ++ ">\nrest of the page")

main :: IO ()
main = stampedSummary (Net fakeFetch) (Console putStrLn) (Clock (return 42)) "https://example.org"
