module Expr
  ( Expr (..)
  , VarName
  , size
  , depth
  , operatorCount
  , freeVars
  , substitute
  ) where

-- folosim Set ca sa nu apara variabile duplicate in freeVars
import Data.Set (Set)
import qualified Data.Set as Set

-- un nume de variabila este doar un sir de caractere
type VarName = String

-- AST-ul: fiecare constructor reprezinta un tip de nod in arborele de expresie
data Expr
  = Const Int
  | Var VarName
  | Add Expr Expr
  | Sub Expr Expr
  | Mul Expr Expr
  | Neg Expr
  deriving (Eq, Ord, Show)

-- nr total de noduri in arbore
size :: Expr -> Int
size expr =
  case expr of
    Const _ -> 1
    Var _ -> 1
    Add a b -> 1 + size a + size b
    Sub a b -> 1 + size a + size b
    Mul a b -> 1 + size a + size b
    Neg e -> 1 + size e

-- adancimea maxima a arborelui: cat de adanc este ramura cea mai lunga
depth :: Expr -> Int
depth expr =
  case expr of
    Const _ -> 1
    Var _ -> 1
    Add a b -> 1 + max (depth a) (depth b)
    Sub a b -> 1 + max (depth a) (depth b)
    Mul a b -> 1 + max (depth a) (depth b)
    Neg e -> 1 + depth e

-- numarul de noduri operator din expresie (Add, Sub, Mul, Neg)
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

-- Inlocuim o variabila cu o alta expresie in tot arborele
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