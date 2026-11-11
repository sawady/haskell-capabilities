{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
-- | Example D, written with the effectful library (effectful-core) instead of
-- the hand-made "Effects". The program, the effects and the handlers are the
-- same ones, and so is the output.
module Main (main) where

import Effectful
import Effectful.Dispatch.Dynamic (interpret, reinterpret, send)
import Effectful.Writer.Static.Local (runWriter, tell)

type Url = String

-- * The effects: they only declare operations, as in "Effects"

-- | The extra parameter, the monad @m@, is for operations that take
-- computations as arguments; these two do not use it.
data Net :: Effect where
  HttpGet :: Url -> Net m String

data Console :: Effect where
  PrintLine :: String -> Console m ()

-- | How the operations of each effect are dispatched: dynamically, that is,
-- with a handler chosen when running the program.
type instance DispatchOf Net = Dynamic
type instance DispatchOf Console = Dynamic

httpGet :: Net :> es => Url -> Eff es String
httpGet = send . HttpGet

printLine :: Console :> es => String -> Eff es ()
printLine = send . PrintLine

-- * The program: polymorphic in the row, as in D

-- | @Net :> es@ is @Member Net es@: Net is in the row.
summary :: (Net :> es, Console :> es) => Url -> Eff es ()
summary url = do
  page <- httpGet url
  printLine (takeWhile (/= '\n') page)

-- * Handlers: each one removes an effect from the row

handleNet :: (Url -> String) -> Eff (Net : es) a -> Eff es a
handleNet pages = interpret $ \_ -> \case
  HttpGet url -> return (pages url)

-- | Interprets Console without IO, with another effect of the library, a
-- Writer, that collects the lines.
handleConsolePure :: Eff (Console : es) a -> Eff es (a, [String])
handleConsolePure = reinterpret runWriter $ \_ -> \case
  PrintLine s -> tell [s]

-- | IO is an effect of the library, IOE, which goes at the end of the row:
-- the role of EmbedIO in "Effects".
handleConsoleIO :: IOE :> es => Eff (Console : es) a -> Eff es a
handleConsoleIO = interpret $ \_ -> \case
  PrintLine s -> liftIO (putStrLn s)

fakePages :: Url -> String
fakePages url = "<title of " ++ url ++ ">\nrest of the page"

-- | runPureEff and runEff are the run and runIO of "Effects".
main :: IO ()
main = do
  putStrLn "Row [Net, Console], handled without IO:"
  let ((), output) = runPureEff (handleConsolePure (handleNet fakePages (summary "https://example.org")))
  mapM_ putStrLn output
  putStrLn "Row [Net, Console, IOE], handled with real IO:"
  runEff (handleConsoleIO (handleNet fakePages (summary "https://example.org")))
