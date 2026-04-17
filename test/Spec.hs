module Main where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set

import Eval
import Expr
import Parser
import Pretty
import Simplify
import Test.QuickCheck

variablePool :: [String]
variablePool = ["x", "y", "z", "u", "v", "w", "a", "b", "c"]

genSmallInt :: Gen Int
genSmallInt =
  frequency
    [ (5, chooseInt (-4, 4))
    , (1, chooseInt (-12, 12))
    ]

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

genEnvFor :: Expr -> Gen Env
genEnvFor expr = do
  let names = Set.toList (freeVars expr)
  values <- vectorOf (length names) genSmallInt
  pure (Map.fromList (zip names values))

withEnv :: Expr -> (Env -> Property) -> Property
withEnv expr = forAll (genEnvFor expr)

prop_simplifyPreservesMeaning :: Expr -> Property
prop_simplifyPreservesMeaning expr =
  withEnv expr $ \env ->
    eval env (simplify expr) === eval env expr

prop_prettyParsePreservesMeaning :: Expr -> Property
prop_prettyParsePreservesMeaning expr =
  withEnv expr $ \env ->
    case parseExpr (pretty expr) of
      Nothing ->
        counterexample ("Parser failed for: " ++ pretty expr) False
      Just parsed ->
        eval env parsed === eval env expr

prop_simplifyIdempotent :: Expr -> Bool
prop_simplifyIdempotent expr =
  simplify (simplify expr) == simplify expr

prop_simplifyDoesNotIncreaseSize :: Expr -> Bool
prop_simplifyDoesNotIncreaseSize expr =
  size (simplify expr) <= size expr

prop_simplifyDoesNotIncreaseDepth :: Expr -> Bool
prop_simplifyDoesNotIncreaseDepth expr =
  depth (simplify expr) <= depth expr

prop_simplifyDoesNotIncreaseOperators :: Expr -> Bool
prop_simplifyDoesNotIncreaseOperators expr =
  operatorCount (simplify expr) <= operatorCount expr

prop_addCommutative :: Expr -> Expr -> Property
prop_addCommutative a b =
  withEnv (Add a b) $ \env ->
    eval env (Add a b) === eval env (Add b a)

prop_mulCommutative :: Expr -> Expr -> Property
prop_mulCommutative a b =
  withEnv (Mul a b) $ \env ->
    eval env (Mul a b) === eval env (Mul b a)

prop_addAssociative :: Expr -> Expr -> Expr -> Property
prop_addAssociative a b c =
  withEnv (Add (Add a b) c) $ \env ->
    eval env (Add (Add a b) c) === eval env (Add a (Add b c))

prop_mulAssociative :: Expr -> Expr -> Expr -> Property
prop_mulAssociative a b c =
  withEnv (Mul (Mul a b) c) $ \env ->
    eval env (Mul (Mul a b) c) === eval env (Mul a (Mul b c))

prop_addZeroIdentity :: Expr -> Property
prop_addZeroIdentity expr =
  withEnv expr $ \env ->
    eval env (Add expr (Const 0)) === eval env expr

prop_mulOneIdentity :: Expr -> Property
prop_mulOneIdentity expr =
  withEnv expr $ \env ->
    eval env (Mul expr (Const 1)) === eval env expr

prop_mulZeroAbsorbing :: Expr -> Property
prop_mulZeroAbsorbing expr =
  withEnv expr $ \env ->
    eval env (Mul expr (Const 0)) === Just 0

prop_subSelfZero :: Expr -> Property
prop_subSelfZero expr =
  withEnv expr $ \env ->
    eval env (Sub expr expr) === Just 0

prop_doubleNegation :: Expr -> Property
prop_doubleNegation expr =
  withEnv expr $ \env ->
    eval env (Neg (Neg expr)) === eval env expr

prop_substituteClosedPreservesMeaning :: Expr -> Property
prop_substituteClosedPreservesMeaning expr =
  forAll genClosedExpr $ \closedReplacement ->
    withEnv expr $ \env ->
      case eval env closedReplacement of
        Nothing ->
          counterexample "Closed expression should always evaluate." False
        Just value ->
          let env' = Map.insert "x" value env
           in eval env (substitute "x" closedReplacement expr) === eval env' expr

runProperty :: Testable prop => String -> prop -> IO ()
runProperty name prop = do
  putStrLn ("-- " ++ name)
  quickCheckWith stdArgs {maxSuccess = 120, maxSize = 12} prop
  putStrLn ""

main :: IO ()
main = do
  runProperty "prop_simplifyPreservesMeaning" prop_simplifyPreservesMeaning
  runProperty "prop_prettyParsePreservesMeaning" prop_prettyParsePreservesMeaning
  runProperty "prop_simplifyIdempotent" prop_simplifyIdempotent
  runProperty "prop_simplifyDoesNotIncreaseSize" prop_simplifyDoesNotIncreaseSize
  runProperty "prop_simplifyDoesNotIncreaseDepth" prop_simplifyDoesNotIncreaseDepth
  runProperty "prop_simplifyDoesNotIncreaseOperators" prop_simplifyDoesNotIncreaseOperators
  runProperty "prop_addCommutative" prop_addCommutative
  runProperty "prop_mulCommutative" prop_mulCommutative
  runProperty "prop_addAssociative" prop_addAssociative
  runProperty "prop_mulAssociative" prop_mulAssociative
  runProperty "prop_addZeroIdentity" prop_addZeroIdentity
  runProperty "prop_mulOneIdentity" prop_mulOneIdentity
  runProperty "prop_mulZeroAbsorbing" prop_mulZeroAbsorbing
  runProperty "prop_subSelfZero" prop_subSelfZero
  runProperty "prop_doubleNegation" prop_doubleNegation
  runProperty "prop_substituteClosedPreservesMeaning" prop_substituteClosedPreservesMeaning
