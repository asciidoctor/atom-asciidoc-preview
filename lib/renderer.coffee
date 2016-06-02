{$} = require 'atom-space-pen-views'
{Task} = require 'atom'
path = require 'path'
fs = require 'fs-plus'
cheerio = require 'cheerio'
# No direct dependence with Highlight because it requires a compilation. See #63 and #150 and atom/highlights#36.
Highlights = require path.join atom.packages.resolvePackagePath('markdown-preview'), '..', 'highlights'
{scopeForFenceName} = require './extension-helper'

highlighter = null
{resourcePath} = atom.getLoadSettings()
packagePath = path.dirname(__dirname)

exports.toHtml = (text='', filePath, callback) ->
  return unless atom.config.get('asciidoc-preview.defaultAttributes')?
  attributes =
    defaultAttributes: atom.config.get('asciidoc-preview.defaultAttributes')
    numbered: sectionNumbering()
    skipfrontmatter: if atom.config.get('asciidoc-preview.frontMatter') then '' else 'skip-front-matter'
    showtitle: if atom.config.get('asciidoc-preview.showTitle') then 'showtitle' else 'showtitle!'
    compatmode: if atom.config.get('asciidoc-preview.compatMode') then 'compat-mode=@' else ''
    forceExperimental: if atom.config.get('asciidoc-preview.forceExperimental') then 'experimental' else ''
    toctype: calculateTocType()
    safemode: atom.config.get('asciidoc-preview.safeMode') or 'safe'
    doctype: atom.config.get('asciidoc-preview.docType') or 'article'
    opalPwd: window.location.href

  taskPath = require.resolve('./worker')

  Task.once taskPath, text, attributes, filePath, (html) ->
    html = sanitize(html)
    html = resolveImagePaths(html, filePath)
    html = tokenizeCodeBlocks(html)
    callback(html)

exports.toText = (text='', filePath, callback) ->
  exports.toHtml text, filePath, (error, html) ->
    if error
      callback(error)
    else
      string = $(document.createElement('div')).append(html)[0].innerHTML
      callback(null, string)

calculateTocType = ->
  tocType = atom.config.get 'asciidoc-preview.tocType'
  if tocType is 'none'
    return ''
  # NOTE: 'auto' (blank option in asciidoctor) is currently not supported but
  # this section is left as a reminder of the expected behaviour
  else if tocType is 'auto'
    return 'toc! toc2!'
  else
    return "toc=#{tocType} toc2!"

sectionNumbering = ->
  numberedOption = atom.config.get('asciidoc-preview.sectionNumbering')
  if numberedOption is 'always-enabled'
    'sectnums'
  else if numberedOption is 'always-disabled'
    'sectnums!'
  else if numberedOption is 'enabled-by-default'
    'sectnums=@'
  else
    ''

sanitize = (html) ->
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
  [rootDirectory] = atom.project.relativizePath(filePath)
  o = cheerio.load(html)
  for imgElement in o('img')
    img = o(imgElement)
    if src = img.attr('src')
      continue if src.match(/^(https?|atom):\/\//)
      continue if src.startsWith(process.resourcesPath)
      continue if src.startsWith(resourcePath)
      continue if src.startsWith(packagePath)

      if src[0] is '/'
        unless fs.isFileSync(src)
          if rootDirectory
            img.attr('src', path.join(rootDirectory, src.substring(1)))
      else
        img.attr('src', path.resolve(path.dirname(filePath), src))

  o.html()

tokenizeCodeBlocks = (html, defaultLanguage='text') ->
  html = $(html)

  if fontFamily = atom.config.get('editor.fontFamily')
    $(html).find('code').css('font-family', fontFamily)

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
