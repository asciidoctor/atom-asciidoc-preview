url = require 'url'
AsciiDocPreviewView = require './asciidoc-preview-view'

renderer = null # Defer until used

module.exports =

  config:
    compatMode:
      title: 'Compatibility mode (AsciiDoc Python)'
      type: 'boolean'
      default: false
      order: 1
    forceExperimental:
      title: 'Force enable experimental extensions'
      description: '''
        The features behind this attribute are subject to change and may even be removed in a future version.

        Currently enables the UI macros (`button`, `menu` and `kbd`).
        '''
      type: 'boolean'
      default: false
      order: 2
    showTitle:
      description: '''
        If set, displays an embedded document’s title.

        Mutually exclusive with the notitle attribute.
        '''
      type: 'boolean'
      default: true
      order: 3
    safeMode:
      description: '''
        Set safe mode level: `unsafe`, `safe`, `server` or `secure`.

        Disables potentially dangerous macros in source files, such as `include::[]`.

        http://asciidoctor.org/docs/user-manual/#running-asciidoctor-securely
        '''
      type: 'string'
      default: 'safe'
      enum: ['unsafe', 'safe', 'server', 'secure']
      order: 4
    tocType:
      title: 'Show Table of Contents'
      type: 'string'
      default: 'preamble'
      enum: ['none', 'preamble', 'macro']
      order: 5
    frontMatter:
      description: '''
        If set, consume YAML-style front matter at the top of the document and store it in the front-matter attribute.
        '''
      type: 'boolean'
      default: false
      order: 6
    showNumberedHeadings:
      description: 'Auto-number section titles.'
      type: 'boolean'
      default: true
      order: 7
    renderOnSaveOnly:
      type: 'boolean'
      default: false
      order: 8
    defaultAttributes:
      type: 'string'
      default: 'platform=opal platform-opal env=browser env-browser source-highlighter=highlight.js data-uri!'
      order: 9
    grammars:
      type: 'array'
      default: [
        'source.asciidoc'
        'text.plain'
        'text.plain.null-grammar'
      ]
      order: 10

  activate: ->
    atom.commands.add 'atom-workspace',
      'asciidoc-preview:toggle': =>
        @toggle()
      'asciidoc-preview:copy-html': =>
        @copyHtml()
      'pane-container:active-pane-item-changed': =>
        @changeRenderMode()
      'asciidoc-preview:toggle-show-title': ->
        keyPath = 'asciidoc-preview.showTitle'
        atom.config.set(keyPath, not atom.config.get(keyPath))
      'asciidoc-preview:toggle-compat-mode': ->
        keyPath = 'asciidoc-preview.compatMode'
        atom.config.set(keyPath, not atom.config.get(keyPath))
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
        atom.config.set(keyPath, not atom.config.get(keyPath))
      'asciidoc-preview:toggle-show-numbered-headings': ->
        keyPath = 'asciidoc-preview.showNumberedHeadings'
        atom.config.set(keyPath, not atom.config.get(keyPath))
      'asciidoc-preview:toggle-render-on-save-only': =>
        keyPath = 'asciidoc-preview.renderOnSaveOnly'
        atom.config.set(keyPath, not atom.config.get(keyPath))
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

    previewPane = atom.workspace.paneForURI uri
    if previewPane
      previewPane.destroyItem previewPane.itemForURI(uri)
      @changeRenderMode()
      return

    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri, split: 'right', searchAllPanes: true)
      .then (asciidocPreview) ->
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
    saveOnly = atom.config.get 'asciidoc-preview.renderOnSaveOnly'
    if saveOnly
      divChangeMode.appendChild document.createTextNode('Render on save')
    else
      divChangeMode.appendChild document.createTextNode('Render on change')

    statusBar?.addLeftTile(item: divChangeMode, priority: 100)

  copyHtml: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    renderer ?= require './renderer'
    text = editor.getSelectedText() or editor.getText()
    renderer.toText text, editor.getPath(), (error, html) ->
      if error
        console.warn 'Copying AsciiDoc as HTML failed', error
      else
        atom.clipboard.write(html)
