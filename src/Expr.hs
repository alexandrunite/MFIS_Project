module Expr
  ( Expr (..)
  , VarName
  , size
  , depth
  , operatorCount
  , freeVars
  , substitute
  ) where

-- sa nu avem variabile duplicate
import Data.Set (Set)
import qualified Data.Set as Set

type VarName = String

-- | Asta defineste arborele de expresie.
data Expr
  = Const Int
  | Var VarName
  | Add Expr Expr
  | Sub Expr Expr
  | Mul Expr Expr
  | Neg Expr
  deriving (Eq, Ord, Show)

-- | nr total de noduri in arbore
size :: Expr -> Int
size expr =
  case expr of
    Const _ -> 1
    Var _ -> 1
    Add a b -> 1 + size a + size b
    Sub a b -> 1 + size a + size b
    Mul a b -> 1 + size a + size b
    Neg e -> 1 + size e

-- adancimea maxima a expresiei, cat de adanc eeste arborele
depth :: Expr -> Int
depth expr =
  case expr of
    Const _ -> 1
    Var _ -> 1
    Add a b -> 1 + max (depth a) (depth b)
    Sub a b -> 1 + max (depth a) (depth b)
    Mul a b -> 1 + max (depth a) (depth b)
    Neg e -> 1 + depth e

-- count de cate noduri operator apar in expresie
operatorCount :: Expr -> Int
operatorCount expr =
  case expr of
    Const _ -> 0
    Var _ -> 0
    Add a b -> 1 + operatorCount a + operatorCount b
    Sub a b -> 1 + operatorCount a + operatorCount b
    Mul a b -> 1 + operatorCount a + operatorCount b
    Neg e -> 1 + operatorCount e

-- cate variabile libere apar in expresie
freeVars :: Expr -> Set VarName
freeVars expr =
  case expr of
    Const _ -> Set.empty
    Var x -> Set.singleton x
    Add a b -> Set.union (freeVars a) (freeVars b)
    Sub a b -> Set.union (freeVars a) (freeVars b)
    Mul a b -> Set.union (freeVars a) (freeVars b)
    Neg e -> freeVars e

-- | inlocuim o variabila cu o alte expresie, ex substitute nume replacement expresie
-- substitutia e simpla, pt ca nu exista variabile capture
substitute :: VarName -> Expr -> Expr -> Expr
substitute name replacement expr =
  case expr of
    Const _ -> expr
    Var x
      | x == name -> replacement
      | otherwise -> expr
    Add a b -> Add (substitute name replacement a) (substitute name replacement b)
    Sub a b -> Sub (substitute name replacement a) (substitute name replacement b)
    Mul a b -> Mul (substitute name replacement a) (substitute name replacement b)
    Neg e -> Neg (substitute name replacement e)



-- fie expresia 1 * x + -(-y)
-- expresia de mai sus poate fi scrisa ca un arbore in felul urmator:
  --       Add
  --      /   \
  --    Mul    Neg
  --   /   \    |
  -- 1      x   Neg
  --             |
  --             y