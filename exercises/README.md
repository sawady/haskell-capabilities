# Exercises

Five exercises, from part A to part D of the [guide](https://sawady.github.io/haskell-capabilities/),
from easier to harder. Each one starts from an example in `src/` and asks for a small change.

| | Part | What it practices |
|:--|:--|:--|
| 1 | A. Types only | Adding a capability as a record of functions |
| 2 | B. Tagless final | Adding a capability as a class, and predicting the type GHC infers |
| 3 | C. Transformers | Predicting GHC's errors with transformers and in the mtl style |
| 4 | C. Transformers | Running the same mtl-style program without IO |
| 5 | D. Effect rows | The row at each step of the handlers, and what happens when one is missing |

Try them before looking at the solutions, in [`solutions/`](solutions/). `build.sh` and CI check
them like the examples: the ones in `solutions/` compile and run, and the ones in
`solutions/must-fail/` are rejected with the error they declare. What they print, and GHC's
errors, are in `outputs/solution-*.txt`. The answers to the questions are in the comments of the
solutions.

To compile an attempt, from the root of the repository (`-isrc` finds `Capabilities` and
`Effects`):

```
mkdir -p build/exercises
ghc -isrc -outputdir build/exercises -o build/exercises/attempt attempt.hs && build/exercises/attempt
ghci -isrc attempt.hs
```

The examples in `src/` are programs (`module Main`) and cannot be imported: start each exercise
from a copy.

## 1. A Files capability as a record (part A)

Start from part 3 of `src/A_TypesOnly.hs`, records of functions over an abstract monad.

- Add a record `Files m` with a function `readTextFile :: FilePath -> m String`.
- Write `summaryWithFile`, which downloads a page, reads a file and prints the first line of the
  page followed by the contents of the file. Its type must not mention `IO`.
- Run it twice: with records over `IO`, and with records over `State [String]`, where the console
  collects the lines in a list. The network and the file can be simulated in both.

Question: what changed in the signature and in each call? What would have changed in B, where
the capabilities are constraints?

Solution: [`solutions/E1_RecordsWithFiles.hs`](solutions/E1_RecordsWithFiles.hs).

## 2. A new capability in tagless final (part B)

Start from a copy of `src/B_TaglessFinal.hs`.

- Add a capability `Clock`: a single-parameter class with `now :: m Int`, the seconds since some
  instant.
- Write, without a signature, `stampedSummary url`, which prints the first line of the page
  preceded by the time.
- Before loading it, write down the type you expect GHC to infer. Then check it in GHCi with
  `:t stampedSummary` (see [Exploring in GHCi](../README.md#exploring-in-ghci)).
- Make it run with the pure interpreter `Test`, with a clock that always says 42.

Question: which of the existing functions and instances had to change? Can `App` run
`stampedSummary`?

Solution: [`solutions/E2_Clock.hs`](solutions/E2_Clock.hs). The type GHC infers is in
`outputs/solution-E2_Clock-ghci.txt`.

## 3. Predict the error (part C)

For each change, write down what you expect GHC to say, on which line and about which types,
before compiling it:

- a. In `src/C1_Transformers.hs`, remove one of the two `lift` from the line that prints, so that
  it reads `lift (putStrLn ...)`.
- b. In `src/C2_Mtl.hs`, remove `MonadState Int m` from the signature of `summary`.

Then compare with what GHC says. In (b), why does the message mention `Integer` and not `Int`?

Solutions: [`solutions/must-fail/E3_OneLiftTooFew.hs`](solutions/must-fail/E3_OneLiftTooFew.hs)
and [`solutions/must-fail/E3_StateNotGranted.hs`](solutions/must-fail/E3_StateNotGranted.hs).
GHC's messages are in `outputs/solution-must-fail-E3_*.txt`.

## 4. A pure interpreter for the mtl style (part C)

In `src/C2_Mtl.hs` the program runs over `Base`, which wraps `IO`.

- Write a base monad without `IO`, `Fake`, whose `Net` instance answers with a fixed text and
  records each requested URL in a list.
- Run C2's `summary`, without changing it, on `ReaderT Config (StateT Int Fake)`, and print the
  requested URLs.

Question: could you do the same with the `summary` of `src/C1_Transformers.hs` without changing
it? Why?

Solution: [`solutions/E4_PureMtl.hs`](solutions/E4_PureMtl.hs).

## 5. The order of the handlers (part D)

Start from a copy of `src/D_EffectRows.hs`.

- a. Apply the handlers in the other order: first `handleConsolePure`, then `handleNet`. Give each
  step a signature with its row, starting with `Eff '[Console, Net] ()` (the `'[...]` syntax
  needs `DataKinds`), and let GHC check them.
- b. Predict the error: run the program with `run` after handling only `Net`.

Solutions: [`solutions/E5_HandlerOrder.hs`](solutions/E5_HandlerOrder.hs) and
[`solutions/must-fail/E5_HandlerMissing.hs`](solutions/must-fail/E5_HandlerMissing.hs).
