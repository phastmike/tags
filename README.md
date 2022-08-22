# Tagger [![build](https://app.travis-ci.com/phastmike/tagger.svg?branch=master)](https://app.travis-ci.com/github/phastmike/tagger)

A GNOME text tagger inspired by the [TextAnalysisTool.NET](https://textanalysistool.github.io/)
tool.

The main goal is to aid log analysis by tagging lines with user defined colors.
Tags have a description/name, a visibility toggle and a hit counter.

## Screenshot

![tagger](./data/screenshots/tagger_1.png)

## Features and Shortchuts

<kbd>Ctrl</kbd> + <kbd>N</kbd> : Add a Tag

<kbd>Ctrl</kbd> + <kbd>S</kbd> : Save tagged lines

<kbd>Ctrl</kbd> + <kbd>H</kbd> : Toggle untagged lines visibility

<kbd>Ctrl</kbd> + <kbd>F</kbd> : Hide/Show Tag list (bottom)

Additional features:

- Load tags
- Save tags


## Development

Developed with Vala + Gtk4.

### Dependencies

It depends on:

- meson
- ninja
- valac
- Gtk 4

### Build

Clone the repository and inside it, compile with:

`$ meson build && cd build && ninja`

Then, test it with:

`$ ./src/tagger`

If you want to install, do it with:

`$ ninja install`

---

Only works with text files and uses string matching rules.

