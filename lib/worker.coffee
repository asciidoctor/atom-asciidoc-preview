ajs = require('asciidoctor.js')()
Asciidoctor = ajs.Asciidoctor()
Opal = ajs.Opal
path = require 'path'

module.exports = (text, attributes, filePath) ->
  callback = @async()

  concatAttributes = [
    attributes.defaultAttributes
    'icons=font@'
    attributes.numbered
    attributes.skipfrontmatter
    attributes.showtitle
    attributes.compatmode
    attributes.toctype
    attributes.forceExperimental
  ].join ' '

  folder = path.dirname(filePath)

  Opal.ENV['$[]=']('PWD', path.dirname(attributes.opalPwd))

  options = Opal.hash
    base_dir: folder
    safe: attributes.safemode
    doctype: 'article'
    # Force backend to html5
    backend: 'html5'
    attributes: concatAttributes.trim()

  html = Asciidoctor.$convert text, options
  callback html
