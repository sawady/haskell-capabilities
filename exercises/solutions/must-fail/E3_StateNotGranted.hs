{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE FlexibleContexts #-}
-- | Solution to exercise 3b: C2's summary without @MonadState Int m@ in its
-- signature. The body still counts requests, and the signature no longer
-- grants the state, so GHC cannot deduce it. Since nothing fixes the type of
-- the counter any more, GHC defaults the literal @1@ to 'Integer', and the
-- message asks for @MonadState Integer m@.
-- Expected error: [GHC-39999]
module Main (main) where

import Capabilities (Net (..), Url, firstLine)
import Control.Monad.Reader (MonadReader, ask)
import Control.Monad.State (MonadState, get, modify)

data Config = Config { server :: Url }

summary :: (MonadReader Config m, Net m) => String -> m String
summary path = do
  cfg <- ask
  modify (+ 1)
  page <- httpGet (server cfg ++ path)
  n <- get
  return (firstLine page ++ " (request " ++ show n ++ ")")

main :: IO ()
main = return ()
