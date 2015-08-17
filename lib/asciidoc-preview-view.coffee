path = require 'path'
{Emitter, Disposable, CompositeDisposable} = require 'atom'
{$, $$$, ScrollView} = require 'atom-space-pen-views'
_ = require 'underscore-plus'
fs = require 'fs-plus'
mustache = require 'mustache'
renderer = require './renderer'
markdownDirectory = atom.packages.resolvePackagePath('markdown-preview')
{File} = require path.join(markdownDirectory, '..', 'pathwatcher')

module.exports =
class AsciiDocPreviewView extends ScrollView
  atom.deserializers.add(this)

  @deserialize: (state) ->
    new AsciiDocPreviewView(state)

  @content: ->
    @div class: 'asciidoc-preview native-key-bindings', tabindex: -1

  constructor: ({@editorId, filePath}) ->
    super
    @emitter = new Emitter
    @disposables = new CompositeDisposable

  attached: ->
    if @editorId?
      @resolveEditor(@editorId)
    else
      if atom.workspace?
        @subscribeToFilePath(@filePath)
      else
        @disposables.add atom.packages.onDidActivateInitialPackages =>
          @subscribeToFilePath(@filePath)

  serialize: ->
    deserializer: 'AsciiDocPreviewView'
    filePath: @getPath()
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
    @file = new File(filePath)
    @emitter.emit 'did-change-title'
    @handleEvents()
    @renderAsciiDoc()

  resolveEditor: (editorId) ->
    resolve = =>
      @editor = @editorForId(editorId)

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
      @disposables.add atom.packages.onDidActivateInitialPackages(resolve)

  editorForId: (editorId) ->
    for editor in atom.workspace.getTextEditors()
      return editor if editor.id?.toString() is editorId.toString()
    null

  handleEvents: ->
    @disposables.add atom.grammars.onDidAddGrammar => _.debounce((=> @renderAsciiDoc()), 250)
    @disposables.add atom.grammars.onDidUpdateGrammar _.debounce((=> @renderAsciiDoc()), 250)

    atom.commands.add @element,
      'core:move-up': =>
        @scrollUp()
      'core:move-down': =>
        @scrollDown()
      'core:save-as': (event) =>
        event.stopPropagation()
        @saveAs()
      'core:copy': (event) =>
        event.stopPropagation() if @copyToClipboard()
      'asciidoc-preview:zoom-in': =>
        zoomLevel = parseFloat(@css('zoom')) or 1
        @css('zoom', zoomLevel + .1)
      'asciidoc-preview:zoom-out': =>
        zoomLevel = parseFloat(@css('zoom')) or 1
        @css('zoom', zoomLevel - .1)
      'asciidoc-preview:reset-zoom': =>
        @css('zoom', 1)

    changeHandler = =>
      @renderAsciiDoc()

      # TODO: Remove paneForURI call when ::paneForItem is released
      pane = atom.workspace.paneForItem?(this) ? atom.workspace.paneForURI(@getURI())
      if pane? and pane isnt atom.workspace.getActivePane()
        pane.activateItem(this)

    renderOnChange = =>
      saveOnly = atom.config.get('asciidoc-preview.renderOnSaveOnly')
      changeHandler() if !saveOnly

    if @file?
      @disposables.add @file.onDidChange(changeHandler)
    else if @editor?
      @disposables.add @editor.getBuffer().onDidStopChanging =>
        renderOnChange()
      @disposables.add @editor.onDidChangePath => @emitter.emit 'did-change-title'
      @disposables.add @editor.getBuffer().onDidSave =>
        renderOnChange()
      @disposables.add @editor.getBuffer().onDidReload =>
        renderOnChange()

    @disposables.add atom.config.onDidChange 'asciidoc-preview.showTitle', changeHandler
    @disposables.add atom.config.onDidChange 'asciidoc-preview.compatMode', changeHandler
    @disposables.add atom.config.onDidChange 'asciidoc-preview.safeMode', changeHandler
    @disposables.add atom.config.onDidChange 'asciidoc-preview.defaultAttributes', changeHandler
    @disposables.add atom.config.onDidChange 'asciidoc-preview.tocType', changeHandler
    @disposables.add atom.config.onDidChange 'asciidoc-preview.skipFrontMatter', changeHandler
    @disposables.add atom.config.onDidChange 'asciidoc-preview.showNumberedHeadings', changeHandler

  renderAsciiDoc: ->
    @showLoading()
    if @file?
      @file.read().then (contents) => @renderAsciiDocText(contents)
    else if @editor?
      @renderAsciiDocText(@editor.getText())

  renderAsciiDocText: (text) ->
    renderer.toHtml text, @getPath(), (html) =>
      @loading = false
      @html(html)
      @enableAnchorScroll html, (top) =>
        @scrollTop top

      @emitter.emit 'did-change-asciidoc'
      @originalTrigger('asciidoc-preview:asciidoc-changed')

  enableAnchorScroll: (html, callback) ->
    document.querySelector('#asciidoc-linkUrl')?.remove()
    statusBar = document.querySelector('status-bar')
    divLink = document.createElement("div")
    divLink.setAttribute 'id', 'asciidoc-linkUrl'
    divLink.classList.add 'inline-block'

    statusBar?.addRightTile(item: divLink, priority: 300)


    html = $(html)
    for linkElement in html.find("a")
      link = $(linkElement)
      if hrefLink = link.attr('href')
        do(hrefLink) ->
          link.on 'mouseover', (e) ->
            # TODO Use constant
            cropUrl = if (hrefLink.length > 100) then hrefLink.substr(0, 97).concat('...')  else hrefLink
            divLink.appendChild document.createTextNode(cropUrl)
          link.on 'mouseleave', (e) ->
            $(divLink).empty()
        continue if not hrefLink.match(/^#/)
        if target = $(hrefLink)
          continue if not target.offset()
          # TODO Use tab height variable instead of 43
          top = target.offset().top - 43
          do (top) ->
            link.on 'click', (e) ->
              top = top
              callback top

  getTitle: ->
    if @file?
      "#{path.basename(@getPath())} Preview"
    else if @editor?
      "#{@editor.getTitle()} Preview"
    else
      "AsciiDoc Preview"

  getIconName: ->
    "eye"

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

  showError: (result) ->
    failureMessage = result?.message

    @html $$$ ->
      @h2 'Previewing AsciiDoc Failed'
      @h3 failureMessage if failureMessage?

  showLoading: ->
    @loading = true
    if !@firstloadingdone?
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

    atom.clipboard.write(@[0].innerHTML)
    true

  saveAs: ->
    return if @loading

    filePath = @getPath()
    if filePath
      filePath += '.html'
    else
      filePath = 'untitled.adoc.html'
      if projectPath = atom.project.getPaths()[0]
        filePath = path.join(projectPath, filePath)

    if htmlFilePath = atom.showSaveDialogSync(filePath)
      mustacheObject =
        title: 'test'
        content: @[0].innerHTML

      templatePath = path.join atom.packages.resolvePackagePath('asciidoc-preview'), 'templates', 'default.html'
      page = fs.readFileSync(templatePath, 'utf8')
      htmlContent = mustache.to_html page, mustacheObject
      fs.writeFileSync(htmlFilePath, htmlContent)
      atom.workspace.open(htmlFilePath)
