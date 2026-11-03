# noctalia-case-convert

A [Noctalia 5](https://github.com/noctalia-dev/noctalia-shell) launcher plugin
that converts text between naming conventions — camelCase, kebab-case,
snake_case, CONSTANT_CASE and 14 more — without leaving the launcher.

Inspired by the Raycast extension
[`erics118/change-case`](https://www.raycast.com/erics118/change-case).

```
/case parse http response      → convert what you typed
/case                          → convert the current selection, else the clipboard
/case >kebab                   → same input, but filter the conversion list
```

Enter copies the highlighted conversion to the clipboard.

## Conversions

Input `this is an example`:

| Category | Conversion | Result |
| --- | --- | --- |
| Programming | `camelCase` | `thisIsAnExample` |
| Programming | `PascalCase` | `ThisIsAnExample` |
| Programming | `kebab-case` | `this-is-an-example` |
| Programming | `snake_case` | `this_is_an_example` |
| Programming | `CONSTANT_CASE` | `THIS_IS_AN_EXAMPLE` |
| Programming | `dot.case` | `this.is.an.example` |
| Programming | `path/case` | `this/is/an/example` |
| Programming | `Pascal_Snake_Case` | `This_Is_An_Example` |
| Programming | `KEBAB-UPPER-CASE` | `THIS-IS-AN-EXAMPLE` |
| Programming | `Header-Case` | `This-Is-An-Example` |
| Text | `Title Case` | `This Is an Example` |
| Text | `Capital Case` | `This Is An Example` |
| Text | `Sentence case` | `This is an example` |
| Text | `no case` | `this is an example` |
| Text | `lower case` | `this is an example` |
| Text | `UPPER CASE` | `THIS IS AN EXAMPLE` |
| Fun | `sWAP cASE` | `THIS IS AN EXAMPLE` |
| Fun | `AlTeRnAtInG cAsE` | `ThIs Is An ExAmPlE` |

The launcher's category filter bar narrows the list to Programming, Text or Fun.

Two details worth knowing:

- **Title Case vs Capital Case.** Title Case lowercases small words (`a`, `of`,
  `the`, …) unless they are first or last; Capital Case capitalizes every word.
- **Word-based vs character-based.** The word-based conversions rebuild the text
  from its words. Programming conversions drop punctuation between words; Text
  conversions keep prose punctuation and decimals (`hello, version 2.5`) but
  still split identifiers (`dot.case` → `Dot Case`). `lower case`,
  `UPPER CASE`, `sWAP cASE` and `AlTeRnAtInG cAsE` transform the input character
  by character and keep punctuation intact.

## Settings

| Setting | Default | Effect |
| --- | --- | --- |
| Input source | Selection, then clipboard | Where text comes from with an empty query |
| Preserve casing | on | Keep casing inside words, so `NASA rocks` → `NASA_Rocks` instead of `Nasa_Rocks` |
| Notify on copy | on | Show a notification after copying |

## Install

The primary selection is read with `wl-paste` from
[wl-clipboard](https://github.com/bugaevc/wl-clipboard); everything else needs
nothing beyond noctalia.

Clone anywhere, then register the clone as a plugin source:

```sh
git clone https://github.com/kjvdven/noctalia-case-convert.git
noctalia msg plugins source add local path "$PWD/noctalia-case-convert"
noctalia msg plugins enable kjvdven/case-convert
```

Going through `noctalia msg` rather than editing `settings.toml` by hand matters:
the moment the config declares a `[[plugins.source]]` of its own, noctalia stops
seeding the default `official` and `community` sources, and hand-editing is an
easy way to lose the plugins you already had.

The launcher trigger is the provider prefix plus `case` (so `/case` by default).
To change just this provider's prefix:

```toml
[shell.launcher.providers."kjvdven/case-convert:case"]
prefix = "cc"
```

## Development

The conversion logic in `case-convert/cases.luau` touches no noctalia API, so it
runs and tests standalone:

```sh
nix run nixpkgs#luau -- tests/cases_test.luau   # 63 checks
noctalia plugins lint case-convert              # manifest + settings cross-check
```

`case.luau` is file-watched by the shell: save it and the plugin hot-reloads.

For editor completion, drop a local copy of the API type definitions next to
`.luaurc` (gitignored, since the upstream repo ships no license):

```sh
git --git-dir=~/.local/state/noctalia/plugins/sources/official/repo/.git \
    show HEAD:noctalia.d.luau > noctalia.d.luau
```

### Unicode

Casing covers ASCII and the Latin-1 Supplement block, so `café` → `CAFÉ` and
`ÉÉN` → `één`. Letters beyond that block (`Ł`, `Ż`, `Ș`, Greek, Cyrillic) pass
through uncased rather than corrupted; `ß` stays `ß`, having no single-character
uppercase. The tokenizer splits only on an explicit separator set — never on
"not a letter" — so no multi-byte character is ever cut in half, and the byte
walk cannot throw on the invalid UTF-8 a raw selection may contain.

## License

MIT
