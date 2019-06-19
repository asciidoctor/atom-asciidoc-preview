{Emitter, Disposable, CompositeDisposable, File} = require 'atom'
{$, $$$, ScrollView} = require 'atom-space-pen-views'
path = require 'path'
fs = require 'fs-plus'
_ = require 'underscore-plus'
mustache = require 'mustache'
opn = require 'opn'
renderer = require './renderer'
pdfconverter = require './pdf-converter'

module.exports =
class AsciiDocPreviewView extends ScrollView
  @content: ->
    @div class: 'asciidoc-preview native-key-bindings', tabindex: -1

  constructor: ({@editorId, @filePath}) ->
    super
    @emitter = new Emitter
    @disposables = new CompositeDisposable
    @loaded = false

  attached: ->
    return if @isAttached
    @isAttached = true

    if @editorId?
      @resolveEditor @editorId
    else if atom.workspace?
      @subscribeToFilePath @filePath
    else
      @disposables.add atom.packages.onDidActivateInitialPackages =>
        @subscribeToFilePath @filePath

  serialize: ->
    deserializer: 'AsciiDocPreviewView'
    filePath: @getPath() ? @filePath
    editorId: @editorId

  destroy: ->
    @disposables.dispose()

  onDidChangeTitle: (callback) ->
    @emitter.on 'did-change-title', callback

  onDidChangeModified: (callback) ->
    # No op to suppress deprecation warning
    new Disposable

  onDidChangeAsciidoc: (callback) ->
    @emitter.on 'did-change-asciidoc', callback

  subscribeToFilePath: (filePath) ->
    @file = new File filePath
    @emitter.emit 'did-change-title'
    @handleEvents()
    @renderAsciiDoc()

  resolveEditor: (editorId) ->
    resolve = =>
      @editor = @editorForId editorId

      if @editor?
        @emitter.emit 'did-change-title' if @editor?
        @handleEvents()
        @renderAsciiDoc()
      else
        # The editor this preview was created for has been closed so close
        # this preview since a preview cannot be rendered without an editor
        atom.workspace?.paneForItem(this)?.destroyItem(this)

    if atom.workspace?
      resolve()
    else
      @disposables.add atom.packages.onDidActivateInitialPackages resolve

  editorForId: (editorId) ->
    for editor in atom.workspace.getTextEditors()
      return editor if editor.id?.toString() is editorId.toString()
    null

  handleEvents: ->
    @disposables.add atom.grammars.onDidAddGrammar => _.debounce((=> @renderAsciiDoc()), 250)
    @disposables.add atom.grammars.onDidUpdateGrammar _.debounce((=> @renderAsciiDoc()), 250)

    @disposables.add atom.commands.add @element,
      'core:move-up': =>
        @scrollUp()
      'core:move-down': =>
        @scrollDown()
      'asciidoc-preview:export-pdf': =>
        pdfconverter.convertFromPath(@filePath ? @getPath())
      'core:copy': (event) =>
        event.stopPropagation() if @copyToClipboard()
      'asciidoc-preview:zoom-in': =>
        zoomLevel = parseFloat(@css 'zoom') or 1
        @css 'zoom', zoomLevel + .1
      'asciidoc-preview:zoom-out': =>
        zoomLevel = parseFloat(@css 'zoom') or 1
        @css 'zoom', zoomLevel - .1
      'asciidoc-preview:reset-zoom': =>
        @css 'zoom', 1

    changeHandler = =>
      @renderAsciiDoc()

      pane = atom.workspace.paneForItem(this)
      if pane? and pane isnt atom.workspace.getActivePane()
        pane.activateItem(this)

    renderOnChange = ->
      saveOnly = atom.config.get 'asciidoc-preview.renderOnSaveOnly'
      changeHandler() if not saveOnly

    scrollPreview = (event, callback) ->
      if atom.config.get 'asciidoc-preview.scrollMode'
        blockId = renderer.getBlockId event.newBufferPosition.row
        if blockId?
          if target = document.getElementById(blockId)
            callback target.offsetTop
        # else
          # TODO Find the nearest block

    if @file?
      @disposables.add @file.onDidChange changeHandler
    else if @editor?
      @disposables.add @editor.onDidChangeCursorPosition (event) => scrollPreview event, (top) => @scrollTop top
      @disposables.add @editor.onDidChangePath => @emitter.emit 'did-change-title'
      buffer = @editor.getBuffer()
      @disposables.add buffer.onDidStopChanging renderOnChange
      @disposables.add buffer.onDidSave changeHandler
      @disposables.add buffer.onDidReload renderOnChange

    @disposables.add atom.config.onDidChange 'asciidoc-preview.showTitle', changeHandler
    @disposables.add atom.config.onDidChange 'asciidoc-preview.compatMode', changeHandler
    @disposables.add atom.config.onDidChange 'asciidoc-preview.safeMode', changeHandler
    @disposables.add atom.config.onDidChange 'asciidoc-preview.defaultAttributes', changeHandler
    @disposables.add atom.config.onDidChange 'asciidoc-preview.tocType', changeHandler
    @disposables.add atom.config.onDidChange 'asciidoc-preview.frontMatter', changeHandler
    @disposables.add atom.config.onDidChange 'asciidoc-preview.sectionNumbering', changeHandler
    @disposables.add atom.config.onDidChange 'asciidoc-preview.forceExperimental', changeHandler
    @disposables.add atom.config.onDidChange 'asciidoc-preview.baseDir', changeHandler

  renderAsciiDoc: ->
    @showLoading() unless @loaded
    @getAsciiDocSource().then (source) => @renderAsciiDocText(source) if source?

  getAsciiDocSource: ->
    if @file?.getPath()
      @file.read()
    else if @editor?
      Promise.resolve(@editor.getText())
    else
      Promise.resolve(null)

  renderAsciiDocText: (text) ->
    renderer.toHtml text, @getPath()
      .then (html) =>
        @loading = false
        @html(html)
        @enableAnchorScroll html, (top) =>
          @scrollTop top

        @emitter.emit 'did-change-asciidoc'
        @originalTrigger('asciidoc-preview:asciidoc-changed')

  enableAnchorScroll: (html, callback) ->
    html = $(html)
    for linkElement in html.find('a')
      link = $(linkElement)
      if hrefLink = link.attr('href')
        continue if not hrefLink.match(/^#/)
        # Because jQuery uses CSS syntax for selecting elements, some characters are interpreted as CSS notation.
        # In order to tell jQuery to treat these characters literally rather than as CSS notation, they must be "escaped" by placing two backslashes in front of them.
        if target = $(hrefLink.replace(/(\/|:|\.|\[|\]|,|\)|\()/g, '\\$1'))
          continue if not target[0]
          top = target[0].offsetTop
          do (top) ->
            link.on 'click', (e) ->
              top = top
              callback top

  getTitle: ->
    if @file?
      "#{path.basename @getPath()} Preview"
    else if @editor?
      "#{@editor.getTitle()} Preview"
    else
      'AsciiDoc Preview'

  getIconName: ->
    'eye'

  getURI: ->
    if @file?
      "asciidoc-preview://#{@getPath()}"
    else
      "asciidoc-preview://editor/#{@editorId}"

  getPath: ->
    if @file?
      @file.getPath()
    else if @editor?
      @editor.getPath()

  showLoading: ->
    @loading = true
    if not @firstloadingdone?
      @firstloadingdone = true
      @html $$$ ->
        @div class: 'asciidoc-spinner', 'Loading AsciiDoc\u2026'

  copyToClipboard: ->
    return false if @loading

    selection = window.getSelection()
    selectedText = selection.toString()
    selectedNode = selection.baseNode

    # Use default copy event handler if there is selected text inside this view
    return false if selectedText and selectedNode? and $.contains(@[0], selectedNode)

    atom.clipboard.write @[0].innerHTML
    true

  getSaveDialogOptions: ->
    defaultPath = @getPath()
    if defaultPath
      defaultPath += '.html'
    else
      defaultPath = 'untitled.adoc.html'
      if projectPath = atom.project.getPaths()[0]
        defaultPath = path.join(projectPath, defaultPath)

    return {defaultPath}

  saveAs: (htmlFilePath) ->
    if @loading
      atom.notifications.addWarning('Please wait until the Asciidoctor Preview has finished loading before saving')
      return

    packPath = atom.packages.resolvePackagePath 'asciidoc-preview'
    templatePath = path.join packPath, 'templates', 'default.html'

    @getAsciiDocSource()
      .then (source) =>
        renderer.toRawHtml source, @getPath()
      .then (html) =>
        model =
          content: html
          style: fs.readFileSync path.join(packPath, 'node_modules/@asciidoctor/core/dist/css/asciidoctor.css'), 'utf8'
          title: $(@html).find('h1').text() or path.basename htmlFilePath, '.html'
      .then (model) ->
        template = fs.readFileSync templatePath, 'utf8'
        mustache.to_html template, model
      .then (htmlContent) ->
        fs.writeFileSync htmlFilePath, htmlContent
      .then ->
        if atom.config.get 'asciidoc-preview.saveAsHtml.openInEditor'
          atom.workspace.open htmlFilePath

        if atom.config.get 'asciidoc-preview.saveAsHtml.openInBrowser'
          opn(htmlFilePath).catch (error) ->
            atom.notifications.addError error.toString(), detail: error?.stack or '', dismissable: true
            console.error error
