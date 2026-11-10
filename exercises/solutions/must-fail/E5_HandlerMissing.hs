{-# LANGUAGE FlexibleContexts #-}
-- | Solution to exercise 5b: running D's program without handling Console.
-- After 'handleNet' the row is empty, so 'Member Console' cannot be
-- satisfied: every effect has to be handled before 'run'.
-- Expected error: [GHC-39999]
module Main (main) where

import Effects

summary :: (Member Net es, Member Console es) => Url -> Eff es ()
summary url = do
  page <- httpGet url
  printLine (takeWhile (/= '\n') page)

fakePages :: Url -> String
fakePages url = "<title of " ++ url ++ ">\nrest of the page"

main :: IO ()
main = print (run (handleNet fakePages (summary "https://example.org")))
