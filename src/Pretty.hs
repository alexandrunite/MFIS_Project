module Pretty
  ( pretty
  ) where

import Expr

pretty :: Expr -> String
pretty = prettyPrec 0

prettyPrec :: Int -> Expr -> String
prettyPrec ctx expr =
  case expr of
    Const n -> wrapIf (ctx > atomPrec) (prettyConst n)
    Var x -> wrapIf (ctx > atomPrec) x
    Neg e -> wrapIf (ctx > negPrec) ("-" ++ prettyPrec (negPrec + 1) e)
    Add a b ->
      wrapIf (ctx > addPrec) (prettyPrec addPrec a ++ " + " ++ prettyPrec (addPrec + 1) b)
    Sub a b ->
      wrapIf (ctx > addPrec) (prettyPrec addPrec a ++ " - " ++ prettyPrec (addPrec + 1) b)
    Mul a b ->
      wrapIf (ctx > mulPrec) (prettyPrec mulPrec a ++ " * " ++ prettyPrec (mulPrec + 1) b)
  where
    atomPrec = 11
    negPrec = 9
    mulPrec = 7
    addPrec = 6

    wrapIf :: Bool -> String -> String
    wrapIf True s = "(" ++ s ++ ")"
    wrapIf False s = s

    prettyConst :: Int -> String
    prettyConst n
      | n < 0 = "(" ++ show n ++ ")"
      | otherwise = show n
