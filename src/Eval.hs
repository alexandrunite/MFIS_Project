-- liftA2 e in Prelude doar din GHC 9.6 (base 4.18); importul explicit
-- pastreaza compatibilitatea cu GHC < 9.6.
{-# OPTIONS_GHC -Wno-unused-imports #-}
module Eval
  ( Env
  , emptyEnv
  , singletonEnv
  , fromListEnv
  , eval
  ) where

import Control.Applicative (liftA2)
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map

import Expr

-- Mediul de evaluare asociaza nume de variabile cu valori Int
type Env = Map VarName Int

emptyEnv :: Env
emptyEnv = Map.empty

singletonEnv :: VarName -> Int -> Env
singletonEnv = Map.singleton

fromListEnv :: [(VarName, Int)] -> Env
fromListEnv = Map.fromList

-- Evaluator sigur: intoarce Nothing daca o variabila nu are valoare
eval :: Env -> Expr -> Maybe Int
eval env expr =
  case expr of
    Const n -> Just n
    Var x -> Map.lookup x env
    -- Operatiile binare reusesc doar daca ambele subexpresii se evalueaza
    Add a b -> liftA2 (+) (eval env a) (eval env b)
    Sub a b -> liftA2 (-) (eval env a) (eval env b)
    Mul a b -> liftA2 (*) (eval env a) (eval env b)
    -- Negarea schimba semnul rezultatului calculat pentru subexpresie
    Neg e -> negate <$> eval env e
