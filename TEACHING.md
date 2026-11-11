# Teaching guide

A short guide for using this material in a course: what students should be able to do after
each part, how long each part takes, and how to use the exercises in class. The material itself
is the [guide](https://sawady.github.io/haskell-capabilities/), the code in `src/` and
`must-fail/`, and the [exercises](exercises/README.md).

The prerequisites of each part are in the [reading order](README.md#reading-order) of the README.

## Learning objectives

After the introduction and part A, students can:

- explain what *ambient authority* is, and why the type `IO ()` does not say which resources a
  function uses;
- write capabilities as records of functions, and explain why they only restrict the code when
  the monad is abstract.

After part B (tagless final), students can:

- write a capability as a single-parameter class, and an interpreter as a monad with instances
  for some capabilities;
- read in the type GHC infers which capabilities a function uses, in the source and in GHCi;
- read GHC's errors when a capability is not granted ("Could not deduce … from the context",
  "No instance for") and when the body uses `IO` directly ("rigid type variable").

After part C (transformers and the mtl style), students can:

- build a stack with `transformers` and put the `lift` each layer needs;
- explain why a stack with `IO` at the bottom does not remove ambient authority;
- recognize the mtl classes as tagless final with two-parameter classes, and explain why a
  capability of our own needs one instance per transformer.

After part D (effect rows), students can:

- explain the row as a type-level list, and a function polymorphic in the row with `Member`;
- follow how each handler removes one effect from the row, and why the order of the handlers
  matters;
- write a new effect and its handler.

At the end, students can compare the four styles with the criteria of the table
[The four, side by side](https://sawady.github.io/haskell-capabilities/#side-by-side).

## Duration

These are estimates for a group that already knows monads and type classes; they have not been
measured in a course. "Exposition" is reading the section of the guide with the code and the
errors, and trying things in GHCi.

| Part | Exposition | Exercises |
|:--|:--|:--|
| Introduction and A. Types only | 30 min | 1: 20 min |
| B. Tagless final, with GHCi and the errors | 60 min | 2: 20 min |
| C. Transformers and the mtl style | 60 min | 3: 20 min; 4: 30 min |
| D. Effect rows | 75 min | 5: 30 min |
| The four, side by side, and what suits the thesis | 20 min | 6: 60–90 min |

That fits three classes of about two hours: A and B in the first, C in the second, D and the
comparison in the third. Exercise 6 works as homework, or as a fourth session.

## The exercises in class

- **Check the setup first.** `./build.sh` on a fresh clone has to end with 0 failures. Any GHC from
  9.6 to 9.12 works; the outputs in `outputs/` were generated with 9.12.2. How to compile an attempt
  is at the top of [`exercises/README.md`](exercises/README.md).
- **Predicting before compiling.** Exercises 2, 3 and 5b ask for a prediction: the type GHC will
  infer, or the error it will give. They work well in class if each student writes the prediction
  down before compiling, and then compares it with what GHC says. The walk-through of the errors
  in the guide, in section 2, is a good reading before exercise 3.
- **In pairs, at the end of each class.** Exercises 1 and 2 close the first class: one adds the
  capability as a record and the other as a class, and they compare signatures and calls.
  Exercise 3 closes the second, and exercise 5 the third.
- **As a lab or homework.** Exercise 4 needs writing a whole base monad and its instances.
- **In groups, to close.** Exercise 6 can be split: each member of a group adds the clock in one
  style, and then the group lists which existing lines had to change in each one. The answers to
  compare with are in the comments of the solutions.
- **The solutions are in the repository**, in `exercises/solutions/`, and `build.sh` checks them.
  Students who want to try first should not look at them; to check their own attempt, they can
  compare what it prints with `outputs/solution-*.txt`.

## License

This guide is under [CC BY-SA 4.0](LICENSE-docs), like the rest of the text of the repository.
