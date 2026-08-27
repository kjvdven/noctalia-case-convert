# Change Case

Convert text between naming conventions from the launcher.

```
/case parse http response      convert what you typed
/case                          convert the current selection, else the clipboard
/case >kebab                   same input, filtered by conversion name
```

Enter copies the highlighted conversion. 18 conversions across three
categories — Programming (`camelCase`, `PascalCase`, `kebab-case`, `snake_case`,
`CONSTANT_CASE`, `dot.case`, `path/case`, `Pascal_Snake_Case`,
`KEBAB-UPPER-CASE`, `Header-Case`), Text (`Title Case`, `Capital Case`,
`Sentence case`, `no case`, `lower case`, `UPPER CASE`) and Fun (`sWAP cASE`,
`AlTeRnAtInG cAsE`) — filterable with the launcher's category bar.

Reading the primary selection needs `wl-paste` from
[wl-clipboard](https://github.com/bugaevc/wl-clipboard). Without it the plugin
falls back to the clipboard.

## Settings

- **Input source** — selection then clipboard (default), selection only, or
  clipboard only, for when the query is empty.
- **Preserve casing** — keep casing inside words, so `NASA rocks` becomes
  `NASA_Rocks` rather than `Nasa_Rocks`. On by default.
- **Notify on copy** — notification after copying. On by default.

Full documentation, conversion table and Unicode behaviour:
<https://github.com/krisvanderven/noctalia-case-convert>
