# Hook to prevent errors occurs on Windows with Asciidoctor.js when syntax within a document is invalid.
# See #159 and #174.
#
module.exports =
  oldStdoutWrite: process.stdout.write
  oldStderrWrite: process.stderr.write

  hook: ->
    if process.platform is 'win32'
      process.stdout.write = (string, encoding, fd) -> console.log string
      process.stderr.write = (string, encoding, fd) -> console.error string

  restore: ->
    if process.platform is 'win32'
      process.stdout.write = @oldStdoutWrite
      process.stderr.write = @oldStderrWrite
