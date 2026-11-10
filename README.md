# Capabilities in Haskell

[![build](https://github.com/sawady/haskell-capabilities/actions/workflows/build.yml/badge.svg)](https://github.com/sawady/haskell-capabilities/actions/workflows/build.yml)
[![Sponsor](https://img.shields.io/github/sponsors/sawady?label=Sponsor&logo=GitHub)](https://github.com/sponsors/sawady)

Four ways of stating, in the type of a Haskell program, which resources it may use:

- types only,
- type classes in the *tagless final* style,
- monad transformers,
- effect systems with rows.

All the examples solve the same problem: download a page and print its first line.
The network is simulated.

**Read the guide:** https://sawady.github.io/haskell-capabilities/ explains the four styles and
compares them, with the code and the GHC errors from this repository.

This is supporting material for the doctoral plan «Restringir antes que validar» ("Restrict before
validating", Universidad Nacional de Quilmes, UNQ). The thesis needs a program's capabilities
(network, files, console) to be in its type, so that an oracle can reject whatever was not granted
while a language model writes the code.

The project was originally written in Spanish, as `capacidades-haskell`; that version is kept
at the tag [`v-es`](https://github.com/sawady/haskell-capabilities/tree/v-es) (commit `4d808dd`).

## How to run it

```
./build.sh
```

It needs GHC. It only uses `base`, `mtl` and `transformers`, which ship with GHC, so `cabal` is not
needed. The script:

- builds and runs each example in `src/`;
- checks that the ones in `must-fail/` do **not** compile;
- records the GHCi sessions of [Exploring in GHCi](#exploring-in-ghci);
- saves to `outputs/` everything that is shown, including GHC's error messages.

The examples run with a fixed environment (only `LANG` and `PATH`), so that the outputs do not
change from one machine to another. The script exits with the number of failures: 0 if everything
went as expected.

The reference version is GHC 9.12.2, installed with GHCup: `outputs/` and the page were generated
with it. To try another version:

```
GHC=ghc-9.6.7 ./build.sh
```

CI (`.github/workflows/build.yml`) runs the script with GHC 9.6.7, 9.8.4, 9.10.3, 9.12.2 and, as
experimental, 9.14.1. With the reference version it compares `outputs/` and the page exactly
against what is in the repository. With the others, GHC's error messages only differ in blank
lines, so the comparison ignores them. GHC 9.14.1 compiles everything and rejects what it should,
but when showing B's inferred types it expands the synonyms (`[Char]` instead of `Url` and
`FilePath`), so its comparison fails without breaking CI.

## The examples

| File | What it shows | Language |
|:--|:--|:--|
| `src/A_TypesOnly.hs` | With `IO` the type does not say what is used. Records of functions name the capabilities, and over an abstract monad they also enforce them. | Haskell 2010 |
| `src/B_TaglessFinal.hs` | Capabilities as single-parameter classes (from `src/Capabilities.hs`). GHC **infers** which capabilities each function uses. Two interpreters: IO and a pure one for testing. | Haskell 2010 |
| `src/C1_Transformers.hs` | A concrete `transformers` stack, with `lift` by hand. | Haskell 2010 |
| `src/C2_Mtl.hs` | mtl style: the same stack behind classes. A capability of our own that goes through the stack. | Haskell 2010 + `FlexibleContexts` |
| `src/D_EffectRows.hs` and `src/Effects.hs` | A hand-made effect system with rows, in about 120 lines: the row is a type-level list. | Haskell 2010 + 7 extensions |
| `must-fail/B_CapabilityNotGranted.hs` | The signature grants network and console, and the body reads a file. | Haskell 2010 |
| `must-fail/B_DirectIO.hs` | With the abstract monad, not even IO can be used directly. | Haskell 2010 |
| `must-fail/B_InterpreterLacksCapability.hs` | The program asks for files and the interpreter does not grant them. | Haskell 2010 |
| `must-fail/D_EffectNotInRow.hs` | The row only has network, and the body prints. | with extensions |

## Reading order

Read the examples in the order of the guide, A to D. Each part builds on the previous ones and
needs, in addition, what the last column lists.

| Part | Files, in order | You need to know |
|:--|:--|:--|
| A. Types only | `src/A_TypesOnly.hs` (it uses `Url` and `firstLine` from `src/Capabilities.hs`) | `IO` and `do` notation, records, a constraint such as `Monad m =>` |
| B. Tagless final | `src/Capabilities.hs`, `src/B_TaglessFinal.hs`, then the three `must-fail/B_*.hs` with their errors in `outputs/` | Type classes and instances; `Functor`, `Applicative` and `Monad` instances for a `newtype`; the `State` monad |
| C. Transformers | `src/C1_Transformers.hs`, then `src/C2_Mtl.hs` | `ReaderT`, `StateT` and `lift` from `transformers`; for C2, the classes of `mtl` (`MonadReader`, `MonadState`) |
| D. Effect rows | `src/D_EffectRows.hs` (the program), then `src/Effects.hs` (the mechanism), then `must-fail/D_EffectNotInRow.hs` | GADTs, `DataKinds` (type-level lists), multi-parameter classes and overlapping instances |

Where to learn them:

- Type classes, `Functor`, `Applicative`, `Monad` and monad transformers: the
  [Typeclassopedia](https://wiki.haskell.org/Typeclassopedia), and the documentation of
  [`transformers`](https://hackage.haskell.org/package/transformers) and
  [`mtl`](https://hackage.haskell.org/package/mtl).
- The extensions of D, in the GHC User's Guide:
  [GADTs](https://downloads.haskell.org/ghc/9.12.2/docs/users_guide/exts/gadt.html),
  [`DataKinds`](https://downloads.haskell.org/ghc/9.12.2/docs/users_guide/exts/data_kinds.html),
  [multi-parameter classes](https://downloads.haskell.org/ghc/9.12.2/docs/users_guide/exts/multi_param_type_classes.html)
  and [overlapping instances](https://downloads.haskell.org/ghc/9.12.2/docs/users_guide/exts/instances.html#overlapping-instances).

## Exploring in GHCi

The most interesting part of B and D is what GHC infers, and GHCi lets you ask it directly. From
the root of the repository:

```
ghci -isrc src/B_TaglessFinal.hs
```

`:t` shows the type GHC infers, `:info` a class and its instances, and `:reload` (`:r`) loads the
files again after editing them. Functions can also be written at the prompt, and GHC infers their
capabilities just as it does in the file. With GHC 9.12.2 (`[safe]` is a Safe Haskell annotation
and can be ignored here):

```
ghci> :info Files
type Files :: (* -> *) -> Constraint
class Monad m => Files m where
  readTextFile :: FilePath -> m String
  {-# MINIMAL readTextFile #-}
  	-- Defined at src/Capabilities.hs:23:1
instance [safe] Files Test
  -- Defined at src/B_TaglessFinal.hs:71:10
ghci> runState (runTest (summary "https://example.org")) []
((),["test page for https://example.org"])
ghci> let quiet url = do { page <- httpGet url; return (firstLine page) }
ghci> :t quiet
quiet :: Net m => Url -> m String
ghci> let both url path = do { page <- httpGet url; note <- readTextFile path; printLine (page ++ note) }
ghci> :t both
both :: (Net m, Files m, Console m) => Url -> FilePath -> m ()
```

Only `Test` grants `Files`, so `runApp (both "https://example.org" "note.txt")` is rejected with
`No instance for ‘Files App’`. `quiet` does not print, and `Console` disappears from its type.

In D, `ghci -isrc src/D_EffectRows.hs` shows how each handler removes one effect from the row:

```
ghci> :t summary
summary :: (Member Net es, Member Console es) => Url -> Eff es ()
ghci> :t handleNet fakePages (summary "https://example.org")
handleNet fakePages (summary "https://example.org")
  :: Member Console es => Eff es ()
ghci> :t handleConsolePure (handleNet fakePages (summary "https://example.org"))
handleConsolePure (handleNet fakePages (summary "https://example.org"))
  :: Eff es ((), [String])
ghci> run (handleConsolePure (handleNet fakePages (summary "https://example.org")))
((),["<title of https://example.org>"])
```

Things to try: write at the prompt a function that also reads a file, and look at its type; in
the file, give `summary` a signature with fewer capabilities than it uses, and `:r`; in D, apply
the handlers in the other order. `build.sh` regenerates these sessions in `outputs/ghci-B.txt` and
`outputs/ghci-D.txt`.

## Which extensions are needed, and why

| Style | Extensions | Why |
|:--|:--|:--|
| Tagless final with single-parameter classes | none | `class Monad m => Net m` is Haskell 2010 |
| Transformers (`transformers`) | none | Stacks are ordinary types |
| mtl style | `FlexibleContexts` in the code that uses it | `MonadReader Config m` mentions a concrete type. The library, in addition, uses `MultiParamTypeClasses` and `FunctionalDependencies` |
| Effect rows | `DataKinds`, `GADTs`, `KindSignatures`, `TypeOperators`, `MultiParamTypeClasses`, `FlexibleInstances`, `FlexibleContexts`, `EmptyCase` | The row is a list of types. Effects are GADTs. Row membership is a two-parameter class with overlapping instances |

A clarification about "Haskell 2010": the 2010 report does not have `Applicative` as a superclass
of `Monad`, and GHC does. The examples write that instance, as current GHC requires.

## The explanatory page

The guide is published at https://sawady.github.io/haskell-capabilities/. Its source is
`site/index.html`, a single HTML file with no scripts and no external dependencies. It is not
edited by hand: it is generated from `site/template.html` with

```
./build.sh && python3 site/build.py
```

The generator inserts into the template the fragments of `src/`, `must-fail/` and `outputs/`, and
highlights the Haskell code, so the code and the errors on the page are always the ones the script
compiles. `.github/workflows/pages.yml` publishes it to GitHub Pages.

## Contributing

Issues are welcome: see [`CONTRIBUTING.md`](CONTRIBUTING.md). Changes are listed in
[`CHANGELOG.md`](CHANGELOG.md).

## Sponsoring

This project is free software. If it is useful to you, you can support its development through
[GitHub Sponsors](https://github.com/sponsors/sawady).

## License

- The code (`src/`, `must-fail/`, `build.sh`, `site/build.py` and the CI workflows) is under the
  BSD 3-Clause license: see [`LICENSE`](LICENSE).
- The text (this README and the explanatory page, `site/template.html` and `site/index.html`) is
  under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/): see
  [`LICENSE-docs`](LICENSE-docs). Code fragments that appear in the text remain under BSD 3-Clause.
