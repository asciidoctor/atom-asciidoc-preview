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
      blocksPositions = registerBlocksPositions doc
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

registerBlocksPositions = (doc) ->
  # Use Ruby API:
  # because `doc.findBy()`` doesn't yet accept a filter function as a parameter.
  # https://github.com/asciidoctor/asciidoctor.js/issues/282
  blocks = Opal.block_send doc, 'find_by', (b) -> b.$lineno() isnt Opal.nil

  linesMapping = {}
  for block, index in blocks
    lineno = block.$lineno()

    if typeof block.id is 'string'
      id = block.id
    else
      # Set a unique id
      id = "#{block.node_name}_#{index}"
      block.id = id

    linesMapping[lineno] = id

  linesMapping
