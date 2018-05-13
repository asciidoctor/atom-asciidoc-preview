{$} = require 'atom-space-pen-views'
{Task} = require 'atom'
path = require 'path'
fs = require 'fs-plus'
cheerio = require 'cheerio'
highlights = require './highlights'

{scopeForFenceName} = require './highlights-helper'

{makeAttributes, makeOptions} = require './configuration-builder'

highlighter = null
{resourcePath} = atom.getLoadSettings()
packagePath = path.dirname(__dirname)

exports.toHtml = (text='', filePath) ->
  render text, filePath
    .then (html) ->
      sanitize html
    .then (html) ->
      resolveImagePaths html, filePath
    .then (html) ->
      tokenizeCodeBlocks html

exports.toRawHtml = (text='', filePath) ->
  render text, filePath

exports.getBlockId = (bufferRowPosition) =>
  @blockPositions[bufferRowPosition + 1] if @blockPositions

render = (text='', filePath) =>
  return Promise.resolve() unless atom.config.get('asciidoc-preview.defaultAttributes')?

  new Promise (resolve, reject) =>
    attributes = makeAttributes()
    options = makeOptions filePath

    taskPath = require.resolve('./worker')
    task = Task.once taskPath, text, attributes, options

    task.on 'asciidoctor-load:success', ({blockPositions}) =>
      @blockPositions = blockPositions

    task.on 'asciidoctor-render:success', ({html}) ->
      console.warn "Rendering is empty: #{filePath}" if not html
      resolve html or ''

    task.on 'asciidoctor-render:error', ({code, errno, syscall, stack}) ->
      resolve """
        <div>
          <h1>Asciidoctor.js error</h1>
          <h2>Rendering error</h2>
          <div>
            <p><b>Please verify your document syntax.</b></p>
            <p>Details: #{stack.split('\n')[0]}</p>
            <p>[code: #{code}, errno: #{errno}, syscall: #{syscall}]<p>
            <div><pre>#{stack}</pre></div>
          </div>
        </div>
        """

sanitize = (html) ->
  return html unless html

  o = cheerio.load(html)
  o('script').remove()
  attributesToRemove = [
    'onabort'
    'onblur'
    'onchange'
    'onclick'
    'ondbclick'
    'onerror'
    'onfocus'
    'onkeydown'
    'onkeypress'
    'onkeyup'
    'onload'
    'onmousedown'
    'onmousemove'
    'onmouseover'
    'onmouseout'
    'onmouseup'
    'onreset'
    'onresize'
    'onscroll'
    'onselect'
    'onsubmit'
    'onunload'
  ]
  o('*').removeAttr(attribute) for attribute in attributesToRemove
  o.html()

resolveImagePaths = (html, filePath) ->
  return html unless html

  [rootDirectory] = atom.project.relativizePath(filePath)
  o = cheerio.load(html)
  for imgElement in o('img')
    img = o(imgElement)
    if src = img.attr('src')
      appenderChar = if src.indexOf('?') is -1 then "?" else "&"
      invalidateCache = "#{appenderChar}atomcache=#{Date.now()}"

      if src.match /^(https?|atom):\/\// or
          src.startsWith process.resourcesPath or
          src.startsWith resourcePath or
          src.startsWith packagePath
        img.attr 'src', src + invalidateCache
      else if src[0] is '/'
        unless fs.isFileSync src
          if rootDirectory
            img.attr 'src', path.join(rootDirectory, src.substring(1) + invalidateCache)
      else
        img.attr 'src', path.resolve(path.dirname(filePath), "#{src}#{invalidateCache}")

  o.html()

tokenizeCodeBlocks = (html, defaultLanguage='text') ->
  html = $(html)

  if fontFamily = atom.config.get 'editor.fontFamily'
    html.find('code').css 'font-family', fontFamily

  for preElement in $.merge(html.filter('pre'), html.find('pre'))
    codeBlock = $(preElement.firstChild)

    # Exclude text node to highlights
    # Because this creates a rendering bug with quotes substitutions #102
    if codeBlock[0]?.nodeType isnt Node.TEXT_NODE
      langExp = /language-([^ ]+)/g
      group = langExp.exec codeBlock.attr('class')

      if group and group.length
        fenceName = group[1]
      else
        fenceName = defaultLanguage

      # Exclude text block to highlights
      # Because this creates a rendering bug with quotes substitutions #193
      if fenceName is defaultLanguage
        preElement.className = ''
      else
        blockText = codeBlock.text()
        highlightedHtml = highlights
          fileContents: blockText
          scopeName: scopeForFenceName(fenceName, blockText)
          lineDivs: true
          editorDiv: true
          editorDivTag: 'pre'
          # The `editor` class messes things up as `.editor` has absolutely positioned lines
          editorDivClass: 'highlights editor-colors'

        highlightedBlock = $(highlightedHtml)

        highlightedBlock.addClass("lang-#{fenceName}")
        highlightedBlock.insertAfter(preElement)
        preElement.remove()

  html
