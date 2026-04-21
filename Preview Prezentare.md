# Preview Prezentare (extins)

## Slide 1 — Titlu

**Metode Formale in Ingineria Software**  
Tema 20: **Testarea property-based folosind QuickCheck**  
Studiu de caz: mini-limbaj de expresii aritmetice in Haskell  
Echipa: [nume1], [nume2]

**Mesaj cheie:** prezentarea arata cum trecem de la teste punctuale la specificatii generale executabile.

---

## Slide 2 — Context: de ce avem nevoie de metode formale

In proiecte reale, codul poate parea corect pe exemplele alese manual, dar sa esueze pe cazuri limita.
Metodele formale ne ajuta sa formulam explicit ce inseamna corectitudinea:

- ce proprietati trebuie sa ramana adevarate pentru orice intrare;
- ce invarianti semantici trebuie respectati dupa transformari (de exemplu simplificare);
- ce garantii vrem asupra comportamentului parserului si evaluatorului.

In loc sa spunem "merge la mine", spunem: **"pentru orice expresie valida, proprietatea X este adevarata"**.

**Mesaj cheie:** formalizarea proprietatilor reduce ambiguitatea si creste increderea in modulul testat.

---

## Slide 3 — Testare clasica vs. property-based

**Testare clasica (example-based):**

```haskell
eval env (Add (Const 1) (Const 2)) == Just 3
eval env (Mul (Const 5) (Const 0)) == Just 0
```

Acest stil este util, dar acopera doar cazurile la care ne-am gandit in avans.

**Property-based testing:**

```text
Pentru orice expresii a, b si orice mediu complet env:
  eval env (Add a b) == eval env (Add b a)
```

Framework-ul genereaza automat multe exemple si cauta contraexemple.

**Mesaj cheie:** nu testam instanțe izolate, testam reguli generale.

---

## Slide 4 — Ce este QuickCheck (pe scurt)

QuickCheck este biblioteca Haskell pentru property-based testing.
Elementele folosite in proiect:

- `Arbitrary` — clasa tipurilor ce pot fi generate;
- `Gen a` — tipul generatorilor;
- `frequency` — control pe distributie (ponderi explicite);
- `sized` — control pe marime/adancime;
- `shrink` — minimizare automata a contraexemplului;
- `classify` — etichetare si analiza distributiei testelor;
- `quickCheckWith` — parametri custom (`maxSuccess`, `maxSize`).

**Mesaj cheie:** QuickCheck nu este doar random testing; este random testing controlat, cu feedback util pentru debug.

---

## Slide 5 — Arhitectura modulului testat

Componentele proiectului:

- `Expr.hs` — AST + functii structurale (`size`, `depth`, `operatorCount`, `freeVars`, `substitute`);
- `Eval.hs` — evaluare sigura: `eval :: Env -> Expr -> Maybe Int`;
- `Simplify.hs` — reguli algebrice aplicate pana la punct fix;
- `Pretty.hs` — serializare text cu precedenta corecta;
- `Parser.hs` — parsare text -> `Expr`;
- `test/Spec.hs` — generatoare + 16 proprietati QuickCheck.

Evaluarea intoarce `Nothing` cand o variabila lipseste din mediu.

**Mesaj cheie:** proiectul acopera intreg fluxul: sintaxa, semantica, transformare, serializare si verificare.

---

## Slide 6 — AST si exemplu de arbore

Sintaxa abstracta:

```haskell
data Expr
  = Const Int
  | Var String
  | Add Expr Expr
  | Sub Expr Expr
  | Mul Expr Expr
  | Neg Expr
```

Exemplu pentru `1 * x + -(-y)`:

```text
       Add
      /   \
    Mul    Neg
   /   \    \
  1     x   Neg
               \
                y
```

**Mesaj cheie:** modelarea cu tipuri algebrice face structura expresiilor explicita si usor de procesat recursiv.

---

## Slide 7 — Evaluatorul: semantica operationala

Fragment:

```haskell
eval :: Env -> Expr -> Maybe Int
eval env (Add a b) = liftA2 (+) (eval env a) (eval env b)
eval env (Var x)   = Map.lookup x env
```

Observatii:

- `Maybe` encodeaza explicit esecul partial (`Nothing`);
- operatiile binare reusesc doar daca ambele subexpresii sunt evaluabile;
- design-ul evita exceptii runtime pentru variabile nedefinite.

**Mesaj cheie:** semantica este total controlata si transparenta, inclusiv pentru cazurile incomplete.

---

## Slide 8 — Simplificatorul si regulile algebrice

Simplificarea aplica reguli pana la stabilizare (`fixpoint`). Exemple:

- `x + 0 -> x`
- `x * 1 -> x`
- `x * 0 -> 0`
- `x - x -> 0`
- `--x -> x`
- `0 - e -> -e`

Plus evaluare constanta locala:

- `Const a + Const b -> Const (a+b)`
- `Const a * Const b -> Const (a*b)` etc.

**Mesaj cheie:** simplificatorul este deterministic si conserva semantica pentru evaluari in medii complete.

---

## Slide 9 — Pretty + Parser: round-trip semantic

`Pretty.hs` foloseste prioritati (`addPrec`, `mulPrec`, `negPrec`) pentru paranteze corecte.
`Parser.hs` respecta precedenta operatorilor:

- `exprP` pentru `+` / `-`;
- `termP` pentru `*`;
- `factorP` pentru negare unara;
- suport pentru variabile, constante si paranteze.

Proprietatea validata:

```text
eval env (parse(pretty(expr))) == eval env expr
```

**Mesaj cheie:** forma textuala si forma interna raman consistente la nivel semantic.

---

## Slide 10 — De ce generatoare manuale (nu automate)

In proiect, generatoarele sunt definite manual pentru control pe distributie.
Un generator generic poate produce expresii neechilibrate sau prea adanci.

`genSmallInt` favorizeaza numere mici pentru lizibilitate:

```haskell
frequency
  [ (5, chooseInt (-4, 4))
  , (1, chooseInt (-12, 12))
  ]
```

**Mesaj cheie:** un test bun are nevoie de date bune, nu doar de date random.

---

## Slide 11 — `genExpr`, `genClosedExpr`, `genEnvFor`

`genExpr` controleaza marimea cu `sized` si distribuie constructorii:

- terminale (Const/Var) cu pondere mare, ca sa opreasca recursivitatea;
- `Neg` cu pondere mai mica;
- `Add`, `Sub`, `Mul` echilibrate.

`genClosedExpr` produce expresii fara variabile (utile pentru substitutie).

`genEnvFor` construieste automat medii complete pentru variabilele libere:

```haskell
let names = Set.toList (freeVars expr)
values <- vectorOf (length names) genSmallInt
pure (Map.fromList (zip names values))
```

**Mesaj cheie:** controlul generatorului + medii complete reduc fals-pozitivele si cresc relevanta testelor.

---

## Slide 12 — `shrink`: contraexemple mici, debug rapid

Cand o proprietate pica, QuickCheck simplifica intrarea pana la forma minima relevanta.

Exemplu pentru `Add`:

```haskell
shrinkExpr (Add a b) =
  [a, b]
  ++ [Add a' b | a' <- shrinkExpr a]
  ++ [Add a b' | b' <- shrinkExpr b]
```

Fara shrink: expresie mare si greu de citit.  
Cu shrink: contraexemplu scurt, usor de localizat in cod.

**Mesaj cheie:** shrink transforma un "test failed" intr-un indiciu concret de reparat.

---

## Slide 13 — Cele 16 proprietati (grupare completa)

1. **Corectitudine semantica:**
- simplificarea pastreaza semantica in medii complete;
- pretty + parse pastreaza semantica.

2. **Structurale:**
- idempotenta simplificarii;
- simplificarea nu creste `size`, `depth`, `operatorCount`.

3. **Algebrice:**
- comutativitate `+`, `*`;
- asociativitate `+`, `*`.

4. **Elemente speciale:**
- `e + 0 = e`, `e * 1 = e`, `e * 0 = 0`.

5. **Negatie/scadere:**
- `e - e = 0`, `--e = e`.

6. **Substitutie:**
- substitutia unei expresii inchise pastreaza semantica.

**Mesaj cheie:** proprietatile descriu comportamentul global al modulului, nu implementarea punctuala.

---

## Slide 14 — Rezultate experimentale (exemplu de output)

Setari de rulare:

```haskell
quickCheckWith stdArgs {maxSuccess = 120, maxSize = 12}
```

Exemple de output. Procentele pot varia intre rulari, deoarece QuickCheck genereaza date aleatorii:

```text
+++ OK, passed 120 tests:
62.5% cu variabile
37.5% fara variabile
30.0% expresie mare (>8 noduri)
```

```text
+++ OK, passed 120 tests:
57.5% expresii mari
17.5% expresii mici
```

`classify` confirma ca nu testam doar cazuri triviale.

**Mesaj cheie:** distributia testelor este monitorizata explicit, nu lasata la intamplare.

---

## Slide 15 — Avantaje si limitari

**Avantaje:**

- acoperire mult mai buna decat testarea manuala;
- descoperire rapida de cazuri limita;
- contraexemple minimale pentru debugging;
- proprietatile devin documentatie executabila.

**Limitari:**

- o proprietate gresit formulata poate trece mereu;
- calitatea depinde de generator;
- proprietatile semantice necesita medii complete cand expresiile contin variabile;
- QuickCheck completeaza, nu inlocuieste demonstratia formala.

**Mesaj cheie:** eficienta metodei depinde de calitatea specificatiilor si a generatorilor.

---

## Slide 16 — Concluzii si directii viitoare

Concluzii:

- abordarea property-based este foarte potrivita pentru un mini-limbaj formal;
- Haskell + QuickCheck ofera un ecosistem natural pentru verificare;
- diferenta fata de testarea clasica este schimbarea de perspectiva: de la exemple la invarianti.

Directii viitoare (optional):

- extinderea limbajului (impartire, comparatii, booleene);
- teste de performanta pentru simplificator;
- validari suplimentare pentru parser (input-uri malformate mai variate);
- integrare CI cu rulare automata a proprietatilor.

**Mesaj cheie final:** nu demonstram doar ca "merge"; demonstram ca respecta proprietati generale pentru o clasa larga de intrari.

---

## Slide 17 — Walkthrough demo din `app/Main.hs`

Acest slide arata traseul complet al expresiei demo din executabil:

- `demoExpr = Add (Mul (Const 1) (Var "x")) (Neg (Neg (Var "y")))`
- `demoEnv = Map.fromList [("x", 4), ("y", 7)]`

Output real obtinut din executabilul proiectului:

- expresie originala: `1 * x + -(-y)`
- `size = 7`, `depth = 4`, `operatorCount = 4`
- variabile libere: `["x","y"]`
- valoare evaluata: `Just 11`
- simplificata: `x + y`, valoare: `Just 11`
- `parse(pretty(expr))` pastreaza semantica (`True`)

**Mesaj cheie:** toate modulele se leaga corect intr-un scenariu concret de rulare.

---

## Slide 18 — `Expr.hs`: functii structurale in proprietati

Functiile structurale din `Expr.hs` sunt baza testelor structurale:

- `size` — numarul total de noduri;
- `depth` — adancimea maxima;
- `operatorCount` — cati operatori apar in arbore;
- `freeVars` — multimea variabilelor libere;
- `substitute` — inlocuire recursiva in AST.

Legatura directa cu QuickCheck:

- `prop_simplifyDoesNotIncreaseSize`
- `prop_simplifyDoesNotIncreaseDepth`
- `prop_simplifyDoesNotIncreaseOperators`

**Mesaj cheie:** masuram formal efectul simplificarii, nu doar il presupunem.

---

## Slide 19 — `Parser.hs`: gramatica efectiva

Parserul este construit cu `ReadP` si precedenta explicita:

- `exprP = chainl1 termP addOp` (nivel `+` / `-`)
- `termP = chainl1 factorP mulOp` (nivel `*`)
- `factorP = negP +++ atomP`
- `atomP = negConstP +++ parens exprP +++ integerP +++ variableP`

Detalii concrete:

- accepta spatii prin `token` / `skipSpaces`;
- variabile: litera + caractere alfanumerice/underscore;
- constante negative explicite: `(-3)`;
- `parseExpr` valideaza input complet cu `eof`.

**Mesaj cheie:** sintaxa si precedenta sunt codificate explicit in parser.

---

## Slide 20 — `Pretty.hs`: prioritati si paranteze

`Pretty` foloseste `prettyPrec` cu prioritati numerice:

- `atomPrec = 11`
- `negPrec = 9`
- `mulPrec = 7`
- `addPrec = 6`

Regula importanta:

```haskell
prettyConst n
  | n < 0 = "(" ++ show n ++ ")"
```

Constantele negative sunt parenthezate ca sa nu fie confundate cu scaderea binara.

**Mesaj cheie:** output-ul text este minim-parenthezat, dar semantic corect.

---

## Slide 21 — Infrastructura de rulare in `test/Spec.hs`

Proprietatile sunt rulate uniform prin:

```haskell
quickCheckWith stdArgs {maxSuccess = 120, maxSize = 12}
```

Avantajul acestei abordari:

- aceeasi configuratie pentru toate proprietatile;
- comparatii corecte intre rezultate;
- output consistent pentru prezentare si analiza.

In `main` sunt apelate cele 16 proprietati grupate logic (semantice, structurale, algebrice etc.).

**Mesaj cheie:** testarea este sistematica si reproductibila.

---

## Slide 22 — Exemplu de rezultate din `spec.exe`

Exemplu de output obtinut local. Procentele de mai jos sunt orientative si pot varia intre rulari:

- `Simplificarea pastreaza semantica in medii complete`: `68.3%` cu variabile, `31.7%` fara variabile
- `Pretty/Parse`: `28.3%` expresie terminala, `24.2%` adancime `> 4`
- `Adunarea comutativa`: `52.5%` expresii mari, `16.7%` expresii mici
- `0 absorbant la inmultire`: `68.3%` cu variabile, `31.7%` fara variabile
- toate cele 16 proprietati: `PASS`

**Mesaj cheie:** distributia cazurilor este vizibila si confirma acoperire buna.

---

## Slide 23 — Configurarea proiectului din `.cabal`

Fisierul `mfis-quickcheck-expr.cabal` defineste:

- `library` cu modulele: `Expr`, `Eval`, `Pretty`, `Parser`, `Simplify`
- `executable mfis-quickcheck-expr` (intrare: `app/Main.hs`)
- `test-suite spec` (intrare: `test/Spec.hs`)

Dependinte:

- `base`, `containers` (proiect)
- `QuickCheck >= 2.14 && < 3` (test-suite)

**Mesaj cheie:** structura declarativa din cabal face proiectul portabil si usor de rulat.

---

## Slide 24 — Limitari concrete ale implementarii actuale

Limitari strict din proiectul curent:

- limbajul are doar `Int` + `Add/Sub/Mul/Neg` (fara impartire/comparatii/booleene);
- `parseExpr :: String -> Maybe Expr` nu furnizeaza erori detaliate;
- `variablePool` este finit (9 identificatori predefiniti);
- distributia `frequency` este fixa si necesita recalibrare la extinderea AST-ului;
- property-based testing nu inlocuieste o demonstratie formala completa.

**Mesaj cheie:** limitarile sunt cunoscute si ofera o foaie de parcurs clara pentru versiuni viitoare.
