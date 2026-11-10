# Contributing

Thanks for your interest! This is teaching material: it matters as much that the code compiles as
that it is easy to follow.

## Issues

GitHub issues are welcome: bugs, an example or explanation that is hard to follow, differences
with another GHC version, ideas for other capability styles. For larger changes, please open an
issue first so we can agree on the approach.

## Running and testing

You need GHC (for example through [GHCup](https://www.haskell.org/ghcup/)); `cabal` is not needed.

```
./build.sh                  # build and run src/, check must-fail/, regenerate outputs/
GHC=ghc-9.6.7 ./build.sh    # the same with another GHC version
python3 site/build.py       # regenerate the page from site/template.html
```

That is the test: the script must end with 0 failures (the examples in `src/` compile and run, the
ones in `must-fail/` are rejected with the error they expect, and the same goes for the solutions
in `exercises/solutions/` and `exercises/solutions/must-fail/`), and `git diff outputs/` must show
only the changes you expected. CI does the same with GHC 9.6 to 9.14.

A new example in `must-fail/` (or a new solution in `exercises/solutions/must-fail/`) needs a line `-- Expected error: [GHC-NNNNN]` with the code of the
error GHC has to reject it with (GHC's error codes are stable since 9.6, and listed in the
[Haskell Error Index](https://errors.haskell.org/)). The example only counts as failing as
expected if every error GHC reports has that code.

`outputs/` and `site/index.html` are generated with the reference version, GHC 9.12.2. If you
change an example, commit the regenerated outputs and page too; if you do not have that version,
say so in the PR.

## Style

- Haskell 2010 whenever possible. Every file declares its extensions with `LANGUAGE`; if an
  example needs a new one, explain why in a comment and in the README table.
- Only `base`, `mtl` and `transformers`, which ship with GHC.
- Names, comments and documentation in English.
- The page (`site/index.html`) is never edited by hand: change the template or the code.

## License

By contributing you agree that code is published under the [BSD 3-Clause license](LICENSE) and
text under [CC BY-SA 4.0](LICENSE-docs), like the rest of the repository.
