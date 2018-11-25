# AsciiDoc Preview package

[![Atom Package](https://img.shields.io/apm/v/asciidoc-preview.svg)](https://atom.io/packages/asciidoc-preview)
[![Atom Package Downloads](https://img.shields.io/apm/dm/asciidoc-preview.svg)](https://atom.io/packages/asciidoc-preview)
[![Build Status (Linux)](https://travis-ci.org/asciidoctor/atom-asciidoc-preview.svg?branch=master)](https://travis-ci.org/asciidoctor/atom-asciidoc-preview)
[![Build Status (Windows)](https://ci.appveyor.com/api/projects/status/a7240elaip2dkd16?svg=true)](https://ci.appveyor.com/project/asciidoctor/atom-asciidoc-preview)
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/asciidoctor/atom-asciidoc-preview/blob/master/LICENSE.md)

Shows the rendered HTML of the AsciiDoc content in current editor.

Toggle the preview pane, which appears to the right of the editor, by using the key combination <kbd>ctrl-shift-a</kbd> or <kbd>cmd-shift-a</kbd>.

It is currently enabled for `.adoc`, `.asciidoc`, `.ad`, `.asc`, `.adoc.txt`, `.txt` files.

**Note:** since 1.0.0, the auto-completions have been migrated to a dedicate package: [autocomplete-asciidoc](https://atom.io/packages/autocomplete-asciidoc).

This package use [Asciidoctor.js](https://github.com/asciidoctor/asciidoctor.js).

![asciidoc-preview](https://cloud.githubusercontent.com/assets/5674651/23831539/c914762a-0723-11e7-85f6-f7a16dcfa1e9.png)


## Options

* Live preview or preview only on save.
* Choose the position of the preview pane: "left", "right", "up", "down" (default: "right")
* Enable or disable table of contents (TOC) in preview pane.
  * Supported TOC positions: default (center), preamble, or macro.
  * Choose none in settings to allow document to control position.
  * If toc attribute is set to left or right, the TOC will appear in the center.
* Save as HTML: save the document to an HTML file.
* Export as PDF: create a PDF file and open with your default PDF viewer.
  * [asciidoctor-pdf](https://github.com/asciidoctor/asciidoctor-pdf) command must be available on your `PATH`.
  * more styling options are available in the package settings.
* Synchronize the preview pane: synchronize the preview pane with the AsciiDoc source pane.
  * **WARNING:** The scroll position on the preview pane does not automatically scroll the AsciiDoc source pane.

More options are available :
* in the package settings
* in the global menu
* by right-clicking on the preview
* by right-clicking on an AsciiDoc file.

## Disclaimer About Styles

The preview window is not meant to emulate the published styles.
Rather, it's intended to present a preview of the content to assist with editing.
This is by design.
It also aims to make the best use of limited screen space.
So, for example, you won't see functionality such as a sidebar TOC.
The colors may also differ to better integrate with the Atom theme.
If you want to customize the apparance of the preview, you can specify your own stylesheet in the settings.

## Others Atom packages for AsciiDoc

* [language-asciidoc](https://atom.io/packages/language-asciidoc): Syntax highlighting and snippets for AsciiDoc (with Asciidoctor flavor).
* [asciidoc-preview](https://atom.io/packages/asciidoc-preview): Show an preview for the AsciiDoc content in the current editor.
* [autocomplete-asciidoc](https://atom.io/packages/autocomplete-asciidoc): AsciiDoc language autocompletions.
* [asciidoc-image-helper](https://atom.io/packages/asciidoc-image-helper): When pasting an image into an Asciidoc document, this package will paste clipboard image data as a file into a folder specified by the user.
* [asciidoc-assistant](https://atom.io/packages/asciidoc-assistant): install Atom AsciiDoc basic packages with one package.

## More

You can install this module from the command-line by typing `apm install asciidoc-preview`.

![AsciiDoc Preview demo](https://cloud.githubusercontent.com/assets/5674651/15512720/96199b06-21e1-11e6-9eab-56826356a4e9.gif)

Thanks to [@kevinsawicki](https://github.com/kevinsawicki) for inspiration [markdown-preview](https://github.com/atom/markdown-preview).
