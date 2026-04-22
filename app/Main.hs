module Main where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import System.Environment (getArgs)
import System.Exit (exitFailure)

import Eval
import Expr
import Parser
import Pretty
import Simplify

runExpr :: String -> [(String, Int)] -> IO ()
runExpr input varBindings = do
  case parseExpr input of
    Nothing -> do
      putStrLn ("  EROARE: nu pot parsa expresia: " ++ input)
    Just expr -> do
      let env = Map.fromList varBindings
          simplified = simplify expr
      putStrLn ("  Original:    " ++ pretty expr)
      putStrLn ("  Simplificat: " ++ pretty simplified)
      putStrLn ("  Dimensiune:  " ++ show (size expr) ++ " → " ++ show (size simplified))
      putStrLn ("  Adancime:    " ++ show (depth expr) ++ " → " ++ show (depth simplified))
      let fv = Set.toList (freeVars expr)
      if null fv
        then do
          putStrLn ("  Valoare:     " ++ show (eval env expr))
        else do
          putStrLn ("  Variabile:   " ++ show fv)
          if null varBindings
            then putStrLn ("  Valoare:     (nu ai dat valori pentru variabile)")
            else putStrLn ("  Mediu:       " ++ show varBindings
                        ++ "\n  Valoare:     " ++ show (eval env expr)
                        ++ "\n  Val. simpl.: " ++ show (eval env simplified))
      putStrLn ""

demoExpresii :: [(String, [(String, Int)])]
demoExpresii =
  [ ("1 * x + -(-y)",      [("x", 4), ("y", 7)])
  , ("0 + x * 1",          [("x", 5)])
  , ("(x - x) * 100",      [("x", 3)])
  , ("2 * 3 + 4 * 5",      [])
  , ("x * 0 + y * 1",      [("x", 10), ("y", 42)])
  , ("-(-(x + 1))",        [("x", 8)])
  ]

main :: IO ()
main = do
  args <- getArgs
  putStrLn "=== MFIS: QuickCheck pe un mini-limbaj aritmetic ===\n"
  case args of
    -- mod interactiv: cabal run mfis-quickcheck-expr -- "x + 1" x=5
    (exprStr : rest) -> do
      let varBindings = [ (name, read val :: Int)
                        | arg <- rest
                        , let (name, eqval) = break (== '=') arg
                        , not (null eqval)
                        , let val = tail eqval
                        ]
      putStrLn ("Expresie: " ++ exprStr)
      runExpr exprStr varBindings

    -- mod demo: cabal run mfis-quickcheck-expr
    [] -> do
      putStrLn "Mod demo — ruleaza pe expresii predefinite.\n"
      putStrLn "---"
      mapM_ (uncurry runExpr) demoExpresii
