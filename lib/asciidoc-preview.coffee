url = require 'url'

AsciiDocPreviewView = require './asciidoc-preview-view'
renderer = null # Defer until used

module.exports =
  configDefaults:
    showTitle: true
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

  toggle: ->
    editor = atom.workspace.getActiveEditor()
    return unless editor?

    grammars = atom.config.get('asciidoc-preview.grammars') ? []
    return unless editor.getGrammar().scopeName in grammars

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
