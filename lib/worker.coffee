ajs = require('asciidoctor.js')()
Asciidoctor = ajs.Asciidoctor()
Opal = ajs.Opal
path = require 'path'
stdStream = require './std-stream-hook'

module.exports = (text, attributes, options) ->
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
  ].join(' ').trim()

  Opal.ENV['$[]=']('PWD', path.dirname(options.opalPwd))

  asciidoctorOptions = Opal.hash
    base_dir: options.baseDir
    safe: options.safeMode
    doctype: 'article'
    # Force backend to html5
    backend: 'html5'
    attributes: concatAttributes
    sourcemap: options.scrollMode

  try
    stdStream.hook()
    doc = Asciidoctor.$load text, asciidoctorOptions

    if options.scrollMode
      blocksPositions = registerBlocksPositions doc.$query(), {}, 1
      emit 'asciidoctor-load:success', blocksPositions: blocksPositions

    html = doc.$convert()
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

registerBlocksPositions = (blocks, result, @index) ->
  for block in blocks
    lineno = block.$lineno()

    if typeof lineno is 'number'
      if typeof block.id is 'string'
        id = block.id
      else
        # Set a unique id
        id = "#{block.node_name}_#{index}"
        @index += 1
        block.id = id

      result[lineno] = id

  result
