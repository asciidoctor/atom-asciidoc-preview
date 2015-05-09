url = require 'url'

AsciiDocPreviewView = require './asciidoc-preview-view'
AttributesProvider = require "./attributes-provider"
renderer = null # Defer until used

module.exports =

  editorSubscription: null
  providers: []
  autocomplete: null

  configDefaults:
    compatMode: true
    showTitle: true
    safeMode: 'safe'
    showToc: true
    showNumberedHeadings: true
    renderOnSaveOnly: false
    defaultAttributes: 'platform=opal platform-opal env=browser env-browser'
    grammars: [
      'source.asciidoc'
      'text.plain'
      'text.plain.null-grammar'
    ]

  activate: ->
    atom.commands.add 'atom-workspace',
      'asciidoc-preview:toggle': =>
        @toggle()
      'asciidoc-preview:copy-html': =>
        @copyHtml()
      'asciidoc-preview:toggle-render-on-save-only': =>
        @changeRenderMode()
      'pane-container:active-pane-item-changed': =>
        @changeRenderMode()
      'asciidoc-preview:toggle-show-title': ->
        atom.config.toggle('asciidoc-preview.showTitle')
      'asciidoc-preview:toggle-compat-mode': ->
        atom.config.toggle('asciidoc-preview.compatMode')
      'asciidoc-preview:toggle-show-toc': ->
        atom.config.toggle('asciidoc-preview.showToc')
      'asciidoc-preview:toggle-show-numbered-headings': ->
        atom.config.toggle('asciidoc-preview.showNumberedHeadings')
      'asciidoc-preview:toggle-render-on-save-only': ->
        atom.config.toggle('asciidoc-preview.renderOnSaveOnly')

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

    atom.packages.activatePackage("autocomplete-plus")
      .then (pkg) =>
        @autocomplete = pkg.mainModule
        return unless @autocomplete?
        Provider = (require './attributes-provider').ProviderClass(@autocomplete.Provider, @autocomplete.Suggestion)
        return unless Provider?
        @editorSubscription = atom.workspace.observeTextEditors((editor) => @registerProvider(Provider, editor))

  registerProvider: (Provider, editor) ->
    return unless Provider?
    return unless editor?
    editorView = atom.views.getView(editor)
    return unless editorView?
    if not editorView.mini
      provider = new Provider(editor)
      @autocomplete.registerProviderForEditor(provider, editor)
      @providers.push(provider)

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

    previewPane = atom.workspace.paneForUri(uri)
    if previewPane
      previewPane.destroyItem(previewPane.itemForUri(uri))
      return

    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri, split: 'right', searchAllPanes: true).done (asciidocPreview) ->
      if asciidocPreview instanceof AsciiDocPreviewView
        asciidocPreview.renderAsciiDoc()
        previousActivePane.activate()

  changeRenderMode: ->
    document.querySelector('#asciidoc-changemode')?.remove()
    return unless @checkFile()?

    statusBar = document.querySelector('status-bar')

    span = document.createElement("span")
    span.setAttribute 'id', 'asciidoc-changemode'
    saveOnly = atom.config.get('asciidoc-preview.renderOnSaveOnly')
    if saveOnly
      span.appendChild document.createTextNode("Render on save")
    else
      span.appendChild document.createTextNode("Render on change")

    statusBar?.addLeftTile(item: span, priority: 100)

  copyHtml: ->
    editor = atom.workspace.getActiveEditor()
    return unless editor?

    renderer ?= require './renderer'
    text = editor.getSelectedText() or editor.getText()
    renderer.toText text, editor.getPath(), (error, html) =>
      if error
        console.warn('Copying AsciiDoc as HTML failed', error)
      else
        atom.clipboard.write(html)

  deactivate: ->
    @editorSubscription?.dispose()
    @editorSubscription = null

    @providers.forEach (provider) => @autocomplete.unregisterProvider(provider)
    @providers = []
