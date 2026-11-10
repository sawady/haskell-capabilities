{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
-- | Solution to exercise 5a: D's handlers in the other order.
--
-- Each signature is the row at that step, and GHC checks it. The program
-- is the same; what changes is which effect is first in the row, and so
-- which handler has to be applied first.
module Main (main) where

import Effects

-- | Copied unchanged from D_EffectRows.
summary :: (Member Net es, Member Console es) => Url -> Eff es ()
summary url = do
  page <- httpGet url
  printLine (takeWhile (/= '\n') page)

fakePages :: Url -> String
fakePages url = "<title of " ++ url ++ ">\nrest of the page"

-- | The program, with Console first in the row.
step0 :: Eff '[Console, Net] ()
step0 = summary "https://example.org"

-- | handleConsolePure removes Console: only Net is left.
step1 :: Eff '[Net] ((), [String])
step1 = handleConsolePure step0

-- | handleNet removes Net: the row is empty, and the result is pure.
step2 :: Eff '[] ((), [String])
step2 = handleNet fakePages step1

main :: IO ()
main = do
  putStrLn "Row [Console, Net], Console handled first:"
  let ((), output) = run step2
  mapM_ putStrLn output
