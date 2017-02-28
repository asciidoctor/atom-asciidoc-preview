{Task} = require 'atom'

describe 'worker', ->

  it 'should generate blocks positions', ->
    options =
      opalPwd: window.location.href

    content = """= Hello world

    == First section

    First paragraph.
    Second paragraph.

    == Second section

    Third paragraph.
    Fourth paragraph."""

    task = Task.once require.resolve('../lib/worker'), content, {}, options

    task.on 'asciidoctor-load:success', ({blocksPositions}) =>
      @blocksPositions = blocksPositions

    waitsFor (done) -> task.start(done)

    runs =>
      expect(@blocksPositions[3]).toBe '_first_section'
      expect(@blocksPositions[5]).toBe 'paragraph_1'
      expect(@blocksPositions[8]).toBe '_second_section'
      expect(@blocksPositions[10]).toBe 'paragraph_2'
