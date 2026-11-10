{-# LANGUAGE Haskell2010 #-}
-- | Solution to exercise 1: a Files capability as a record of functions,
-- in the style of part 3 of A_TypesOnly.
module Main (main) where

import Capabilities (Url, firstLine)
import Control.Monad.Trans.State (State, modify, runState)

data Net m = Net { httpGet :: Url -> m String }

data Console m = Console { printLine :: String -> m () }

-- | The new capability is one more record.
data Files m = Files { readTextFile :: FilePath -> m String }

-- | Three capabilities, three arguments, in a fixed order: the signature
-- lists them and every call has to pass them, one more than before. In B,
-- the new capability would be one more constraint, and the calls would not
-- change.
summaryWithFile :: Monad m => Net m -> Files m -> Console m -> Url -> FilePath -> m ()
summaryWithFile net files console url path = do
  page <- httpGet net url
  note <- readTextFile files path
  printLine console (firstLine page ++ " / " ++ note)

-- * Records over IO (the network and the file are simulated)

netIO :: Net IO
netIO = Net (\url -> return ("<title of " ++ url ++ ">\nrest of the page"))

filesIO :: Files IO
filesIO = Files (\path -> return ("contents of " ++ path))

consoleIO :: Console IO
consoleIO = Console putStrLn

-- * Records over a pure monad: the console collects lines in a list

netTest :: Net (State [String])
netTest = Net (\url -> return ("test page for " ++ url))

filesTest :: Files (State [String])
filesTest = Files (\path -> return ("simulated contents of " ++ path))

consoleTest :: Console (State [String])
consoleTest = Console (\line -> modify (++ [line]))

-- | The same function runs over IO and over State by passing other records,
-- without writing any instance.
main :: IO ()
main = do
  putStrLn "Records over IO:"
  summaryWithFile netIO filesIO consoleIO "https://example.org" "note.txt"
  putStrLn "Records over State (output captured in a list):"
  let ((), output) =
        runState (summaryWithFile netTest filesTest consoleTest "https://example.org" "note.txt") []
  mapM_ putStrLn output
