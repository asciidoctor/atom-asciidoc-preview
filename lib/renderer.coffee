path = require 'path'
_ = require 'underscore-plus'
cheerio = require 'cheerio'
{$} = require 'atom-space-pen-views'
{Task} = require 'atom'
# use the native highlights
pathWatcherDirectory = atom.packages.resolvePackagePath('markdown-preview')
Highlights = require path.join(pathWatcherDirectory, '..', 'highlights')
{scopeForFenceName} = require './extension-helper'

highlighter = null

exports.toHtml = (text, filePath, callback) ->
  return unless atom.config.get('asciidoc-preview.defaultAttributes')?
  attributes = {
    defaultAttributes: atom.config.get('asciidoc-preview.defaultAttributes'),
    numbered: if atom.config.get('asciidoc-preview.showNumberedHeadings') then 'numbered' else 'numbered!',
    skipfrontmatter: if atom.config.get('asciidoc-preview.skipFrontMatter') then 'skip-front-matter' else '',
    showtitle: if atom.config.get('asciidoc-preview.showTitle') then 'showtitle' else 'showtitle!',
    compatmode: if atom.config.get('asciidoc-preview.compatMode') then 'compat-mode=@' else '',
    toctype: calculateTocType(),
    safemode: atom.config.get('asciidoc-preview.safeMode') or 'safe',
    doctype: atom.config.get('asciidoc-preview.docType') or "article",
    opalPwd: window.location.href
  }

  taskPath = require.resolve('./worker')

  Task.once taskPath, text, attributes, filePath, (html) ->
    html = sanitize(html)
    html = resolveImagePaths(html, filePath)
    html = tokenizeCodeBlocks(html)
    callback(html)

exports.toText = (text, filePath, callback) ->
  exports.toHtml text, filePath, (error, html) ->
    if error
      callback(error)
    else
      string = $(document.createElement('div')).append(html)[0].innerHTML
      callback(error, string)

calculateTocType = () ->
  if (atom.config.get('asciidoc-preview.tocType') == 'none')
    return ""
  # NOTE: 'auto' (blank option in asciidoctor) is currently not supported but
  # this section is left as a reminder of the expected behaviour
  else if (atom.config.get('asciidoc-preview.tocType') == 'auto')
    return "toc! toc2!"
  else
    return "toc=#{atom.config.get('asciidoc-preview.tocType')} toc2!"

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
  html = $(html)
  for imgElement in html.find("img")
    img = $(imgElement)
    if src = img.attr('src')
      continue if src.match /^(https?:\/\/)/
      img.attr('src', path.resolve(path.dirname(filePath), src))

  html

tokenizeCodeBlocks = (html) ->
  html = $(html)

  if fontFamily = atom.config.get('editor.fontFamily')
    $(html).find('code').css('font-family', fontFamily)

  for preElement in $.merge(html.filter("pre"), html.find("pre"))
    codeBlock = $(preElement.firstChild)
    fenceName = codeBlock.attr('class')?.replace(/^language-/, '') ? 'text'

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
