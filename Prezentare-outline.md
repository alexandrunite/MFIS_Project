# Prezentare: Testarea property-based a modulelor software folosind QuickCheck

## Slide 1. Titlu si tema

- Metode Formale in Ingineria Software
- QuickCheck si testarea property-based
- Mini-limbaj de expresii aritmetice in Haskell

## Slide 2. Context: metode formale

- ce inseamna specificare formala
- de ce proprietatile sunt importante
- diferenta dintre exemple si invarianti

## Slide 3. Haskell si QuickCheck

- tipuri de date algebrice
- pattern matching si recursivitate
- functii pure
- `Arbitrary` si `shrink`

## Slide 4. Modulul implementat

- AST pentru expresii
- evaluator sigur cu mediu `Map String Int`
- simplifier / optimizer
- pretty printer
- parser simplu

## Slide 5. Proprietatile testate

- simplificarea pastreaza semantica
- simplificarea este idempotenta
- adunarea si inmultirea sunt comutative
- neutre si absorbante
- negatie dubla si scaderea unui termen cu el insusi

## Slide 6. Generarea automata a testelor

- generator controlat pe marime
- expresii recursive finite
- medii de evaluare pentru variabile
- shrink pentru contraexemple mici

## Slide 7. Exemplu de rulare

- output QuickCheck de succes
- exemplu de contraexemplu
- cum ajuta shrink la debug

## Slide 8. Rezultate si observatii

- proprietatile acopera atat semantica, cat si structura
- parserul si pretty printerul sunt consistente
- simplificarea reduce complexitatea expresiei

## Slide 9. Limitari

- medii complete necesare pentru proprietatile semantice
- parserul este simplu, nu industrial
- QuickCheck nu inlocuieste demonstratia matematica

## Slide 10. Concluzii si extensii

- abordare buna pentru cursuri de metode formale
- proiect usor de inteles si de prezentat
- extensii posibile: booleani, variabile avansate, parser mai serios
