# AsciiDoc Preview package

[![Atom Package](https://img.shields.io/apm/v/asciidoc-preview.svg)](https://atom.io/packages/asciidoc-preview)
[![Atom Package Downloads](https://img.shields.io/apm/dm/asciidoc-preview.svg)](https://atom.io/packages/asciidoc-preview)
[![Build Status (Linux)](https://travis-ci.org/asciidoctor/atom-asciidoc-preview.svg?branch=master)](https://travis-ci.org/asciidoctor/atom-asciidoc-preview)
[![Build Status (Windows)](https://ci.appveyor.com/api/projects/status/a7240elaip2dkd16?svg=true)](https://ci.appveyor.com/project/asciidoctor/atom-asciidoc-preview)
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/asciidoctor/atom-asciidoc-preview/blob/master/LICENSE.md)

Shows the rendered HTML of the AsciiDoc content in current editor using <kbd>ctrl-shift-a</kbd> or <kbd>cmd-shift-a</kbd>.

It can be activated from the editor using the <kbd>ctrl-shift-a</kbd> or <kbd>cmd-shift-a</kbd> key-binding and is currently enabled for `.adoc`, `.asciidoc`, `.ad`, `.asc`, `.adoc.txt`, `.txt` files.

**Note:** since 1.0.0, the autocompletions have been migrated to a new package: [autocomplete-asciidoc](https://atom.io/packages/autocomplete-asciidoc)

You can install this module from the command-line by typing `apm install asciidoc-preview`.

You can toggle the preview pane, which appears to the right of the editor, using the key combination <kbd>ctrl-shift-a</kbd> or <kbd>cmd-shift-a</kbd>.

More options are accessible by right-clicking on the preview.

![AsciiDoc Preview demo](https://cloud.githubusercontent.com/assets/5674651/15512720/96199b06-21e1-11e6-9eab-56826356a4e9.gif)

Thanks to @kevinsawicki! I just adapted [markdown-preview](https://github.com/atom/markdown-preview) and used [Asciidoctor.js](https://github.com/asciidoctor/asciidoctor.js).
