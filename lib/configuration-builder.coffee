path = require 'path'

module.exports =
  makeAttributes: ->
    attributes =
      defaultAttributes: atom.config.get 'asciidoc-preview.defaultAttributes'
      sectnums: sectionNumbering()
      skipFrontMatter: if atom.config.get 'asciidoc-preview.frontMatter' then '' else 'skip-front-matter'
      showTitle: if atom.config.get 'asciidoc-preview.showTitle' then 'showtitle' else 'showtitle!'
      compatMode: if atom.config.get 'asciidoc-preview.compatMode' then 'compat-mode=@' else ''
      forceExperimental: if atom.config.get 'asciidoc-preview.forceExperimental' then 'experimental' else ''
      tocType: calculateTocType()

  makeOptions: (filePath) ->
    options =
      baseDir: (makeBaseDirectory filePath if filePath)
      safeMode: atom.config.get 'asciidoc-preview.safeMode' or 'safe'
      scrollMode: atom.config.get 'asciidoc-preview.scrollMode'

calculateTocType = ->
  tocType = atom.config.get 'asciidoc-preview.tocType'
  if tocType is 'none'
    ''
  else if tocType is 'auto'
    # NOTE: 'auto' (blank option in asciidoctor) is currently not supported but
    # this section is left as a reminder of the expected behaviour
    'toc=toc! toc2!'
  else
    "toc=#{tocType} toc2!"

sectionNumbering = ->
  sectnumsOption = atom.config.get 'asciidoc-preview.sectionNumbering'
  if sectnumsOption is 'always-enabled'
    'sectnums'
  else if sectnumsOption is 'always-disabled'
    'sectnums!'
  else if sectnumsOption is 'enabled-by-default'
    'sectnums=@'
  else
    ''

makeBaseDirectory = (filePath) ->
  baseBir = atom.config.get 'asciidoc-preview.baseDir'
  if baseBir is '{docdir}'
    path.dirname filePath
  else if baseBir isnt '-'
    baseBir
