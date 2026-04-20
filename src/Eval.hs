module Eval
  ( Env
  , emptyEnv
  , singletonEnv
  , fromListEnv
  , eval
  ) where

import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map

import Expr

-- | Evaluation environment for variables.
type Env = Map VarName Int

emptyEnv :: Env
emptyEnv = Map.empty

singletonEnv :: VarName -> Int -> Env
singletonEnv = Map.singleton

fromListEnv :: [(VarName, Int)] -> Env
fromListEnv = Map.fromList

-- | Safe interpreter: returns Nothing if a variable is missing.
eval :: Env -> Expr -> Maybe Int
eval env expr =
  case expr of
    Const n -> Just n
    Var x -> Map.lookup x env
    Add a b -> liftA2 (+) (eval env a) (eval env b)
    Sub a b -> liftA2 (-) (eval env a) (eval env b)
    Mul a b -> liftA2 (*) (eval env a) (eval env b)
    Neg e -> negate <$> eval env e
