module Simplify
  ( simplify
  ) where

import Expr

-- | Normalize an expression by applying a small set of algebraic laws
-- until a fixed point is reached.
simplify :: Expr -> Expr
simplify = fixpoint simplifyOnce
  where
    fixpoint :: Eq a => (a -> a) -> a -> a
    fixpoint f x =
      let x' = f x
       in if x' == x then x else fixpoint f x'

    simplifyOnce :: Expr -> Expr
    simplifyOnce expr =
      case expr of
        Const _ -> expr
        Var _ -> expr
        Neg e ->
          case simplify e of
            Const n -> Const (-n)
            Neg e' -> e'
            e' -> Neg e'
        Add a b ->
          let a' = simplify a
              b' = simplify b
           in case (a', b') of
                (Const x, Const y) -> Const (x + y)
                (Const 0, e) -> e
                (e, Const 0) -> e
                _ -> Add a' b'
        Sub a b ->
          let a' = simplify a
              b' = simplify b
           in case (a', b') of
                (Const x, Const y) -> Const (x - y)
                (e1, e2)
                  | e1 == e2 -> Const 0
                (e, Const 0) -> e
                (Const 0, e) -> Neg e
                _ -> Sub a' b'
        Mul a b ->
          let a' = simplify a
              b' = simplify b
           in case (a', b') of
                (Const x, Const y) -> Const (x * y)
                (Const 0, _) -> Const 0
                (_, Const 0) -> Const 0
                (Const 1, e) -> e
                (e, Const 1) -> e
                (Const (-1), e) -> Neg e
                (e, Const (-1)) -> Neg e
                _ -> Mul a' b'
