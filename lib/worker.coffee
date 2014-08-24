ajs = require('asciidoctor.js')()
Asciidoctor = ajs.Asciidoctor()
Opal = ajs.Opal
path = require 'path'

module.exports = (text, attributes, filePath) ->

  concatAttributes = attributes.defaultAttributes.concat(' icons=font@ ').concat(attributes.numbered).concat(' ').concat(attributes.showtitle).concat(' ').concat(attributes.showtoc)
  folder = path.dirname(filePath)
  Opal.ENV['$[]=']("PWD", path.dirname(attributes.opalPwd))
  opts = Opal.hash2(['base_dir', 'safe', 'doctype', 'attributes'], {
      'base_dir': 'file://'.concat(folder),
      'safe': attributes.safemode,
      'doctype': attributes.doctype,
      'attributes': concatAttributes
  });
  html = Asciidoctor.$convert(text, opts)
  callback = @async()
  callback(html)
