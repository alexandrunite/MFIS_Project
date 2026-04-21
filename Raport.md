# Raport: Testarea property-based a modulelor software folosind QuickCheck

## 1. Introducere

Acest proiect aplica QuickCheck pentru testarea property-based a unui modul software scris in Haskell: un mini-limbaj de expresii aritmetice. Alegerea unui limbaj mic, dar formal, este naturala pentru Metode Formale in Ingineria Software — sintaxa este clara, semantica poate fi definita precis, iar proprietatile matematice pot fi formulate direct ca teste automate.

Scopul proiectului nu este doar sa demonstreze cateva functii Haskell, ci sa arate cum un modul software poate fi validat prin proprietati generale, nu prin exemple individuale.

## 2. Ce sunt metodele formale

Metodele formale folosesc notatii si tehnici matematice pentru a descrie, analiza si verifica programe sau sisteme.

In loc sa spunem doar "programul pare sa functioneze", formulam:

- ce inseamna corectitudinea
- ce invarianti trebuie sa ramana valabili
- ce proprietati trebuie sa fie adevarate pentru toate intrarile relevante

In acest proiect, expresiile aritmetice sunt descrise printr-un tip de date algebric, iar comportamentul lor este verificat prin proprietati formale precum:

- simplificarea pastreaza semantica in medii complete
- adunarea este comutativa la evaluare
- inmultirea cu 0 este absorbanta

## 3. Ce este property-based testing

Testarea clasica porneste de la cateva exemple alese manual:

- `1 + 2 = 3`
- `x * 1 = x`

Aceste teste sunt utile, dar acopera doar un numar mic de cazuri.

Property-based testing porneste de la o proprietate generala si lasa framework-ul sa genereze automat sute de cazuri de test. In loc de "testez 5 exemple", spunem:

- pentru orice expresie si orice mediu complet, simplificarea nu schimba valoarea
- pentru orice expresii `a` si `b`, `a + b` are aceeasi valoare ca `b + a`

Avantajul principal este acoperirea mult mai buna a spatiului de intrare si descoperirea unor cazuri limita la care un dezvoltator nu s-ar gandi usor.

## 4. Ce este QuickCheck

QuickCheck este o biblioteca Haskell pentru testare property-based. Ofera:

- clasa `Arbitrary` cu metoda `arbitrary :: Gen a` pentru generarea de valori aleatoare
- combinatorul `frequency` pentru a controla probabilitatile de generare
- combinatorul `sized` pentru a controla marimea expresiilor generate
- metoda `shrink` pentru reducerea contraexemplelor la forma minimala
- combinatorul `classify` pentru a analiza distributia cazurilor generate
- afisarea unui contraexemplu minimal cand o proprietate esueaza

In acest proiect, QuickCheck este folosit pentru a genera expresii aritmetice si medii de evaluare, si pentru a verifica proprietatile semanticii, simplificarii si parserului.

## 5. De ce Haskell este potrivit pentru aceasta abordare

Haskell este potrivit pentru metode formale si testare property-based din mai multe motive:

- tipurile de date algebrice modeleaza natural structuri sintactice (AST)
- pattern matching face definirea evaluatorului si a simplificatorului clara si directa
- functiile pure au comportament determinist, deci sunt usor de testat
- recursivitatea se potriveste perfect cu arbori de expresii
- QuickCheck este integrat nativ in ecosistemul Haskell

## 6. Descrierea modulului implementat

Proiectul implementeaza un mini-limbaj de expresii aritmetice cu urmatoarele constructii:

```
Expr ::= Const Int
       | Var String
       | Add Expr Expr
       | Sub Expr Expr
       | Mul Expr Expr
       | Neg Expr
```

Modulele principale sunt:

- `Expr` — defineste AST-ul si functii auxiliare: `size`, `depth`, `operatorCount`, `freeVars`, `substitute`
- `Eval` — evaluarea sigura `eval :: Env -> Expr -> Maybe Int`, unde `Env = Map String Int`
- `Simplify` — aplica reguli algebrice pana la punct fix: `x*0 → 0`, `x+0 → x`, `--x → x` etc.
- `Pretty` — transforma expresiile in text lizibil, cu paranteze corecte dupa prioritati
- `Parser` — transforma textul inapoi in expresii (round-trip cu Pretty)
- `test/Spec.hs` — generatoarele si cele 16 proprietati QuickCheck

Evaluarea returneaza `Maybe Int`: `Nothing` daca o variabila din expresie nu exista in mediu, `Just n` altfel.

## 7. Generatoarele QuickCheck

Generatoarele sunt scrise manual, nu derivate automat. Aceasta este intentionata: un generator automat nu cunoaste domeniul si produce expresii dezechilibrate sau prea mari.

### genSmallInt

```haskell
genSmallInt :: Gen Int
genSmallInt =
  frequency
    [ (5, chooseInt (-4, 4))   -- 83% din cazuri: numere mici
    , (1, chooseInt (-12, 12)) -- 17% din cazuri: numere mai mari
    ]
```

Ponderile 5:1 asigura ca majoritatea constantelor sunt mici, evitand overflow si pastrând contraexemplele lizibile.

### genExpr

```haskell
genExpr = sized go
  where
    go n
      | n <= 0 = terminal
      | otherwise =
          frequency
            [ (5, terminal)      -- 26% terminale (Const sau Var)
            , (2, Neg <$> ...)   -- 11% negatii
            , (4, bin Add ...)   -- 21% adunari
            , (4, bin Sub ...)   -- 21% scaderi
            , (4, bin Mul ...)   -- 21% inmultiri
            ]
```

`sized` controleaza adancimea recursiei — QuickCheck creste treptat `n` de la 0 la `maxSize` (setat la 12 in proiect), evitand arbori infiniti.

Terminalele sunt:
```haskell
terminal = frequency
  [ (3, Const <$> genSmallInt)         -- 60% constante
  , (2, Var <$> elements variablePool) -- 40% variabile
  ]
```

### shrinkExpr

`shrink` reduce un contraexemplu la forma minima pentru a usura debug-ul:

```haskell
shrinkExpr (Add a b) =
  [a, b]                              -- incearca sub-expresiile direct
  ++ [Add a' b | a' <- shrinkExpr a]  -- reduce stanga
  ++ [Add a b' | b' <- shrinkExpr b]  -- reduce dreapta
```

Astfel, daca o proprietate esueaza pe `Add (Mul x (Const 3)) (Const 0)`, QuickCheck va incerca sa reduca la `Mul x (Const 3)`, `Const 0`, `Add x (Const 0)` etc., pana gaseste cel mai mic contraexemplu.

### genEnvFor

Genereaza un mediu care contine exact variabilele libere din expresie:

```haskell
genEnvFor expr = do
  let names = Set.toList (freeVars expr)
  values <- vectorOf (length names) genSmallInt
  pure (Map.fromList (zip names values))
```

Acest lucru garanteaza ca evaluarea returneaza intotdeauna `Just n` (nu `Nothing`) in proprietatile semantice.

## 8. Proprietatile formale definite

Au fost implementate 16 proprietati, grupate logic:

### Corectitudine semantica

Proprietatile semantice sunt formulate pentru medii complete: `genEnvFor` construieste un `Env` care contine toate variabilele libere ale expresiei. Aceasta preconditie este importanta deoarece evaluatorul intoarce `Nothing` pentru variabile lipsa.

| Proprietate | Descriere |
|---|---|
| `prop_simplifyPreservesMeaning` | Simplificarea nu schimba valoarea expresiei in medii complete |
| `prop_prettyParsePreservesMeaning` | `parse(pretty(e))` evalueaza la acelasi rezultat ca `e` |

### Proprietati structurale

| Proprietate | Descriere |
|---|---|
| `prop_simplifyIdempotent` | `simplify(simplify(e)) == simplify(e)` |
| `prop_simplifyDoesNotIncreaseSize` | Simplificarea nu mareste numarul de noduri |
| `prop_simplifyDoesNotIncreaseDepth` | Simplificarea nu mareste adancimea arborelui |
| `prop_simplifyDoesNotIncreaseOperators` | Simplificarea nu mareste numarul de operatori |

### Comutativitate si asociativitate

| Proprietate | Descriere |
|---|---|
| `prop_addCommutative` | `a + b` evalueaza la fel ca `b + a` |
| `prop_mulCommutative` | `a * b` evalueaza la fel ca `b * a` |
| `prop_addAssociative` | `(a + b) + c` evalueaza la fel ca `a + (b + c)` |
| `prop_mulAssociative` | `(a * b) * c` evalueaza la fel ca `a * (b * c)` |

### Elemente neutre si absorbante

| Proprietate | Descriere |
|---|---|
| `prop_addZeroIdentity` | `e + 0` evalueaza la fel ca `e` |
| `prop_mulOneIdentity` | `e * 1` evalueaza la fel ca `e` |
| `prop_mulZeroAbsorbing` | `e * 0` evalueaza intotdeauna la `Just 0` |

### Negatie si scadere

| Proprietate | Descriere |
|---|---|
| `prop_subSelfZero` | `e - e` evalueaza intotdeauna la `Just 0` |
| `prop_doubleNegation` | `--e` evalueaza la fel ca `e` |

### Substitutie

| Proprietate | Descriere |
|---|---|
| `prop_substituteClosedPreservesMeaning` | Substituirea lui `x` cu o expresie inchisa pastreaza semantica |

## 9. Experiment practic si rezultate

Fiecare proprietate este rulata cu 120 de cazuri de test (`maxSuccess = 120`) si expresii de marime maxima 12 (`maxSize = 12`).

Exemplu de output al proiectului. Procentele afisate de `classify` pot varia intre rulari, deoarece QuickCheck genereaza date aleatorii; important este ca proprietatile trec si ca distributia cazurilor nu este triviala.

Linia "Simplificarea pastreaza semantica" trebuie citita cu preconditia folosita in test: expresia este evaluata intr-un mediu complet, generat cu `genEnvFor`.

```
=== Testare QuickCheck: Mini-limbaj de expresii aritmetice ===

-- Simplificarea pastreaza semantica
+++ OK, passed 120 tests:
62.5% cu variabile
37.5% fara variabile
30.0% expresie mare (>8 noduri)

-- Pretty-print urmat de parsare pastreaza semantica
+++ OK, passed 120 tests:
36.7% expresie terminala
22.5% adancime > 4

-- Adunarea este comutativa
+++ OK, passed 120 tests:
57.5% expresii mari
17.5% expresii mici

-- 0 este element absorbant la inmultire
+++ OK, passed 120 tests:
65.8% cu variabile
34.2% fara variabile

[... toate 16 proprietati: PASS]
```

`classify` confirma ca generatorul produce o distributie echilibrata: atat expresii mici cat si mari, atat cu variabile cat si fara.

### Ce se intampla cand o proprietate esueaza

Daca, de exemplu, simplificatorul ar contine un bug in regula `x + 0 → x`, QuickCheck ar raporta:

```
*** Failed! Falsifiable (after 3 tests and 4 shrinks):
Add (Var "x") (Const 0)
cu mediu fromList [("x", 2)]
Expected: Just 2
Got:      Just 99
```

Datorita `shrinkExpr`, contraexemplul este deja redus la forma minima — in loc de o expresie mare si greu de citit.

## 10. Avantaje si limitari ale abordarii

### Avantaje

- testeaza sute de cazuri automat, nu doar exemple manuale
- gaseste rapid erori de logica in simplificare sau parsare
- contraexemplele sunt reduse automat la forma minima prin `shrink`
- `classify` ofera vizibilitate asupra distributiei cazurilor generate
- proprietatile servesc si ca documentatie executabila a modulului

### Limitari

- proprietatile trebuie formulate cu grija (o proprietate gresita trece intotdeauna)
- generatorul trebuie sa produca o distributie buna — un generator slab testeaza doar cazuri banale
- `Maybe` introduce evaluari partiale, deci proprietatile semantice necesita medii complete
- QuickCheck nu inlocuieste demonstratia matematica formala, ci o completeaza

## 11. Concluzii

Proiectul demonstreaza ca Haskell si QuickCheck se potrivesc pentru Metode Formale in Ingineria Software. Un mini-limbaj de expresii aritmetice este suficient de simplu pentru a fi inteles rapid, dar suficient de bogat pentru a ilustra:

- definire formala de AST
- semantica operationala prin evaluator
- simplificare algebrica
- round-trip prin pretty-print si parsare
- verificare automata prin 16 proprietati formale

Diferenta fata de testarea clasica este clara: nu verificam cateva exemple alese manual, ci specificam comportamentul general al modulului si lasam QuickCheck sa caute contraexemple in sute de cazuri generate controlat.
