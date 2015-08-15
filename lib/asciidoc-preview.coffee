url = require 'url'

AsciiDocPreviewView = require './asciidoc-preview-view'
attributesProvider = require "./attributes-provider"
renderer = null # Defer until used

module.exports =

  config:
    compatMode:
      type: 'boolean'
      default: true
    showTitle:
      type: 'boolean'
      default: true
    safeMode:
      type: 'string'
      default: 'safe'
    tocType:
      title: 'Show Table of Contents'
      type: 'string'
      default: 'preamble'
      enum: ['none','preamble','macro']
    skipFrontMatter:
      type: 'boolean'
      default: true
    showNumberedHeadings:
      type: 'boolean'
      default: true
    renderOnSaveOnly:
      type: 'boolean'
      default: false
    defaultAttributes:
      type: 'string'
      default: 'platform=opal platform-opal env=browser env-browser source-highlighter=highlight.js data-uri!'
    grammars:
      type: 'array'
      default: [
        'source.asciidoc'
        'text.plain'
        'text.plain.null-grammar'
      ]

  activate: ->
    attributesProvider.loadCompletions()

    atom.commands.add 'atom-workspace',
      'asciidoc-preview:toggle': =>
        @toggle()
      'asciidoc-preview:copy-html': =>
        @copyHtml()
      'pane-container:active-pane-item-changed': =>
        @changeRenderMode()
      'asciidoc-preview:toggle-show-title': ->
        keyPath = 'asciidoc-preview.showTitle'
        atom.config.set(keyPath, !atom.config.get(keyPath))
      'asciidoc-preview:toggle-compat-mode': ->
        keyPath = 'asciidoc-preview.compatMode'
        atom.config.set(keyPath, !atom.config.get(keyPath))
      'asciidoc-preview:set-toc-none': ->
        keyPath = 'asciidoc-preview.tocType'
        atom.config.set(keyPath, 'none')
      'asciidoc-preview:set-toc-preamble': ->
        keyPath = 'asciidoc-preview.tocType'
        atom.config.set(keyPath, 'preamble')
      'asciidoc-preview:set-toc-macro': ->
        keyPath = 'asciidoc-preview.tocType'
        atom.config.set(keyPath, 'macro')
      'asciidoc-preview:toggle-skip-front-matter': ->
        keyPath = 'asciidoc-preview.skipFrontMatter'
        atom.config.set(keyPath, !atom.config.get(keyPath))
      'asciidoc-preview:toggle-show-numbered-headings': ->
        keyPath = 'asciidoc-preview.showNumberedHeadings'
        atom.config.set(keyPath, !atom.config.get(keyPath))
      'asciidoc-preview:toggle-render-on-save-only': =>
        keyPath = 'asciidoc-preview.renderOnSaveOnly'
        atom.config.set(keyPath, !atom.config.get(keyPath))
        @changeRenderMode()

    atom.workspace.addOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'asciidoc-preview:'

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      if host is 'editor'
        new AsciiDocPreviewView(editorId: pathname.substring(1))
      else
        new AsciiDocPreviewView(filePath: pathname)

  provide: ->
    attributesProvider

  checkFile: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    grammars = atom.config.get('asciidoc-preview.grammars') ? []
    return unless editor.getGrammar().scopeName in grammars
    editor

  toggle: ->
    editor = @checkFile()
    return unless editor?
    uri = "asciidoc-preview://editor/#{editor.id}"

    previewPane = atom.workspace.paneForURI(uri)
    if previewPane
      previewPane.destroyItem(previewPane.itemForURI(uri))
      @changeRenderMode()
      return

    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri, split: 'right', searchAllPanes: true).done (asciidocPreview) ->
      if asciidocPreview instanceof AsciiDocPreviewView
        asciidocPreview.renderAsciiDoc()
        previousActivePane.activate()

  changeRenderMode: ->
    document.querySelector('#asciidoc-changemode')?.remove()
    editor = @checkFile()
    return unless editor?

    uri = "asciidoc-preview://editor/#{editor.id}"

    previewPane = atom.workspace.paneForURI(uri)
    return unless previewPane?


    statusBar = document.querySelector('status-bar')

    divChangeMode = document.createElement("div")
    divChangeMode.setAttribute 'id', 'asciidoc-changemode'
    divChangeMode.classList.add 'inline-block'
    saveOnly = atom.config.get('asciidoc-preview.renderOnSaveOnly')
    if saveOnly
      divChangeMode.appendChild document.createTextNode("Render on save")
    else
      divChangeMode.appendChild document.createTextNode("Render on change")

    statusBar?.addLeftTile(item: divChangeMode, priority: 100)

  copyHtml: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    renderer ?= require './renderer'
    text = editor.getSelectedText() or editor.getText()
    renderer.toText text, editor.getPath(), (error, html) =>
      if error
        console.warn('Copying AsciiDoc as HTML failed', error)
      else
        atom.clipboard.write(html)
