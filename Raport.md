# Raport: Testarea property-based a modulelor software folosind QuickCheck

## 1. Introducere

Acest proiect trateaza tema testarii property-based in Haskell folosind QuickCheck, pe un mini-limbaj de expresii aritmetice. Alegerea unui limbaj mic, dar formal, este naturala pentru Metode Formale in Ingineria Software: sintaxa este clara, semantica poate fi definita precis, iar proprietatile matematice pot fi formulate direct ca teste automate.

Scopul proiectului nu este doar sa demonstreze cateva functii Haskell, ci sa arate cum un modul software poate fi validat prin proprietati, nu doar prin exemple individuale.

## 2. Ce sunt metodele formale

Metodele formale folosesc notatii si tehnici matematice pentru a descrie, analiza si verifica programe sau sisteme.

In loc sa spunem doar "programul pare sa functioneze", formulam:

- ce inseamna corectitudinea
- ce invarianti trebuie sa ramana valabili
- ce proprietati trebuie sa fie adevarate pentru toate intrarile relevante

In acest proiect, expresiile aritmetice sunt descrise printr-un tip de date algebric, iar comportamentul lor este verificat prin proprietati formale precum:

- simplificarea pastreaza semantica
- adunarea este comutativa la evaluare
- inmultirea cu 0 este absorbanta

Aceasta abordare este foarte apropiata de stilul formal din cursurile de Haskell si metode formale.

## 3. Ce este property-based testing

Testarea clasica porneste de la cateva exemple alese manual. De exemplu:

- `1 + 2 = 3`
- `x * 1 = x`

Aceste teste sunt utile, dar acopera doar un numar mic de cazuri.

Property-based testing porneste de la o proprietate generala si lasa framework-ul de testare sa genereze automat multe cazuri de test. In loc de "testez 5 exemple", spunem:

- pentru orice expresie si orice mediu complet de evaluare, simplificarea nu schimba valoarea expresiei
- pentru orice expresii `a` si `b`, `a + b` are aceeasi valoare ca `b + a`

Avantajul principal este acoperirea mai buna a spatiului de intrare si descoperirea unor cazuri limita la care un dezvoltator nu s-ar gandi usor.

## 4. Ce este QuickCheck

QuickCheck este o biblioteca Haskell pentru testare property-based. Ea ofera:

- generatoare automate pentru valori de test
- posibilitatea de a defini generatoare proprii prin `Arbitrary`
- mecanism de reducere a contraexemplelor prin `shrink`
- afisarea unui contraexemplu minimal sau aproape minimal cand o proprietate esueaza

In acest proiect, QuickCheck este folosit pentru:

- generarea expresiilor aritmetice
- generarea mediilor de evaluare
- verificarea proprietatilor semanticii, simplificarii si parserului

## 5. De ce Haskell este potrivit pentru aceasta abordare

Haskell este foarte potrivit pentru metode formale si testare property-based din mai multe motive:

- tipurile de date algebrice modeleaza natural structuri sintactice
- pattern matching face definirea evaluatorului si a simplificatorului foarte clara
- functiile pure au comportament determinist, deci sunt usor de testat
- recursivitatea se potriveste perfect cu arbori de expresii
- limbajul incurajeaza specificarea clara a invariatilor

In plus, Haskell are o integrare naturala cu QuickCheck, ceea ce face foarte simpla trecerea de la specificatie la test automat.

## 6. Descrierea modulului implementat

Proiectul implementeaza un mini-limbaj de expresii aritmetice cu urmatoarele constructii:

- constante intregi
- variabile
- adunare
- scadere
- inmultire
- negatie unara

Modulele principale sunt:

- `Expr`: defineste AST-ul si functii auxiliare precum `size`, `depth`, `operatorCount`, `freeVars`, `substitute`
- `Eval`: defineste evaluarea sigura `eval :: Env -> Expr -> Maybe Int`
- `Simplify`: aplica reguli algebrice si normalizeaza expresiile
- `Pretty`: transforma expresiile in text lizibil
- `Parser`: transforma textul inapoi in expresii
- `test/Spec.hs`: defineste generatoarele si proprietatile QuickCheck

Decizia de a folosi `Maybe` pentru evaluare este justificata de prezenta variabilelor: daca un nume nu exista in mediu, evaluarea esueaza in mod controlat cu `Nothing`.

## 7. Proprietatile formale definite

Au fost implementate mai multe proprietati, grupate logic:

### Corectitudine semantica

- `prop_simplifyPreservesMeaning`
- `prop_prettyParsePreservesMeaning`

### Proprietati structurale

- `prop_simplifyIdempotent`
- `prop_simplifyDoesNotIncreaseSize`
- `prop_simplifyDoesNotIncreaseDepth`
- `prop_simplifyDoesNotIncreaseOperators`

### Proprietati algebrice

- `prop_addCommutative`
- `prop_mulCommutative`
- `prop_addAssociative`
- `prop_mulAssociative`

### Elemente neutre si absorbante

- `prop_addZeroIdentity`
- `prop_mulOneIdentity`
- `prop_mulZeroAbsorbing`

### Negatie si scadere

- `prop_subSelfZero`
- `prop_doubleNegation`

### Substitutie

- `prop_substituteClosedPreservesMeaning`

Aceste proprietati acopera atat partea semantica, cat si partea structurala a modulului.

## 8. Experiment practic

Experimentul practic consta in rularea testelor QuickCheck pe expresii generate automat. Pentru fiecare proprietate:

- QuickCheck genereaza expresii aleatoare, controlate pe marime
- pentru expresiile cu variabile, se construieste un mediu de evaluare care contine toate variabilele libere
- se verifica proprietatea formulata
- daca apare o eroare, QuickCheck incearca sa reduca contraexemplul

Expresiile sunt generate in mod controlat pentru a evita arborii foarte mari sau degenerati. Generatorul foloseste:

- cazuri terminale: constante si variabile
- cazuri recursive: `Add`, `Sub`, `Mul`, `Neg`

Prin `shrink`, contraexemplele devin mai mici si mai usor de analizat.

## 9. Rezultate obtinute

Pentru o implementare corecta, proprietatile ar trebui sa treaca, iar QuickCheck ar afisa mesaje de forma:

```text
+++ OK, passed 120 tests.
```

Cand o proprietate esueaza, QuickCheck raporteaza un contraexemplu. De exemplu, pentru o regula gresita de simplificare, un output posibil ar putea arata astfel:

```text
*** Failed! Falsifiable (after 7 tests and 15 shrinks):
Add (Var "x") (Const 0)
with environment fromList [("x",2)]
```

Acesta este avantajul major al `shrink`: in loc sa primim o expresie foarte mare si greu de citit, obtinem un caz mic, aproape minim, mult mai usor de debug-at.

In proiectul actual, proprietatile sunt construite astfel incat sa descrie corect comportamentul implementarii, iar mediile generate acopera toate variabilele libere din expresie.

## 10. Avantaje si limitari ale abordarii

### Avantaje

- testeaza multe cazuri automat, nu doar exemple manuale
- gaseste rapid erori de logica in simplificare sau parsare
- contraexemplele sunt reduse automat
- proprietatile servesc si ca documentatie executabila
- stilul Haskell face specificatia si implementarea foarte apropiate

### Limitari

- proprietatile trebuie formulate cu grija
- un generator prost poate produce cazuri prea simple sau prea mari
- `Maybe` introduce evaluari partiale, deci proprietatile semantice trebuie rulate pe medii complete
- QuickCheck nu inlocuieste demonstratia matematica formala, ci o completeaza

## 11. Concluzii

Proiectul demonstreaza ca Haskell si QuickCheck se potrivesc foarte bine pentru Metode Formale in Ingineria Software. Un mini-limbaj de expresii aritmetice este suficient de simplu pentru a fi inteles rapid, dar suficient de bogat pentru a ilustra:

- definire de AST
- evaluare
- simplificare
- pretty printing
- parsare
- verificare prin proprietati

Din perspectiva pedagogica, proiectul arata clar diferenta dintre testele clasice si property-based testing: nu verificam doar cateva exemple, ci specificam comportamentul general al modulului.

## 12. Cum poate fi extins proiectul

- adaugarea expresiilor booleene si a comparatiilor
- introducerea unor medii mai complexe pentru variabile
- extinderea simplificatorului cu mai multe reguli algebrice
- compararea a doua interpretoare independente pentru acelasi limbaj
- inlocuirea parserului simplu cu unul mai serios, de exemplu Megaparsec
