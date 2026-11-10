{-# LANGUAGE Haskell2010 #-}
-- | Must fail: the program asks for Files and the interpreter does not grant
-- it. Choosing the interpreter is choosing which capabilities are granted.
-- Expected error: [GHC-39999]
module Main (main) where

import Capabilities

summaryWithFile :: (Net m, Files m, Console m) => Url -> FilePath -> m ()
summaryWithFile url path = do
  page <- httpGet url
  note <- readTextFile path
  printLine (firstLine page ++ " / " ++ note)

-- | An interpreter with network and console, but no files.
newtype App a = App { runApp :: IO a }

instance Functor App where
  fmap f (App io) = App (fmap f io)

instance Applicative App where
  pure = App . pure
  App f <*> App x = App (f <*> x)

instance Monad App where
  App io >>= k = App (io >>= runApp . k)

instance Net App where
  httpGet url = App (return url)

instance Console App where
  printLine = App . putStrLn

main :: IO ()
main = runApp (summaryWithFile "https://example.org" "note.txt")
