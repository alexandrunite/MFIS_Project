{-# OPTIONS_GHC -Wno-orphans #-}
module Main where

import Data.Maybe (isNothing)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set

import Eval
import Expr
import Parser
import Pretty
import Simplify
import Test.QuickCheck

-- Setul de nume folosit cand QuickCheck genereaza variabile
variablePool :: [String]
variablePool = ["x", "y", "z", "u", "v", "w", "a", "b", "c"]

-- Generam mai des numere mici, ca exemplele sa ramana usor de inteles
genSmallInt :: Gen Int
genSmallInt =
  frequency
    [ (5, chooseInt (-4, 4))
    , (1, chooseInt (-12, 12))
    ]

-- Expresiile inchise (nu contin variabile) nu depind de niciun mediu extern
genClosedExpr :: Gen Expr
genClosedExpr = sized go
  where
    go :: Int -> Gen Expr
    go n
      | n <= 0 = Const <$> genSmallInt
      | otherwise =
          frequency
            [ (6, Const <$> genSmallInt)
            , (2, Neg <$> go (n - 1))
            , (4, bin Add n)
            , (4, bin Sub n)
            , (4, bin Mul n)
            ]

    bin :: (Expr -> Expr -> Expr) -> Int -> Gen Expr
    bin ctor n = do
      leftSize <- chooseInt (0, n - 1)
      let rightSize = n - 1 - leftSize
      ctor <$> go leftSize <*> go rightSize

-- Generatorul general produce atat constante, cat si variabile
genExpr :: Gen Expr
genExpr = sized go
  where
    go :: Int -> Gen Expr
    go n
      | n <= 0 = terminal
      | otherwise =
          frequency
            [ (5, terminal)
            , (2, Neg <$> go (n - 1))
            , (4, bin Add n)
            , (4, bin Sub n)
            , (4, bin Mul n)
            ]

    terminal :: Gen Expr
    terminal =
      frequency
        [ (3, Const <$> genSmallInt)
        , (2, Var <$> elements variablePool)
        ]

    bin :: (Expr -> Expr -> Expr) -> Int -> Gen Expr
    bin ctor n = do
      leftSize <- chooseInt (0, n - 1)
      let rightSize = n - 1 - leftSize
      ctor <$> go leftSize <*> go rightSize

instance Arbitrary Expr where
  arbitrary = genExpr
  shrink = shrinkExpr

-- shrink simplifica un contraexemplu atunci cand un test esueaza
shrinkExpr :: Expr -> [Expr]
shrinkExpr expr =
  case expr of
    Const n -> Const <$> shrinkIntegral n
    Var _ -> []
    Neg e -> e : [Neg e' | e' <- shrinkExpr e]
    Add a b ->
      [a, b]
        ++ [Add a' b | a' <- shrinkExpr a]
        ++ [Add a b' | b' <- shrinkExpr b]
    Sub a b ->
      [a, b]
        ++ [Sub a' b | a' <- shrinkExpr a]
        ++ [Sub a b' | b' <- shrinkExpr b]
    Mul a b ->
      [a, b]
        ++ [Mul a' b | a' <- shrinkExpr a]
        ++ [Mul a b' | b' <- shrinkExpr b]

-- Genereaza un mediu de evaluare complet pentru expresia data:
-- gaseste toate variabilele libere si le asociaza valori Int aleatorii.
genEnvFor :: Expr -> Gen Env
genEnvFor expr = do
  let names = Set.toList (freeVars expr)
  values <- vectorOf (length names) genSmallInt
  pure (Map.fromList (zip names values))

-- Construim automat un mediu compatibil cu variabilele expresiei
withEnv :: Expr -> (Env -> Property) -> Property
withEnv expr = forAll (genEnvFor expr)

-- ===== Corectitudine semantica =====

-- Verifica faptul ca simplificarea schimba doar forma expresiei,
-- nu si valoarea ei calculata.
prop_simplifyPreservesMeaning :: Expr -> Property
prop_simplifyPreservesMeaning expr =
  classify (Set.null (freeVars expr)) "fara variabile" $
  classify (not (Set.null (freeVars expr))) "cu variabile" $
  classify (size expr > 8) "expresie mare (>8 noduri)" $
  withEnv expr $ \env ->
    eval env (simplify expr) === eval env expr

-- Verifica faptul ca o expresie afisata cu pretty poate fi parsata inapoi
-- si ramane echivalenta ca valoare.
prop_prettyParsePreservesMeaning :: Expr -> Property
prop_prettyParsePreservesMeaning expr =
  classify (depth expr > 4) "adancime > 4" $
  classify (operatorCount expr == 0) "expresie terminala" $
  withEnv expr $ \env ->
    case parseExpr (pretty expr) of
      Nothing ->
        counterexample ("Parser a esuat pentru: " ++ pretty expr) False
      Just parsed ->
        eval env parsed === eval env expr

-- ===== Proprietati structurale ale simplificarii =====

-- Verifica faptul ca dupa ce o expresie a fost simplificata,
-- o a doua simplificare nu mai schimba rezultatul.
prop_simplifyIdempotent :: Expr -> Bool
prop_simplifyIdempotent expr =
  simplify (simplify expr) == simplify expr

-- Verifica faptul ca simplificarea nu produce un AST cu mai multe noduri.
prop_simplifyDoesNotIncreaseSize :: Expr -> Bool
prop_simplifyDoesNotIncreaseSize expr =
  size (simplify expr) <= size expr

-- Verifica faptul ca simplificarea nu face arborele expresiei mai adanc.
prop_simplifyDoesNotIncreaseDepth :: Expr -> Bool
prop_simplifyDoesNotIncreaseDepth expr =
  depth (simplify expr) <= depth expr

-- Verifica faptul ca simplificarea nu introduce operatori in plus.
prop_simplifyDoesNotIncreaseOperators :: Expr -> Bool
prop_simplifyDoesNotIncreaseOperators expr =
  operatorCount (simplify expr) <= operatorCount expr

-- ===== Comutativitate si asociativitate =====

-- Verifica comutativitatea adunarii: a + b are aceeasi valoare ca b + a.
prop_addCommutative :: Expr -> Expr -> Property
prop_addCommutative a b =
  classify (size a + size b <= 3) "expresii mici" $
  classify (size a + size b > 8) "expresii mari" $
  withEnv (Add a b) $ \env ->
    eval env (Add a b) === eval env (Add b a)

-- Verifica comutativitatea inmultirii: a * b are aceeasi valoare ca b * a.
prop_mulCommutative :: Expr -> Expr -> Property
prop_mulCommutative a b =
  withEnv (Mul a b) $ \env ->
    eval env (Mul a b) === eval env (Mul b a)

-- Verifica asociativitatea adunarii: (a + b) + c este echivalent cu a + (b + c).
prop_addAssociative :: Expr -> Expr -> Expr -> Property
prop_addAssociative a b c =
  withEnv (Add (Add a b) c) $ \env ->
    eval env (Add (Add a b) c) === eval env (Add a (Add b c))

-- Verifica asociativitatea inmultirii: (a * b) * c este echivalent cu a * (b * c).
prop_mulAssociative :: Expr -> Expr -> Expr -> Property
prop_mulAssociative a b c =
  withEnv (Mul (Mul a b) c) $ \env ->
    eval env (Mul (Mul a b) c) === eval env (Mul a (Mul b c))

-- ===== Elemente neutre si absorbante =====

-- Verifica faptul ca 0 este element neutru la adunare: expr + 0 = expr.
prop_addZeroIdentity :: Expr -> Property
prop_addZeroIdentity expr =
  withEnv expr $ \env ->
    eval env (Add expr (Const 0)) === eval env expr

-- Verifica faptul ca 1 este element neutru la inmultire: expr * 1 = expr.
prop_mulOneIdentity :: Expr -> Property
prop_mulOneIdentity expr =
  withEnv expr $ \env ->
    eval env (Mul expr (Const 1)) === eval env expr

-- Verifica faptul ca 0 este element absorbant la inmultire: expr * 0 = 0.
prop_mulZeroAbsorbing :: Expr -> Property
prop_mulZeroAbsorbing expr =
  classify (Set.null (freeVars expr)) "fara variabile" $
  classify (not (Set.null (freeVars expr))) "cu variabile" $
  withEnv expr $ \env ->
    eval env (Mul expr (Const 0)) === Just 0

-- ===== Negatie si scadere =====

-- Verifica faptul ca scaderea unei expresii din ea insasi da intotdeauna 0.
prop_subSelfZero :: Expr -> Property
prop_subSelfZero expr =
  withEnv expr $ \env ->
    eval env (Sub expr expr) === Just 0

-- Verifica faptul ca dubla negatie nu schimba valoarea expresiei: -(-expr) = expr.
prop_doubleNegation :: Expr -> Property
prop_doubleNegation expr =
  withEnv expr $ \env ->
    eval env (Neg (Neg expr)) === eval env expr

-- ===== Substitutie =====

-- Verifica faptul ca substitutia lui x cu o expresie inchisa este echivalenta
-- cu evaluarea expresiei initiale intr-un mediu unde x are valoarea acelei expresii.
prop_substituteClosedPreservesMeaning :: Expr -> Property
prop_substituteClosedPreservesMeaning expr =
  forAll genClosedExpr $ \closedReplacement ->
    withEnv expr $ \env ->
      case eval env closedReplacement of
        Nothing ->
          counterexample "Expresia inchisa ar trebui sa fie intotdeauna evaluabila." False
        Just value ->
          let env' = Map.insert "x" value env
           in eval env (substitute "x" closedReplacement expr) === eval env' expr

-- ===== Comportament partial (Nothing) =====

-- Orice variabila evaluata intr-un mediu gol returneaza Nothing
prop_varInEmptyEnvIsNothing :: String -> Bool
prop_varInEmptyEnvIsNothing name =
  isNothing (eval emptyEnv (Var name))

-- O expresie care contine cel putin o variabila esueaza in mediu gol
prop_exprWithVarsInEmptyEnvIsNothing :: Expr -> Property
prop_exprWithVarsInEmptyEnvIsNothing expr =
  not (Set.null (freeVars expr)) ==>
    eval emptyEnv expr === Nothing

-- Verifica faptul ca daca stergem din mediu o variabila folosita de expresie,
-- evaluarea expresiei esueaza cu Nothing.
prop_missingVarCausesNothing :: Expr -> Property
prop_missingVarCausesNothing expr =
  not (Set.null (freeVars expr)) ==>
    let someVar = Set.findMin (freeVars expr)
     in forAll (genEnvFor expr) $ \env ->
          eval (Map.delete someVar env) expr === Nothing

-- Folosim aceleasi setari QuickCheck pentru comparatie intre proprietati
runProperty :: Testable prop => String -> prop -> IO ()
runProperty descriere prop = do
  putStrLn ("-- " ++ descriere)
  quickCheckWith stdArgs {maxSuccess = 120, maxSize = 12} prop
  putStrLn ""

main :: IO ()
main = do
  putStrLn "=== Testare QuickCheck: Mini-limbaj de expresii aritmetice ==="
  putStrLn ""
  runProperty "Simplificarea pastreaza semantica" prop_simplifyPreservesMeaning
  runProperty "Pretty-print urmat de parsare pastreaza semantica" prop_prettyParsePreservesMeaning
  runProperty "Simplificarea este idempotenta" prop_simplifyIdempotent
  runProperty "Simplificarea nu mareste dimensiunea" prop_simplifyDoesNotIncreaseSize
  runProperty "Simplificarea nu mareste adancimea" prop_simplifyDoesNotIncreaseDepth
  runProperty "Simplificarea nu mareste numarul de operatori" prop_simplifyDoesNotIncreaseOperators
  runProperty "Adunarea este comutativa" prop_addCommutative
  runProperty "Inmultirea este comutativa" prop_mulCommutative
  runProperty "Adunarea este asociativa" prop_addAssociative
  runProperty "Inmultirea este asociativa" prop_mulAssociative
  runProperty "0 este element neutru la adunare" prop_addZeroIdentity
  runProperty "1 este element neutru la inmultire" prop_mulOneIdentity
  runProperty "0 este element absorbant la inmultire" prop_mulZeroAbsorbing
  runProperty "Scaderea unui termen cu el insusi da 0" prop_subSelfZero
  runProperty "Dubla negatie este identitate" prop_doubleNegation
  runProperty "Substitutia pastreaza semantica" prop_substituteClosedPreservesMeaning
  runProperty "Variabila in mediu gol returneaza Nothing" prop_varInEmptyEnvIsNothing
  runProperty "Expresie cu variabile in mediu gol returneaza Nothing" prop_exprWithVarsInEmptyEnvIsNothing
  runProperty "Variabila lipsa din mediu cauzeaza Nothing" prop_missingVarCausesNothing
