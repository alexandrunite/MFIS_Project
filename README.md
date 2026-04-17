# MFIS QuickCheck Expr

Proiectul implementeaza un mini-limbaj de expresii aritmetice in Haskell si il foloseste pentru testare property-based cu QuickCheck.

## Ce face proiectul

- defineste un AST pentru expresii aritmetice
- evalueaza expresii intr-un mediu `Map String Int`
- simplifica expresii prin reguli algebrice
- le afiseaza cu un pretty printer
- le parseaza inapoi din text
- testeaza proprietati formale cu QuickCheck

## Structura

- `app/Main.hs` - demo simplu
- `src/Expr.hs` - AST si functii auxiliare
- `src/Eval.hs` - evaluator sigur
- `src/Simplify.hs` - simplificator / optimizer
- `src/Pretty.hs` - pretty printer
- `src/Parser.hs` - parser simplu cu `ReadP`
- `test/Spec.hs` - proprietati QuickCheck
- `Raport.md` - raportul proiectului
- `Prezentare-outline.md` - structura pentru prezentare

## Instalare dependinte

Proiectul foloseste `cabal`. In mod normal ai nevoie de:

- GHC
- Cabal
- pachetul `QuickCheck` (este descarcat automat de `cabal`)

Daca ai GHCup instalat, poti folosi:

```bash
ghcup install ghc
ghcup install cabal
```

## Build

Din radacina proiectului:

```bash
cabal build
```

## Rulare

Rulare aplicatie demo:

```bash
cabal run mfis-quickcheck-expr
```

## Testare

Ruleaza proprietatile QuickCheck:

```bash
cabal test
```

Sau, daca vrei doar testul suite-ului:

```bash
cabal test spec
```

## Exemple utile

Afiseaza demo-ul si vezi simplificarea si parsarea aceleiasi expresii:

```bash
cabal run mfis-quickcheck-expr
```

Ruleaza testele cu detalii directe:

```bash
cabal test spec --test-show-details=direct
```

## Cum poti extinde proiectul

1. Adauga expresii booleene si comparatii.
2. Introdu variabile cu tipuri diferite sau medii mai complexe.
3. Scrie un parser mai serios, de exemplu cu Megaparsec.
4. Extinde simplificatorul cu reguli mai avansate.
5. Compara doi interpretoare diferite pentru acelasi limbaj.
