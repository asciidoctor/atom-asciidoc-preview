{makeAttributes} = require '../lib/attributes-builder'

describe "attributes-builder", ->

  describe "TOC type", ->

    it 'when tocType option is defined to none', ->
      atom.config.set 'asciidoc-preview.tocType', 'none'
      {toctype} = makeAttributes()

      expect(toctype).toBe ''

    it 'when tocType option is defined to preamble', ->
      atom.config.set 'asciidoc-preview.tocType', 'preamble'
      {toctype} = makeAttributes()

      expect(toctype).toBe 'toc=preamble toc2!'

    it 'when tocType option is defined to macro', ->
      atom.config.set 'asciidoc-preview.tocType', 'macro'
      {toctype} = makeAttributes()

      expect(toctype).toBe 'toc=macro toc2!'

  describe "Section numbering", ->

    it 'when sectionNumbering option is defined to enabled-by-default', ->
      atom.config.set 'asciidoc-preview.sectionNumbering', 'enabled-by-default'
      {numbered} = makeAttributes()

      expect(numbered).toBe 'sectnums=@'

    it 'when sectionNumbering option is defined to always-enabled', ->
      atom.config.set 'asciidoc-preview.sectionNumbering', 'always-enabled'
      {numbered} = makeAttributes()

      expect(numbered).toBe 'sectnums'

    it 'when sectionNumbering option is defined to always-disabled', ->
      atom.config.set 'asciidoc-preview.sectionNumbering', 'always-disabled'
      {numbered} = makeAttributes()

      expect(numbered).toBe 'sectnums!'

    it 'when sectionNumbering option is defined to not-specified', ->
      atom.config.set 'asciidoc-preview.sectionNumbering', 'not-specified'
      {numbered} = makeAttributes()

      expect(numbered).toBe ''

  describe "Default attributes", ->

    it 'when defaultAttributes option is defined', ->
      atom.config.set 'asciidoc-preview.defaultAttributes', 'asciidoctor options'
      {defaultAttributes} = makeAttributes()

      expect(defaultAttributes).toBe 'asciidoctor options'

  describe "Front matter", ->

    it 'when frontMatter option is defined to true', ->
      atom.config.set 'asciidoc-preview.frontMatter', true
      {skipfrontmatter} = makeAttributes()

      expect(skipfrontmatter).toBeFalsy()

    it 'when frontMatter option is defined to false', ->
      atom.config.set 'asciidoc-preview.frontMatter', false
      {skipfrontmatter} = makeAttributes()

      expect(skipfrontmatter).toBeTruthy()

  describe "Show title", ->

    it 'when showTitle option is defined to true', ->
      atom.config.set 'asciidoc-preview.showTitle', true
      {showtitle} = makeAttributes()

      expect(showtitle).toBe 'showtitle'

    it 'when showTitle option is defined to false', ->
      atom.config.set 'asciidoc-preview.showTitle', false
      {showtitle} = makeAttributes()

      expect(showtitle).toBe 'showtitle!'

  describe "Compat mode", ->

    it 'when compatMode option is defined to true', ->
      atom.config.set 'asciidoc-preview.compatMode', true
      {compatmode} = makeAttributes()

      expect(compatmode).toBe 'compat-mode=@'

    it 'when compatMode option is defined to false', ->
      atom.config.set 'asciidoc-preview.compatMode', false
      {compatmode} = makeAttributes()

      expect(compatmode).toBe ''

  describe "Force experimental", ->

    it 'when forceExperimental option is defined to true', ->
      atom.config.set 'asciidoc-preview.forceExperimental', true
      {forceExperimental} = makeAttributes()

      expect(forceExperimental).toBe 'experimental'

    it 'when forceExperimental option is defined to false', ->
      atom.config.set 'asciidoc-preview.forceExperimental', false
      {forceExperimental} = makeAttributes()

      expect(forceExperimental).toBe ''

  describe "Safe mode", ->

    it 'when safeMode option is defined to unsafe', ->
      atom.config.set 'asciidoc-preview.safeMode', 'unsafe'
      {safemode} = makeAttributes()

      expect(safemode).toBe 'unsafe'

    it 'when safeMode option is defined to safe', ->
      atom.config.set 'asciidoc-preview.safeMode', 'safe'
      {safemode} = makeAttributes()

      expect(safemode).toBe 'safe'

    it 'when safeMode option is defined to server', ->
      atom.config.set 'asciidoc-preview.safeMode', 'server'
      {safemode} = makeAttributes()

      expect(safemode).toBe 'server'

    it 'when safeMode option is defined to secure', ->
      atom.config.set 'asciidoc-preview.safeMode', 'secure'
      {safemode} = makeAttributes()

      expect(safemode).toBe 'secure'

  describe "opalPwd", ->

    it 'should opalPwd be defined', ->
      {opalPwd} = makeAttributes()

      expect(opalPwd).toBeDefined()
