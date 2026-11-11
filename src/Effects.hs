{-# LANGUAGE DataKinds #-}
{-# LANGUAGE EmptyCase #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeOperators #-}
-- | An effect system with rows, written by hand (used by example D).
--
-- A computation of type @Eff es a@ may use the effects in the list @es@
-- (the "row"). A function that is polymorphic in @es@ and asks for
-- @Member Net es@ works in any row that contains Net: that is row
-- polymorphism. A handler removes one effect from the row and interprets
-- it; when the row is empty, the computation is pure.
--
-- It is a minimal version of what libraries such as effectful, polysemy or
-- fused-effects do, and languages such as Koka. It needs several
-- extensions: the row is a type-level list.
--
-- The constructors of 'Eff' and 'Union', and 'send', are exported so that
-- new effects and their handlers can be written outside this module.
module Effects
  ( Url
  , Eff (..)
  , Union (..)
  , Member
  , send
  , Net (..)
  , Console (..)
  , EmbedIO (..)
  , httpGet
  , printLine
  , handleNet
  , handleConsolePure
  , handleConsoleIO
  , run
  , runIO
  ) where

import Data.Kind (Type)

type Url = String

-- * The row and the open union

-- | A request for one of the effects in the row @es@.
data Union (es :: [Type -> Type]) (a :: Type) where
  Here :: e a -> Union (e ': es) a
  There :: Union es a -> Union (e ': es) a

-- | @Member e es@: the effect @e@ is in the row @es@.
class Member (e :: Type -> Type) (es :: [Type -> Type]) where
  inject :: e a -> Union es a

instance {-# OVERLAPPING #-} Member e (e ': es) where
  inject = Here

instance Member e es => Member e (f ': es) where
  inject = There . inject

-- * The effect monad (a free monad over the union)

data Eff (es :: [Type -> Type]) a where
  Pure :: a -> Eff es a
  Request :: Union es x -> (x -> Eff es a) -> Eff es a

instance Functor (Eff es) where
  fmap f (Pure a) = Pure (f a)
  fmap f (Request u k) = Request u (fmap f . k)

instance Applicative (Eff es) where
  pure = Pure
  mf <*> mx = mf >>= \f -> fmap f mx

instance Monad (Eff es) where
  Pure a >>= f = f a
  Request u k >>= f = Request u (\x -> k x >>= f)

send :: Member e es => e a -> Eff es a
send op = Request (inject op) Pure

-- * The effects: they only declare operations, not how they are done

data Net a where
  HttpGet :: Url -> Net String

data Console a where
  PrintLine :: String -> Console ()

-- | Embeds IO as one more effect, which goes at the end of the row.
data EmbedIO a where
  EmbedIO :: IO a -> EmbedIO a

httpGet :: Member Net es => Url -> Eff es String
httpGet = send . HttpGet

printLine :: Member Console es => String -> Eff es ()
printLine = send . PrintLine

-- * Handlers: each one removes an effect from the row

-- | Interprets Net with a fixed table.
handleNet :: (Url -> String) -> Eff (Net ': es) a -> Eff es a
handleNet _ (Pure a) = Pure a
handleNet pages (Request (Here (HttpGet url)) k) = handleNet pages (k (pages url))
handleNet pages (Request (There u) k) = Request u (handleNet pages . k)

-- | Interprets Console without IO, collecting the lines.
handleConsolePure :: Eff (Console ': es) a -> Eff es (a, [String])
handleConsolePure (Pure a) = Pure (a, [])
handleConsolePure (Request (Here (PrintLine s)) k) = do
  (a, rest) <- handleConsolePure (k ())
  return (a, s : rest)
handleConsolePure (Request (There u) k) = Request u (handleConsolePure . k)

-- | Interprets Console with real IO, which has to be further down the row.
handleConsoleIO :: Member EmbedIO es => Eff (Console ': es) a -> Eff es a
handleConsoleIO (Pure a) = Pure a
handleConsoleIO (Request (Here (PrintLine s)) k) = send (EmbedIO (putStrLn s)) >>= handleConsoleIO . k
handleConsoleIO (Request (There u) k) = Request u (handleConsoleIO . k)

-- | With the row empty there is no effect left: the result is pure.
run :: Eff '[] a -> a
run (Pure a) = a
run (Request u _) = case u of {}

runIO :: Eff '[EmbedIO] a -> IO a
runIO (Pure a) = return a
runIO (Request (Here (EmbedIO io)) k) = io >>= runIO . k
runIO (Request (There u) _) = case u of {}
