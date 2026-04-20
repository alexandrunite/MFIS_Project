module Parser
  ( parseExpr
  ) where

import Data.Char (isAlpha, isAlphaNum, isDigit)
import Data.Maybe (listToMaybe)
import Text.ParserCombinators.ReadP

import Expr

-- Parserul accepta o expresie completa si ignora spatiile exterioare
parseExpr :: String -> Maybe Expr
parseExpr input =
  listToMaybe
    [ expr
    | (expr, rest) <- readP_to_S (skipSpaces *> exprP <* skipSpaces <* eof) input
    , null rest
    ]

-- Suma si diferenta au prioritate mai mica decat produsul
exprP :: ReadP Expr
exprP = chainl1 termP addOp

termP :: ReadP Expr
termP = chainl1 factorP mulOp

-- Negarea unara este analizata inaintea atomilor
factorP :: ReadP Expr
factorP = negP +++ atomP

atomP :: ReadP Expr
atomP = negConstP +++ parens exprP +++ integerP +++ variableP

-- negare unara: '-' urmat de un factor (ex: -x, -(a+b))
negP :: ReadP Expr
negP = do
  _ <- symbol "-"
  Neg <$> factorP

-- constanta negativa scrisa explicit intre paranteze: (-3)
negConstP :: ReadP Expr
negConstP = do
  _ <- symbol "("
  _ <- symbol "-"
  n <- naturalP
  _ <- symbol ")"
  pure (Const (-n))

-- orice expresie inconjurata de paranteze
parens :: ReadP a -> ReadP a
parens p = do
  _ <- symbol "("
  x <- p
  _ <- symbol ")"
  pure x

-- '+' produce Add, '-' produce Sub
addOp :: ReadP (Expr -> Expr -> Expr)
addOp =
  (symbol "+" >> pure Add)
    +++ (symbol "-" >> pure Sub)

-- singurul operator multiplicativ este '*'
mulOp :: ReadP (Expr -> Expr -> Expr)
mulOp = symbol "*" >> pure Mul

integerP :: ReadP Expr
integerP = Const <$> naturalP

naturalP :: ReadP Int
naturalP = token $ read <$> munch1 isDigit

variableP :: ReadP Expr
variableP = token $ do
  first <- satisfy isAlpha
  rest <- munch (\c -> isAlphaNum c || c == '_')
  pure (Var (first : rest))

-- token consuma automat spatiile din jurul elementelor simple
token :: ReadP a -> ReadP a
token p = skipSpaces *> p <* skipSpaces

symbol :: String -> ReadP String
symbol s = token (string s)
