path = require 'path'
_ = require 'underscore-plus'
cheerio = require 'cheerio'
{$, EditorView, Task} = require 'atom'
{extensionForFenceName} = require './extension-helper'

exports.toHtml = (text, filePath, callback) ->

  attributes= {
    defaultAttributes: atom.config.get('asciidoc-preview.defaultAttributes'),
    numbered: if atom.config.get('asciidoc-preview.showNumberedHeadings') then 'numbered' else 'numbered!',
    showtitle: if atom.config.get('asciidoc-preview.showTitle') then 'showtitle' else 'showtitle!',
    showtoc: if atom.config.get('asciidoc-preview.showToc')  then 'toc=preamble toc2!' else 'toc! toc2!',
    safemode: atom.config.get('asciidoc-preview.safeMode') or "safe",
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

    # go to next block unless this one has a class
    continue unless classNames = codeBlock.attr('class')?.split(' ')
    classNames = classNames.filter (className) ->
      className.match(/^language-/)
    fenceName = classNames[0]?.replace(/^language-/, '')
    # go to next block unless the class name matches `lang`
    continue unless extension = extensionForFenceName(fenceName)
    # apply class only if lang match
    $(preElement).addClass("editor-colors")
    text = codeBlock.text()

    grammar = atom.syntax.selectGrammar("foo.#{extension}", text)

    codeBlock.empty()

    for tokens in grammar.tokenizeLines(text).slice(0, -1)
      lineText = _.pluck(tokens, 'value').join('')
      htmlEolInvisibles = ''
      codeBlock.append(EditorView.buildLineHtml({tokens, text: lineText, htmlEolInvisibles}))

  html
