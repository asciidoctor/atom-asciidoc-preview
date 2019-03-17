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

    task.on 'asciidoctor-load:success', ({blockPositions}) =>
      @blockPositions = blockPositions

    waitsFor (done) -> task.start(done)

    runs =>
      expect(Object.keys @blockPositions).toHaveLength 5
      expect(@blockPositions[1]).toBe '__asciidoctor-preview-0__'
      expect(@blockPositions[3]).toBe '_first_section'
      expect(@blockPositions[5]).toBe '__asciidoctor-preview-1__'
      expect(@blockPositions[8]).toBe '_second_section'
      expect(@blockPositions[10]).toBe '__asciidoctor-preview-2__'

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

    task.on 'asciidoctor-load:success', ({blockPositions}) =>
      @blockPositions = blockPositions

    waitsFor (done) -> task.start(done)

    runs =>
      expect(Object.keys @blockPositions).toHaveLength 7
      expect(@blockPositions[1]).toBe '__asciidoctor-preview-0__'
      expect(@blockPositions[3]).toBe '_first_section'
      expect(@blockPositions[6]).toBe '__asciidoctor-preview-2__'
      expect(@blockPositions[7]).toBe '__asciidoctor-preview-4__'
      expect(@blockPositions[8]).toBe '__asciidoctor-preview-6__'
      expect(@blockPositions[9]).toBe '__asciidoctor-preview-7__'
      expect(@blockPositions[10]).toBe '__asciidoctor-preview-8__'

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

    task.on 'asciidoctor-load:success', ({blockPositions}) =>
      @blockPositions = blockPositions

    waitsFor (done) -> task.start(done)

    runs =>
      expect(Object.keys @blockPositions).toHaveLength 7
      expect(@blockPositions[1]).toBe '__asciidoctor-preview-0__'
      expect(@blockPositions[3]).toBe '_first_section'
      expect(@blockPositions[5]).toBe '__asciidoctor-preview-2__'
      expect(@blockPositions[6]).toBe '__asciidoctor-preview-3__'
      expect(@blockPositions[8]).toBe '__asciidoctor-preview-4__'
      expect(@blockPositions[9]).toBe '__asciidoctor-preview-5__'
      expect(@blockPositions[11]).toBe '__asciidoctor-preview-7__'
