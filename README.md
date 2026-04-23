# MFIS QuickCheck Expr

Proiect pentru disciplina **Metode Formale in Ingineria Software**, tema 20:
testarea property-based a unui modul software scris in Haskell, folosind
QuickCheck.

Proiectul implementeaza un mini-limbaj de expresii aritmetice si verifica,
prin proprietati formale, ca parserul, pretty-printerul, evaluatorul,
simplificatorul si functiile structurale se comporta corect impreuna.

Ideea centrala este ca nu testam doar cateva exemple alese manual, ci formulam
legi generale, iar QuickCheck genereaza automat expresii multe si variate pentru
a cauta eventuale contraexemple.

## Context

- Tema: **Testarea property-based a modulelor software folosind QuickCheck**
- Limbaj: **Haskell**
- Biblioteca de testare: **QuickCheck**
- Domeniu testat: expresii aritmetice cu variabile
- Echipa, conform prezentarii: **Mihaila Denisa (352)** si
  **Nite Dan-Alexandru (344)**

## Ce modeleaza proiectul

Mini-limbajul are urmatoarea forma de AST, definita in `src/Expr.hs`:

```haskell
data Expr
  = Const Int
  | Var VarName
  | Add Expr Expr
  | Sub Expr Expr
  | Mul Expr Expr
  | Neg Expr
```

Astfel, o expresie textuala precum:

```text
1 * x + -(-y)
```

este transformata de parser intr-un arbore de expresie echivalent cu:

```haskell
Add
  (Mul (Const 1) (Var "x"))
  (Neg (Neg (Var "y")))
```

Apoi:

- `Simplify.hs` o poate simplifica la `x + y`;
- `Eval.hs` o poate evalua intr-un mediu, de exemplu `x = 4`, `y = 7`;
- `Pretty.hs` o poate transforma inapoi intr-un text lizibil;
- `Spec.hs` verifica automat proprietatile importante ale acestor transformari.

## Arhitectura proiectului

```text
src/
  Expr.hs          AST-ul si functii structurale:
                   size, depth, operatorCount, freeVars, substitute

  Eval.hs          evaluator sigur:
                   eval :: Env -> Expr -> Maybe Int

  Simplify.hs      simplificator algebric aplicat pana la punct fix

  Pretty.hs        pretty-printer cu reguli de precedenta si parantezare

  Parser.hs        parser text -> Expr, cu precedenta corecta a operatorilor

app/
  Main.hs          aplicatie demo pentru parsare, simplificare si evaluare

test/
  Spec.hs          generatoare custom si 19 proprietati QuickCheck

mfis-quickcheck-expr.cabal
                  configurarea componentelor Cabal:
                  library, executable si test-suite

Testarea property-based folosind QuickCheck.pptx
                  prezentarea proiectului
```

## Fluxul principal

Fluxul logic al proiectului este:

```text
String introdus de utilizator
        |
        v
Parser.hs
        |
        v
Expr, adica AST
        |
        +--> Simplify.hs  simplifica expresia
        |
        +--> Eval.hs      calculeaza valoarea expresiei
        |
        +--> Pretty.hs    afiseaza expresia intr-o forma lizibila
        |
        v
Spec.hs verifica proprietati generale cu QuickCheck
```

Exemplu conceptual:

```text
Input:       "1 * x + -(-y)"
Parser:      Add (Mul (Const 1) (Var "x")) (Neg (Neg (Var "y")))
Simplify:    Add (Var "x") (Var "y")
Pretty:      "x + y"
Eval:        Just 11, pentru x = 4 si y = 7
```

## Modulele principale

### `Expr.hs`

Defineste structura expresiilor si functii auxiliare folosite atat in aplicatie,
cat si in teste:

- `size` calculeaza numarul total de noduri din AST;
- `depth` calculeaza adancimea maxima a arborelui;
- `operatorCount` numara operatorii `Add`, `Sub`, `Mul`, `Neg`;
- `freeVars` intoarce multimea variabilelor libere;
- `substitute` inlocuieste recursiv o variabila cu o alta expresie.

### `Eval.hs`

Defineste evaluatorul:

```haskell
eval :: Env -> Expr -> Maybe Int
```

`Env` este un `Map` de la nume de variabile la valori intregi:

```haskell
type Env = Map VarName Int
```

Evaluatorul intoarce:

- `Just valoare`, daca expresia poate fi calculata;
- `Nothing`, daca apare o variabila care nu exista in mediu.

Acest design evita exceptiile runtime pentru variabile nedefinite.

### `Simplify.hs`

Aplica reguli algebrice recursiv, pana cand expresia ajunge la o forma stabila
si nu se mai modifica.

Reguli implementate:

```text
x + 0      -> x
0 + x      -> x
x * 1      -> x
1 * x      -> x
x * 0      -> 0
0 * x      -> 0
x - x      -> 0
0 - x      -> -x
--x        -> x
Const a + Const b -> Const (a + b)
Const a - Const b -> Const (a - b)
Const a * Const b -> Const (a * b)
```

### `Parser.hs`

Parseaza textul introdus de utilizator si construieste AST-ul.

Precedenta operatorilor este definita prin straturi de parseri:

```haskell
exprP = chainl1 termP addOp
termP = chainl1 factorP mulOp
```

Ordinea este:

```text
prioritate mica:   + si -
prioritate medie:  *
prioritate mare:   negare unara, paranteze, constante, variabile
```

Parserul suporta:

- spatii intre token-uri;
- variabile formate din litera, apoi litere/cifre/underscore;
- constante intregi;
- paranteze;
- negare unara, de exemplu `-x` si `-(x + 1)`;
- constante negative scrise explicit ca `(-3)`;
- validarea inputului complet prin `eof`.

### `Pretty.hs`

Transforma AST-ul inapoi intr-un sir de caractere.

Pretty-printerul foloseste prioritati numerice pentru a decide cand trebuie
adaugate paranteze:

```text
atomPrec = 11
negPrec  = 9
mulPrec  = 7
addPrec  = 6
```

Scopul este ca `pretty expr` sa produca un text care poate fi parsat inapoi si
care pastreaza aceeasi semantica.

### `Spec.hs`

Contine testele property-based. Aici sunt definite:

- generatorul general `genExpr`;
- generatorul pentru expresii inchise `genClosedExpr`;
- generatorul de medii complete `genEnvFor`;
- functia de shrinking `shrinkExpr`;
- cele 19 proprietati QuickCheck.

## Generatoare QuickCheck

Generatoarele sunt scrise manual, nu derivate automat, pentru a controla mai
bine forma expresiilor generate.

### `genSmallInt`

Genereaza mai des numere mici, pentru ca exemplele si contraexemplele sa fie
usor de citit:

```haskell
frequency
  [ (5, chooseInt (-4, 4))
  , (1, chooseInt (-12, 12))
  ]
```

### `genExpr`

Genereaza expresii generale, cu constante si variabile. Foloseste `sized` pentru
a limita recursivitatea si `frequency` pentru a controla distributia:

- terminalele apar mai des, ca sa opreasca recursivitatea;
- `Neg` are pondere mai mica, deoarece are un singur subarbore;
- `Add`, `Sub` si `Mul` au ponderi egale.

### `genClosedExpr`

Genereaza expresii fara variabile. Este folosit mai ales la proprietatea de
substitutie, unde inlocuirea lui `x` se face cu o expresie care poate fi evaluata
independent de mediu.

### `genEnvFor`

Construieste automat un mediu complet pentru o expresie:

```haskell
let names = Set.toList (freeVars expr)
values <- vectorOf (length names) genSmallInt
pure (Map.fromList (zip names values))
```

Astfel, daca expresia contine variabilele `x` si `y`, QuickCheck genereaza
automat valori pentru ambele. Acest lucru reduce falsele esecuri cauzate doar de
variabile lipsa.

### `shrinkExpr`

Cand o proprietate esueaza, QuickCheck incearca sa reduca expresia la un
contraexemplu mai mic si mai usor de inteles.

De exemplu, un contraexemplu mare poate fi redus la unul de forma:

```haskell
Add (Var "x") (Const 0)
```

Aceasta face debugging-ul mult mai clar la prezentare si in dezvoltare.

## Proprietatile testate

Testele sunt rulate cu:

```haskell
quickCheckWith stdArgs {maxSuccess = 120, maxSize = 12}
```

Deci fiecare proprietate este verificata pe 120 de cazuri generate automat, iar
marimea expresiilor este tinuta sub control.

| Nr. | Grupare | Proprietate |
|---:|---|---|
| 1 | Corectitudine semantica | Simplificarea pastreaza semantica expresiei |
| 2 | Corectitudine semantica | Pretty-print urmat de parsare pastreaza semantica |
| 3 | Structurala | Simplificarea este idempotenta |
| 4 | Structurala | Simplificarea nu mareste dimensiunea AST-ului |
| 5 | Structurala | Simplificarea nu mareste adancimea AST-ului |
| 6 | Structurala | Simplificarea nu mareste numarul de operatori |
| 7 | Algebrica | Adunarea este comutativa: `a + b == b + a` |
| 8 | Algebrica | Inmultirea este comutativa: `a * b == b * a` |
| 9 | Algebrica | Adunarea este asociativa |
| 10 | Algebrica | Inmultirea este asociativa |
| 11 | Elemente neutre | `0` este element neutru la adunare |
| 12 | Elemente neutre | `1` este element neutru la inmultire |
| 13 | Element absorbant | `0` este element absorbant la inmultire |
| 14 | Scadere | `expr - expr == 0` |
| 15 | Negatie | Dubla negatie pastreaza valoarea: `-(-expr) == expr` |
| 16 | Substitutie | Substitutia cu o expresie inchisa pastreaza semantica |
| 17 | Evaluare partiala | O variabila intr-un mediu gol produce `Nothing` |
| 18 | Evaluare partiala | O expresie cu variabile intr-un mediu gol produce `Nothing` |
| 19 | Evaluare partiala | Stergerea unei variabile libere din mediu produce `Nothing` |

## De ce sunt importante aceste proprietati

Proprietatile semantice verifica faptul ca transformarile nu schimba valoarea
expresiei. De exemplu, `simplify` poate schimba forma AST-ului, dar nu trebuie
sa schimbe rezultatul evaluarii.

Proprietatile structurale verifica faptul ca simplificarea chiar simplifica:
nu creste dimensiunea, adancimea sau numarul de operatori.

Proprietatile algebrice verifica legi matematice asteptate pentru adunare,
inmultire, scadere si negatie.

Proprietatile pentru `Nothing` verifica partea partiala a evaluatorului:
daca lipsesc variabile din mediu, evaluarea trebuie sa esueze explicit si
controlat, nu prin exceptii.

## Cerinte

- GHC 9.6.7 sau o versiune compatibila cu `base >= 4.14 && < 5`
- Cabal 3.14+ sau o versiune compatibila
- QuickCheck `>= 2.14 && < 3`, instalat automat de Cabal pentru test-suite

### Instalare cu GHCup pe Windows

Daca nu ai GHC si Cabal instalate, poti folosi GHCup:

```bash
ghcup install ghc recommended
ghcup set ghc recommended
ghcup install cabal recommended
ghcup set cabal recommended
```

Dupa instalare, `ghc.exe` si `cabal.exe` ar trebui sa fie disponibile in PATH.

## Comenzi utile

Toate comenzile se ruleaza din radacina proiectului:

```text
d:\MFIS_Project
```

### Actualizarea indexului de pachete

```bash
cabal update
```

### Build

```bash
cabal build
```

### Rulare demo

```bash
cabal run mfis-quickcheck-expr
```

Aplicatia ruleaza expresiile demo din `app/Main.hs`, afisand pentru fiecare:

- expresia originala;
- expresia simplificata;
- dimensiunea inainte si dupa simplificare;
- adancimea inainte si dupa simplificare;
- variabilele libere;
- mediul de evaluare, daca exista;
- valoarea expresiei initiale si a celei simplificate.

### Rulare cu o expresie proprie

```bash
cabal run mfis-quickcheck-expr -- "x + 1" x=5
```

Alt exemplu:

```bash
cabal run mfis-quickcheck-expr -- "1 * x + -(-y)" x=4 y=7
```

### Rulare teste

```bash
cabal test
```

### Rulare teste cu output direct

```bash
cabal test spec --test-show-details=direct
```

## Exemplu de output QuickCheck

Procentele raportate de `classify` pot varia intre rulari, deoarece exemplele
sunt generate aleatoriu.

```text
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

... toate cele 19 proprietati trebuie sa treaca ...
```

## Configurare Cabal

Fisierul `mfis-quickcheck-expr.cabal` declara trei componente:

```text
library
  modulele din src/: Expr, Eval, Pretty, Parser, Simplify

executable mfis-quickcheck-expr
  aplicatia demo din app/Main.hs

test-suite spec
  testele QuickCheck din test/Spec.hs
```

Dependinte principale:

- `base`
- `containers`
- `QuickCheck`, doar pentru test-suite

Proiectul foloseste si optiuni de warning precum `-Wall`, `-Wcompat` si
`-Wincomplete-uni-patterns`, pentru a incuraja cod mai robust.

## Limitari

- Limbajul include doar expresii aritmetice cu `Int`.
- Nu exista impartire, comparatii, booleene sau functii.
- `parseExpr` intoarce `Maybe Expr`, deci nu ofera mesaje detaliate de eroare.
- `variablePool` este finit: `x, y, z, u, v, w, a, b, c`.
- Distributia constructorilor din generator este fixa si ar trebui recalibrata
  daca AST-ul este extins.
- QuickCheck este o metoda probabilistica: faptul ca testele trec nu reprezinta
  o demonstratie matematica completa, dar ofera incredere puternica in
  comportamentul general.

## Concluzie

Proiectul arata cum pot fi folosite metodele formale intr-un mod practic:
in loc sa verificam doar exemple punctuale, exprimam proprietati generale despre
program. QuickCheck genereaza automat cazuri de test, cauta contraexemple si le
reduce la forme mai simple prin shrinking.

Mini-limbajul aritmetic este potrivit pentru acest tip de testare deoarece are
legi clare: simplificarea trebuie sa pastreze semantica, parserul si
pretty-printerul trebuie sa fie compatibile, iar evaluatorul trebuie sa trateze
corect atat expresiile complete, cat si variabilele lipsa.

## Bibliografie

- Koen Claessen si John Hughes, "QuickCheck: A Lightweight Tool for Random
  Testing of Haskell Programs", ICFP 2000.
- Documentatia QuickCheck pe Hackage:
  <https://hackage.haskell.org/package/QuickCheck>
- Tutorial online QuickCheck:
  <https://sulzmann.github.io/ProgrammingParadigms/lec-haskell-testing.html>
