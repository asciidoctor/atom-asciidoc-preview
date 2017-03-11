{Task} = require 'atom'

describe 'worker', ->

  it 'should generate blocks positions', ->
    atom.config.set 'asciidoc-preview.scrollMode', true
    options =
      opalPwd: window.location.href
      scrollMode: true

    content = """= Hello world

    == First section

    First paragraph.
    Second paragraph.

    == Second section

    Third paragraph.
    Fourth paragraph."""

    taskPath = require.resolve('../lib/worker')
    task = Task.once taskPath, content, {}, options

    task.on 'asciidoctor-load:success', ({blocksPositions}) =>
      @blocksPositions = blocksPositions

    waitsFor (done) -> task.start(done)

    runs =>
      expect(@blocksPositions[3]).toBe '_first_section'
      expect(@blocksPositions[5]).toBe 'paragraph_2'
      expect(@blocksPositions[8]).toBe '_second_section'
      expect(@blocksPositions[10]).toBe 'paragraph_4'
