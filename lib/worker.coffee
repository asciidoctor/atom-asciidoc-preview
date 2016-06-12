ajs = require('asciidoctor.js')()
Asciidoctor = ajs.Asciidoctor()
Opal = ajs.Opal
path = require 'path'
stdStream = require './std-stream-hook'

module.exports = (text, attributes, filePath) ->
  callback = @async()

  concatAttributes = [
    attributes.defaultAttributes
    'icons=font@'
    attributes.numbered
    attributes.skipFrontMatter
    attributes.showTitle
    attributes.compatMode
    attributes.tocType
    attributes.forceExperimental
  ].join ' '

  folder = path.dirname(filePath)

  Opal.ENV['$[]=']('PWD', path.dirname(attributes.opalPwd))

  options = Opal.hash
    base_dir: folder
    safe: attributes.safeMode
    doctype: 'article'
    # Force backend to html5
    backend: 'html5'
    attributes: concatAttributes.trim()

  try
    stdStream.hook()
    html = Asciidoctor.$convert text, options
    stdStream.restore()
    emit 'asciidoctor-render:success', html: html
  catch error
    console.error error
    {code, errno, syscall, stack} = error
    console.error stack
    emit 'asciidoctor-render:error',
      code: code
      errno: errno
      syscall: syscall
      stack: stack

  callback()
