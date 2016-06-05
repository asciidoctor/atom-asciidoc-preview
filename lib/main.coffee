url = require 'url'
path = require 'path'
fs = require 'fs-plus'

AsciiDocPreviewView = null
renderer = null # Defer until used

isAsciiDocPreviewView = (object) ->
  AsciiDocPreviewView ?= require './asciidoc-preview-view'
  object instanceof AsciiDocPreviewView

module.exports =

  activate: ->
    if parseFloat(atom.getVersion()) < 1.7
      atom.deserializers.add
        name: 'AsciiDocPreviewView'
        deserialize: module.exports.createAsciiDocPreviewView.bind(module.exports)

    atom.commands.add 'atom-workspace',
      'asciidoc-preview:toggle': =>
        @toggle()
      'asciidoc-preview:toggle-show-title': ->
        keyPath = 'asciidoc-preview.showTitle'
        atom.config.set(keyPath, not atom.config.get(keyPath))
      'asciidoc-preview:toggle-compat-mode': ->
        keyPath = 'asciidoc-preview.compatMode'
        atom.config.set(keyPath, not atom.config.get(keyPath))
      'asciidoc-preview:set-toc-none': ->
        atom.config.set('asciidoc-preview.tocType', 'none')
      'asciidoc-preview:set-toc-preamble': ->
        atom.config.set('asciidoc-preview.tocType', 'preamble')
      'asciidoc-preview:set-toc-macro': ->
        atom.config.set('asciidoc-preview.tocType', 'macro')
      'asciidoc-preview:set-section-numbering-enabled-by-default': ->
        atom.config.set('asciidoc-preview.sectionNumbering', 'enabled-by-default')
      'asciidoc-preview:set-section-numbering-always-enabled': ->
        atom.config.set('asciidoc-preview.sectionNumbering', 'always-enabled')
      'asciidoc-preview:set-section-numbering-always-disabled': ->
        atom.config.set('asciidoc-preview.sectionNumbering', 'always-disabled')
      'asciidoc-preview:set-section-numbering-not-specified': ->
        atom.config.set('asciidoc-preview.sectionNumbering', 'not-specified')
      'asciidoc-preview:toggle-skip-front-matter': ->
        keyPath = 'asciidoc-preview.skipFrontMatter'
        atom.config.set(keyPath, not atom.config.get(keyPath))
      'asciidoc-preview:toggle-render-on-save-only': ->
        keyPath = 'asciidoc-preview.renderOnSaveOnly'
        atom.config.set(keyPath, not atom.config.get(keyPath))

    fileExtensions = [
      'adoc'
      'asciidoc'
      'ad'
      'asc'
      'txt'
    ]
    previewFile = @previewFile.bind(this)
    atom.commands.add ".tree-view .file .name[data-name$=\\.#{extension}]", 'asciidoc-preview:preview-file', previewFile for extension in fileExtensions
    atom.commands.add ".tree-view .file .name[data-name$=\\.#{extension}]", 'asciidoc-preview:export-pdf', @exportAsPdf for extension in fileExtensions

    atom.workspace.addOpener (uriToOpen) =>
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
        @createAsciiDocPreviewView(editorId: pathname.substring(1))
      else
        @createAsciiDocPreviewView(filePath: pathname)

  createAsciiDocPreviewView: (state) ->
    if state.editorId or fs.isFileSync(state.filePath)
      AsciiDocPreviewView ?= require './asciidoc-preview-view'
      new AsciiDocPreviewView(state)

  toggle: ->
    if isAsciiDocPreviewView(atom.workspace.getActivePaneItem())
      atom.workspace.destroyActivePaneItem()
      return

    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    grammars = atom.config.get('asciidoc-preview.grammars') ? []
    return unless editor.getGrammar().scopeName in grammars

    @addPreviewForEditor(editor) unless @removePreviewForEditor(editor)

  uriForEditor: (editor) ->
    "asciidoc-preview://editor/#{editor.id}"

  removePreviewForEditor: (editor) ->
    uri = @uriForEditor(editor)
    previewPane = atom.workspace.paneForURI(uri)
    if previewPane?
      previewPane.destroyItem(previewPane.itemForURI(uri))
      true
    else
      false

  addPreviewForEditor: (editor) ->
    uri = @uriForEditor(editor)
    previousActivePane = atom.workspace.getActivePane()
    options =
      searchAllPanes: true
      split: atom.config.get 'asciidoc-preview.openInPane'

    atom.workspace.open(uri, options).then (markdownPreviewView) ->
      if isAsciiDocPreviewView(markdownPreviewView)
        previousActivePane.activate()

  previewFile: ({target}) ->
    filePath = target.dataset.path
    return unless filePath

    for editor in atom.workspace.getTextEditors() when editor.getPath() is filePath
      @addPreviewForEditor(editor)
      return

    atom.workspace.open "asciidoc-preview://#{encodeURI(filePath)}", searchAllPanes: true

  exportAsPdf: ({target}) ->
    if atom.config.get 'asciidoc-preview.experimental.exportAsPdf'
      spawn = require('child_process').spawn

      sourceFilePath = target.dataset.path
      if process.platform is 'win32'
        cmd = spawn 'asciidoctor-pdf', [sourceFilePath]
      else
        shell = process.env['SHELL'] or 'bash'
        cmd = spawn 'asciidoctor-pdf', [sourceFilePath], shell: "#{shell} -i -l"

      cmd.stdout.on 'data', (data) ->
        atom.notifications.addInfo 'Export as PDF:', detail: data.toString() or '', dismissable: true

      cmd.stderr.on 'data', (data) ->
        console.error "stderr: #{data}"
        atom.notifications.addError 'Error:', detail: data.toString() or '', dismissable: true

      cmd.on 'close', (code) ->
        basename = path.basename(sourceFilePath, path.extname(sourceFilePath))
        pdfFilePath = path.join(path.dirname(sourceFilePath), basename) + '.pdf'

        if code is 0
          atom.notifications.addSuccess 'Export as PDF completed!', detail: pdfFilePath or '', dismissable: false
        else
          atom.notifications.addWarning 'Export as PDF completed with errors.', detail: pdfFilePath or '', dismissable: false

    else
      message = '''
        This feature is experimental.
        You must manually activate this feature in the package settings.
        `asciidoctor-pdf` must be installed in you computer.
        '''
      atom.notifications.addWarning 'Export as PDF:', detail: message or '', dismissable: true
