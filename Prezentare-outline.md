# Prezentare: Testarea property-based a modulelor software folosind QuickCheck

---

## Slide 1 — Titlu

- **Metode Formale in Ingineria Software**
- Tema 20: Testarea property-based folosind QuickCheck
- Mini-limbaj de expresii aritmetice in Haskell
- Echipa: [nume1], [nume2]

---

## Slide 2 — Testare clasica vs. property-based testing

**Testare clasica:**
```
eval env (Add (Const 1) (Const 2)) == Just 3
eval env (Mul (Const 5) (Const 0)) == Just 0
```
Problema: acopera doar cazurile la care te-ai gandit.

**Property-based testing:**
```
pentru orice expresii a, b:
  eval env (Add a b) == eval env (Add b a)
```
QuickCheck genereaza automat sute de cazuri si cauta contraexemple.

---

## Slide 3 — Ce este QuickCheck

- **`Arbitrary`** — clasa pentru tipuri care pot fi generate aleatoriu
- **`Gen a`** — tipul unui generator de valori de tip `a`
- **`frequency`** — alege intre generatoare cu ponderi explicite
- **`sized`** — controleaza marimea expresiilor generate
- **`shrink`** — reduce un contraexemplu la forma minima
- **`classify`** — analizeaza distributia cazurilor generate
- **`quickCheckWith`** — ruleaza cu parametri personalizati (nr. teste, marime max)

---

## Slide 4 — Modulul testat: AST si evaluator

**Sintaxa abstracta (AST):**
```haskell
data Expr
  = Const Int
  | Var String
  | Add Expr Expr
  | Sub Expr Expr
  | Mul Expr Expr
  | Neg Expr
```

**Exemplu de arbore** pentru `1 * x + -(-y)`:
```
       Add
      /   \
    Mul    Neg
   /   \    \
  1     x   Neg
               \
                y
```

**Evaluatorul:**
```haskell
eval :: Env -> Expr -> Maybe Int
eval env (Add a b) = liftA2 (+) (eval env a) (eval env b)
eval env (Var x)   = Map.lookup x env
```
Returneaza `Nothing` daca o variabila lipseste din mediu.

---

## Slide 5 — Generatoarele proprii (de ce conteaza)

Generatoarele sunt scrise **manual**, nu derivate automat.
Un generator automat (`genericArbitrary`) nu cunoaste domeniul
si produce expresii dezechilibrate sau prea mari.

**genSmallInt** — ponderi explicite pentru constante:
```haskell
frequency
  [ (5, chooseInt (-4, 4))    -- 83%: numere mici, usor de citit
  , (1, chooseInt (-12, 12))  -- 17%: numere mai mari
  ]
```

**genExpr** — controlat pe marime cu `sized`:
```haskell
frequency
  [ (5, terminal)    -- 26%: Const sau Var (opreste recursivitatea)
  , (2, Neg ...)     -- 11%: negatie
  , (4, bin Add ...) -- 21%: adunare
  , (4, bin Sub ...) -- 21%: scadere
  , (4, bin Mul ...) -- 21%: inmultire
  ]
```

**De ce aceste ponderi:**
- terminalele au ponderea cea mai mare pentru a opri recursivitatea
- `Neg` are pondere mai mica (un singur subarbore vs. doi)
- operatorii binari sunt egali — nu favorizam niciun operator

---

## Slide 6 — shrinkExpr: contraexemple minimale

Cand QuickCheck gaseste un contraexemplu, incearca sa-l reduca:

```haskell
shrinkExpr (Add a b) =
  [a, b]                               -- incearca sub-expresiile
  ++ [Add a' b | a' <- shrinkExpr a]   -- reduce stanga
  ++ [Add a b' | b' <- shrinkExpr b]   -- reduce dreapta
```

**Fara shrink:** contraexemplu posibil:
```
Add (Mul (Add (Var "x") (Const 3)) (Const 2)) (Sub (Var "y") (Const 1))
```

**Cu shrink:** acelasi bug, exprimat minimal:
```
Add (Var "x") (Const 0)
```

---

## Slide 7 — Cele 16 proprietati (grupate)

**Corectitudine semantica:**
- Simplificarea pastreaza semantica in medii complete
- Pretty-print urmat de parsare pastreaza semantica

**Structurale:**
- Simplificarea este idempotenta: `simplify(simplify(e)) == simplify(e)`
- Simplificarea nu mareste dimensiunea / adancimea / numarul de operatori

**Algebrice — comutativitate si asociativitate:**
- `a + b` ≡ `b + a`
- `a * b` ≡ `b * a`
- `(a + b) + c` ≡ `a + (b + c)`
- `(a * b) * c` ≡ `a * (b * c)`

**Elemente neutre si absorbante:**
- `e + 0` ≡ `e`
- `e * 1` ≡ `e`
- `e * 0` ≡ `0`

**Negatie, scadere, substitutie:**
- `e - e` ≡ `0`
- `--e` ≡ `e`
- Substitutia pastreaza semantica

---

## Slide 8 — Exemplu de output cu classify

```
-- Simplificarea pastreaza semantica
+++ OK, passed 120 tests:
62.5% cu variabile
37.5% fara variabile
30.0% expresie mare (>8 noduri)

-- Adunarea este comutativa
+++ OK, passed 120 tests:
57.5% expresii mari
17.5% expresii mici

-- 0 este element absorbant la inmultire
+++ OK, passed 120 tests:
65.8% cu variabile
34.2% fara variabile
```

Procentele pot varia intre rulari, deoarece QuickCheck genereaza date aleatorii.
Proprietatea de simplificare este verificata in medii complete, construite cu `genEnvFor`.
`classify` confirma ca generatorul produce o distributie echilibrata:
atat expresii mici cat si mari, cu si fara variabile.

---

## Slide 9 — Analiza: eficienta metodei

**Avantaje observate:**
- 120 de cazuri per proprietate, generate automat
- contraexemplele sunt reduse automat la forma minima
- proprietatile servesc si ca documentatie executabila

**Limitari observate:**
- proprietatile trebuie formulate corect (o proprietate gresita trece mereu)
- un generator prost testeaza doar cazuri banale — de aceea generatoarele sunt scrise manual
- `Maybe` introduce evaluari partiale; proprietatile semantice folosesc medii complete prin `genEnvFor`

---

## Slide 10 — Concluzii

- **QuickCheck** permite specificarea comportamentului general, nu doar a cazurilor particulare
- Generatoarele manuale (`frequency`, `sized`, `shrink`) sunt esentiale pentru teste relevante
- Un mini-limbaj aritmetic este un exemplu natural pentru Metode Formale: sintaxa clara, semantica precisa, proprietati matematice directe
- Diferenta fata de testarea clasica: nu verificam 5 exemple, ci specificam invarianti valabili pentru orice intrare
