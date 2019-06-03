asciidoctorRuntimeConfig =
  runtime:
    platform: 'node'
    engine: 'v8'
    framework: 'electron'
Asciidoctor = require('@asciidoctor/core')(asciidoctorRuntimeConfig)
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

  asciidoctorOptions =
    base_dir: options.baseDir
    safe: options.safeMode
    doctype: 'article'
    # Force backend to html5
    backend: 'html5'
    attributes: concatAttributes
    sourcemap: options.scrollMode

  try
    stdStream.hook()
    doc = Asciidoctor.load text, asciidoctorOptions

    if options.scrollMode
      blockPositions = registerBlockPositions doc
      emit 'asciidoctor-load:success', blockPositions: blockPositions

    html = doc.convert()
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
  blockId = 0
  if doc.header?
    # Make sure the document header node and the document node share the same ID.
    if typeof doc.id isnt 'string'
      doc.id = "__asciidoctor-preview-#{blockId}__"
      blockId += 1
    doc.header.id = doc.id

  blocks = doc.findBy((b) -> b.getLineNumber()?)

  linesMapping = {}
  for block in blocks
    id = block.id
    if typeof id isnt 'string'
      id = "__asciidoctor-preview-#{blockId}__"
      blockId += 1
      block.id = id

    lineno = block.getLineNumber()
    linesMapping[lineno] = id

  linesMapping
