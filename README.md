# MFIS QuickCheck Expr

Proiect pentru Metode Formale in Ingineria Software (tema 20): testarea property-based a unui modul software scris in Haskell, folosind QuickCheck.

Modulul testat este un mini-limbaj de expresii aritmetice. Proprietatile formale verifica semantica, simplificarea algebrica si round-trip-ul prin pretty-printer si parser.

## Structura proiectului

```
src/
  Expr.hs          -- AST si functii auxiliare (size, depth, freeVars, substitute)
  Eval.hs          -- evaluator sigur: Env -> Expr -> Maybe Int
  Simplify.hs      -- simplificator algebric (x*0->0, x+0->x, --x->x etc.)
  Pretty.hs        -- pretty printer cu prioritati corecte
  Parser.hs        -- parser text -> Expr (round-trip cu Pretty)
app/
  Main.hs          -- demo: afiseaza o expresie, o evalueaza, o simplifica
test/
  Spec.hs          -- 16 proprietati QuickCheck + generatoare proprii
Raport.md          -- raportul complet al proiectului
Prezentare-outline.md -- structura slide-urilor pentru prezentare
```

## Cerinte

- GHC 9.6.7
- Cabal 3.14+
- pachetul `QuickCheck` (descarcat automat de cabal)

### Instalare cu GHCup (Windows)

Daca nu ai GHC instalat, descarca `ghcup.exe` si ruleaza:

```
ghcup install ghc recommended
ghcup set ghc recommended
ghcup install cabal recommended
ghcup set cabal recommended
```

Dupa instalare, `ghc.exe` si `cabal.exe` se gasesc in `C:\ghcup\bin\`.

## Comenzi

Toate comenzile se ruleaza din radacina proiectului (`d:\MFIS_Project`).

### Descarca dependintele (prima rulare)

```
cabal update
```

### Build

```
cabal build
```

### Demo (afiseaza o expresie, evalueaza, simplifica, parseaza)

```
cabal run mfis-quickcheck-expr
```

Output exemplu:
```
Proiect MFIS: QuickCheck pe un mini-limbaj aritmetic

Expresie originala: 1 * x + -(-y)
Dimensiune: 7
Adancime: 4
Numar operatori: 4
Variabile libere: ["x","y"]
Valoare in mediu: Just 11
Expresie simplificata: x + y
Valoare simplificata: Just 11
Expresie parsata din text: 1 * x + -(-y)
Semantica pastrata: True
```

### Testare (ruleaza toate proprietatile QuickCheck)

```
cabal test
```

Output exemplu:
```
=== Testare QuickCheck: Mini-limbaj de expresii aritmetice ===

-- Simplificarea pastreaza semantica
+++ OK, passed 120 tests:
62.5% cu variabile
37.5% fara variabile
30.0% expresie mare (>8 noduri)

-- Adunarea este comutativa
+++ OK, passed 120 tests:
57.5% expresii mari
17.5% expresii mici

[... toate 16 proprietati: PASS]
```

### Testare cu output detaliat

```
cabal test spec --test-show-details=direct
```

## Proprietatile testate

| Grupare | Proprietate |
|---|---|
| Corectitudine semantica | Simplificarea pastreaza semantica |
| Corectitudine semantica | Pretty-print + parsare pastreaza semantica |
| Structurale | Simplificarea este idempotenta |
| Structurale | Simplificarea nu mareste dimensiunea / adancimea / nr. operatori |
| Algebrice | Adunarea si inmultirea sunt comutative |
| Algebrice | Adunarea si inmultirea sunt asociative |
| Neutre / absorbante | 0 neutru la adunare, 1 neutru la inmultire, 0 absorbant la inmultire |
| Negatie si scadere | Dubla negatie, scaderea cu sine insusi |
| Substitutie | Substitutia pastreaza semantica |
