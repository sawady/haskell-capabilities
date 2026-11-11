{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TypeOperators #-}
-- | Solution to exercise 6, part D: the Clock capability as one more effect
-- of the row, with the "Effects" of D_EffectRows.
--
-- What changed: one more effect (a GADT with one constructor per
-- operation), the function that sends it, a handler, one more constraint
-- in the signature of the program, and one more handler when running it.
-- The handler pattern-matches on the constructors of 'Eff' and 'Union', and
-- the operation uses 'send': that is why "Effects" exports them. Neither
-- the other effects nor their handlers changed.
module Main (main) where

import Effects

-- | The new effect: reading the time, as seconds since some instant.
data Clock a where
  Now :: Clock Int

now :: Member Clock es => Eff es Int
now = send Now

-- | Interprets Clock with a clock that always gives the same time.
handleClock :: Int -> Eff (Clock ': es) a -> Eff es a
handleClock _ (Pure a) = Pure a
handleClock t (Request (Here Now) k) = handleClock t (k t)
handleClock t (Request (There u) k) = Request u (handleClock t . k)

stampedSummary :: (Member Net es, Member Console es, Member Clock es) => Url -> Eff es ()
stampedSummary url = do
  t <- now
  page <- httpGet url
  printLine ("[" ++ show t ++ "s] " ++ takeWhile (/= '\n') page)

fakePages :: Url -> String
fakePages url = "<title of " ++ url ++ ">\nrest of the page"

-- | A clock that always says 42, as in exercise 2.
main :: IO ()
main = do
  putStrLn "Row [Clock, Net, Console], handled without IO:"
  let ((), output) =
        run (handleConsolePure (handleNet fakePages (handleClock 42 (stampedSummary "https://example.org"))))
  mapM_ putStrLn output
