{$} = require 'atom-space-pen-views'
{Task} = require 'atom'
path = require 'path'
fs = require 'fs-plus'
cheerio = require 'cheerio'
# No direct dependence with Highlight because it requires a compilation. See #63 and #150 and atom/highlights#36.
Highlights = require path.join atom.packages.resolvePackagePath('markdown-preview'), '..', 'highlights'
{scopeForFenceName} = require './highlights-helper'

{makeAttributes} = require './attributes-builder'

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

render = (text='', filePath) ->
  return Promise.resolve() unless atom.config.get('asciidoc-preview.defaultAttributes')?

  new Promise (resolve, reject) ->
    attributes = makeAttributes filePath

    taskPath = require.resolve('./worker')
    task = Task.once taskPath, text, attributes

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
            <div>#{stack}</div>
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
      continue if src.match /^(https?|atom):\/\//
      continue if src.startsWith process.resourcesPath
      continue if src.startsWith resourcePath
      continue if src.startsWith packagePath

      if src[0] is '/'
        unless fs.isFileSync src
          if rootDirectory
            img.attr('src', path.join(rootDirectory, src.substring(1)))
      else
        img.attr('src', path.resolve(path.dirname(filePath), src))

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
      fenceName = codeBlock.attr('class')?.replace(/^language-/, '') ? defaultLanguage

      highlighter ?= new Highlights(registry: atom.grammars)
      highlightedHtml = highlighter.highlightSync
        fileContents: codeBlock.text()
        scopeName: scopeForFenceName(fenceName)

      highlightedBlock = $(highlightedHtml)
      # The `editor` class messes things up as `.editor` has absolutely positioned lines
      highlightedBlock.removeClass('editor').addClass("lang-#{fenceName}")
      highlightedBlock.insertAfter(preElement)
      preElement.remove()

  html
