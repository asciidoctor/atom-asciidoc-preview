{makeAttributes} = require '../lib/attributes-builder'

describe "attributes-builder", ->

  describe "TOC type", ->

    it 'when tocType option is defined to none', ->
      atom.config.set 'asciidoc-preview.tocType', 'none'
      {tocType} = makeAttributes()

      expect(tocType).toBe ''

    it 'when tocType option is defined to preamble', ->
      atom.config.set 'asciidoc-preview.tocType', 'preamble'
      {tocType} = makeAttributes()

      expect(tocType).toBe 'toc=preamble toc2!'

    it 'when tocType option is defined to macro', ->
      atom.config.set 'asciidoc-preview.tocType', 'macro'
      {tocType} = makeAttributes()

      expect(tocType).toBe 'toc=macro toc2!'

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
      {skipFrontMatter} = makeAttributes()

      expect(skipFrontMatter).toBeFalsy()

    it 'when frontMatter option is defined to false', ->
      atom.config.set 'asciidoc-preview.frontMatter', false
      {skipFrontMatter} = makeAttributes()

      expect(skipFrontMatter).toBeTruthy()

  describe "Show title", ->

    it 'when showTitle option is defined to true', ->
      atom.config.set 'asciidoc-preview.showTitle', true
      {showTitle} = makeAttributes()

      expect(showTitle).toBe 'showtitle'

    it 'when showTitle option is defined to false', ->
      atom.config.set 'asciidoc-preview.showTitle', false
      {showTitle} = makeAttributes()

      expect(showTitle).toBe 'showtitle!'

  describe "Compat mode", ->

    it 'when compatMode option is defined to true', ->
      atom.config.set 'asciidoc-preview.compatMode', true
      {compatMode} = makeAttributes()

      expect(compatMode).toBe 'compat-mode=@'

    it 'when compatMode option is defined to false', ->
      atom.config.set 'asciidoc-preview.compatMode', false
      {compatMode} = makeAttributes()

      expect(compatMode).toBe ''

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
      {safeMode} = makeAttributes()

      expect(safeMode).toBe 'unsafe'

    it 'when safeMode option is defined to safe', ->
      atom.config.set 'asciidoc-preview.safeMode', 'safe'
      {safeMode} = makeAttributes()

      expect(safeMode).toBe 'safe'

    it 'when safeMode option is defined to server', ->
      atom.config.set 'asciidoc-preview.safeMode', 'server'
      {safeMode} = makeAttributes()

      expect(safeMode).toBe 'server'

    it 'when safeMode option is defined to secure', ->
      atom.config.set 'asciidoc-preview.safeMode', 'secure'
      {safeMode} = makeAttributes()

      expect(safeMode).toBe 'secure'

  describe "opalPwd", ->

    it 'should opalPwd be defined', ->
      {opalPwd} = makeAttributes()

      expect(opalPwd).toBeDefined()
