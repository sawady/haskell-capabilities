{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE Safe #-}
-- | An escape that compiles: with 'MonadIO' in the constraints, the
-- function can run any IO action through 'liftIO'. The capabilities Net and
-- Console still say what it may use, and 'MonadIO' gives back everything
-- else: here, it reads the environment, as in A.1.
--
-- At least the escape is in the type, where it can be seen. And it compiles
-- even under Safe Haskell (see the pragma above): 'liftIO' is a safe
-- function, so it is not Safe Haskell that can leave it out.
module Main (main) where

import Capabilities
import Control.Monad.IO.Class (MonadIO (..))
import System.Environment (getEnvironment)

summary :: (Net m, Console m, MonadIO m) => Url -> m ()
summary url = do
  page <- httpGet url
  printLine (firstLine page)
  env <- liftIO getEnvironment
  printLine ("  (read " ++ show (length env) ++ " environment variables without permission)")

-- | B's IO interpreter, which also grants MonadIO.
newtype App a = App { runApp :: IO a }

instance Functor App where
  fmap f (App io) = App (fmap f io)

instance Applicative App where
  pure = App . pure
  App f <*> App x = App (f <*> x)

instance Monad App where
  App io >>= k = App (io >>= runApp . k)

instance MonadIO App where
  liftIO = App

instance Net App where
  httpGet url = App (return ("<title of " ++ url ++ ">\nrest of the page"))

instance Console App where
  printLine = App . putStrLn

main :: IO ()
main = runApp (summary "https://example.org")
