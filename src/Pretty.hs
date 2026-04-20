module Pretty
  ( pretty
  ) where

import Expr

-- Punctul de intrare: pornim cu contextul 0 (nicio prioritate exterioara)
pretty :: Expr -> String
pretty = prettyPrec 0

-- ctx este prioritatea operatorului parinte; daca expresia curenta are
-- prioritate mai mica, o inconjuram cu paranteze
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
    -- valorile de precedenta: mai mare inseamna leaga mai tare
    atomPrec = 11
    negPrec = 9
    mulPrec = 7
    addPrec = 6

    wrapIf :: Bool -> String -> String
    wrapIf True s = "(" ++ s ++ ")"
    wrapIf False s = s

    -- constantele negative necesita paranteze ca sa nu fie confundate cu Sub
    prettyConst :: Int -> String
    prettyConst n
      | n < 0 = "(" ++ show n ++ ")"
      | otherwise = show n
