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
      blockPositions = registerBlockPositions doc
      emit 'asciidoctor-load:success', blockPositions: blockPositions

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

registerBlockPositions = (doc) ->
  if doc.header?
    # Make sure the document header node and the document node share the same ID.
    if typeof doc.id isnt 'string'
      doc.id = "__asciidoctor-preview-#{doc.$object_id()}__"
    doc.header.id = doc.id

  # Use Ruby API:
  # because `doc.findBy()` doesn't yet accept a filter function as parameter.
  # https://github.com/asciidoctor/asciidoctor.js/issues/282
  blocks = Opal.block_send doc, 'find_by', (b) -> b.$lineno() isnt Opal.nil

  linesMapping = {}
  for block in blocks
    id = block.id
    if typeof id isnt 'string'
      id = "__asciidoctor-preview-#{block.$object_id()}__"
      block.id = id

    lineno = block.$lineno()
    linesMapping[lineno] = id

  linesMapping
