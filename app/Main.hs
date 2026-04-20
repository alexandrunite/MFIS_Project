module Main where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set

import Eval
import Expr
import Parser
import Pretty
import Simplify

-- Expresie demo pentru a prezenta toate modulele
demoExpr :: Expr
demoExpr =
  Add
    (Mul (Const 1) (Var "x"))
    (Neg (Neg (Var "y")))

-- Mediul de evaluare pentru variabilele din exemplu
demoEnv :: Env
demoEnv = Map.fromList [("x", 4), ("y", 7)]

main :: IO ()
main = do
  putStrLn "Proiect MFIS: QuickCheck pe un mini-limbaj aritmetic"
  putStrLn ""
  putStrLn ("Expresie originala: " ++ pretty demoExpr)
  putStrLn ("Dimensiune: " ++ show (size demoExpr))
  putStrLn ("Adancime: " ++ show (depth demoExpr))
  putStrLn ("Numar operatori: " ++ show (operatorCount demoExpr))
  putStrLn ("Variabile libere: " ++ show (Set.toList (freeVars demoExpr)))
  putStrLn ("Valoare in mediu: " ++ show (eval demoEnv demoExpr))
  putStrLn ("Expresie simplificata: " ++ pretty (simplify demoExpr))
  putStrLn ("Valoare simplificata: " ++ show (eval demoEnv (simplify demoExpr)))
  -- Verificam ca pretty printer-ul si parserul merg impreuna
  case parseExpr (pretty demoExpr) of
    Nothing ->
      putStrLn "Parser: eroare la parsarea expresiei pretty-printed"
    Just parsed -> do
      putStrLn ("Expresie parsata din text: " ++ pretty parsed)
      putStrLn ("Semantica pastrata: " ++ show (eval demoEnv parsed == eval demoEnv demoExpr))
