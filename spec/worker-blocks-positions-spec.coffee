{Task} = require 'atom'

describe 'worker when the scroll mode is activated', ->
  [options, taskPath] = []

  beforeEach ->
    atom.config.set 'asciidoc-preview.scrollMode', true
    options =
      opalPwd: window.location.href
      scrollMode: true

    taskPath = require.resolve('../lib/worker')

  it 'should generate blocks positions when contains sections', ->
    content = '''
      = Hello world

      == First section

      First paragraph.
      Second paragraph.

      == Second section

      Third paragraph.
      Fourth paragraph.
      '''

    task = Task.once taskPath, content, {}, options

    task.on 'asciidoctor-load:success', ({blocksPositions}) =>
      @blocksPositions = blocksPositions

    waitsFor (done) -> task.start(done)

    runs =>
      expect(Object.keys @blocksPositions).toHaveLength 5
      expect(@blocksPositions[1]).toBe '__asciidoctor-preview-420__'
      expect(@blocksPositions[3]).toBe '_first_section'
      expect(@blocksPositions[5]).toBe '__asciidoctor-preview-464__'
      expect(@blocksPositions[8]).toBe '_second_section'
      expect(@blocksPositions[10]).toBe '__asciidoctor-preview-480__'

  it 'should generate blocks positions when document contains item list.', ->
    content = '''
      = Hello world

      == First section

      .Unordered list title
      * list item 1
      ** nested list item
      *** nested nested list item 1
      *** nested nested list item 2
      * list item 2
      '''

    task = Task.once taskPath, content, {}, options

    task.on 'asciidoctor-load:success', ({blocksPositions}) =>
      @blocksPositions = blocksPositions

    waitsFor (done) -> task.start(done)

    runs =>
      expect(Object.keys @blocksPositions).toHaveLength 5
      expect(@blocksPositions[1]).toBe '__asciidoctor-preview-420__'
      expect(@blocksPositions[3]).toBe '_first_section'
      expect(@blocksPositions[6]).toBe '__asciidoctor-preview-468__'
      expect(@blocksPositions[7]).toBe '__asciidoctor-preview-492__'
      expect(@blocksPositions[8]).toBe '__asciidoctor-preview-512__'

  it 'should generate blocks positions when document contains definition list.', ->
    content = '''
      = Hello world

      == First section

      A term::
        The corresponding definition of the term.

      Another term::
        The corresponding definition of the term.

      Another term again:: The corresponding definition of the term.
      '''

    task = Task.once taskPath, content, {}, options

    task.on 'asciidoctor-load:success', ({blocksPositions}) =>
      @blocksPositions = blocksPositions

    waitsFor (done) -> task.start(done)

    runs =>
      # { 1 : '__asciidoctor-preview-420__', 3 : '_first_section', 5 : '__asciidoctor-preview-466__' }
      expect(Object.keys @blocksPositions).toHaveLength 3
      expect(@blocksPositions[1]).toBe '__asciidoctor-preview-420__'
      expect(@blocksPositions[3]).toBe '_first_section'
      expect(@blocksPositions[5]).toBe '__asciidoctor-preview-466__'
