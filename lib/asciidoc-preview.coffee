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
    safeMode: 'secure'
    showTableOfContent: true
    showNumberedHeadings: true
    renderOnSaveOnly: false
    defaultAttributes: 'platform=opal platform-opal env=browser env-browser'
    grammars: [
      'source.asciidoc'
      'text.plain'
      'text.plain.null-grammar'
    ]

  activate: ->
    atom.workspaceView.command 'asciidoc-preview:toggle', =>
      @toggle()

    atom.workspaceView.command 'asciidoc-preview:copy-html', =>
      @copyHtml()

    atom.workspaceView.command 'asciidoc-preview:toggle-show-title', ->
      atom.config.toggle('asciidoc-preview.showTitle')

    atom.workspaceView.command 'asciidoc-preview:toggle-compat-mode', ->
      atom.config.toggle('asciidoc-preview.compatMode')

    atom.workspaceView.command 'asciidoc-preview:toggle-show-toc', ->
      atom.config.toggle('asciidoc-preview.showToc')

    atom.workspaceView.command 'asciidoc-preview:toggle-show-numbered-headings', ->
      atom.config.toggle('asciidoc-preview.showNumberedHeadings')

    atom.workspaceView.command 'asciidoc-preview:toggle-render-on-save-only', ->
      atom.config.toggle('asciidoc-preview.renderOnSaveOnly')

    atom.workspaceView.command 'asciidoc-preview:toggle-render-on-save-only', =>
      @changeRenderMode()

    atom.workspaceView.on 'pane-container:active-pane-item-changed', =>
      @changeRenderMode()



    atom.workspace.registerOpener (uriToOpen) ->
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
    editor = atom.workspace.getActiveEditor()
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
    atom.workspaceView.find('#asciidoc-changemode')?.remove()
    return unless @checkFile()?

    saveOnly = atom.config.get('asciidoc-preview.renderOnSaveOnly')
    if saveOnly
      atom.workspaceView.statusBar?.appendLeft("<span id='asciidoc-changemode'>Render on save<span>")
    else
      atom.workspaceView.statusBar?.appendLeft("<span id='asciidoc-changemode'>Render on change<span>")

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
