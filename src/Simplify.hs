module Simplify
  ( simplify
  ) where

import Expr

-- Simplificam expresia pana cand nu mai apare nicio schimbare
simplify :: Expr -> Expr
simplify = fixpoint simplifyOnce
  where
    -- Reaplicam regulile pana cand expresia ajunge la o forma stabila
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
            -- negarea unei constante se calculeaza imediat
            Const n -> Const (-n)
            -- dubla negare dispare: --e devine e
            Neg e' -> e'
            e' -> Neg e'
        Add a b ->
          let a' = simplify a
              b' = simplify b
           in case (a', b') of
                -- Daca ambele parti sunt constante, putem calcula imediat
                (Const x, Const y) -> Const (x + y)
                (Const 0, e) -> e
                (e, Const 0) -> e
                _ -> Add a' b'
        Sub a b ->
          let a' = simplify a
              b' = simplify b
           in case (a', b') of
                (Const x, Const y) -> Const (x - y)
                -- e - e este intotdeauna 0, indiferent de expresie
                (e1, e2)
                  | e1 == e2 -> Const 0
                (e, Const 0) -> e
                -- 0 - e devine -e
                (Const 0, e) -> Neg e
                _ -> Sub a' b'
        Mul a b ->
          let a' = simplify a
              b' = simplify b
           in case (a', b') of
                (Const x, Const y) -> Const (x * y)
                -- 0 anuleaza produsul, iar 1 il lasa neschimbat
                (Const 0, _) -> Const 0
                (_, Const 0) -> Const 0
                (Const 1, e) -> e
                (e, Const 1) -> e
                (Const (-1), e) -> Neg e
                (e, Const (-1)) -> Neg e
                _ -> Mul a' b'
