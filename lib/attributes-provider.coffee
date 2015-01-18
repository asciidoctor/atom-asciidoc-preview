{Range}  = require "atom"
fuzzaldrin = require "fuzzaldrin"
_ = require "underscore-plus"

module.exports =
ProviderClass: (Provider, Suggestion) ->
  class AttributesProvider extends Provider
    wordRegex: /\{(\b\w*[a-zA-Z_\-!]\w*\b)?/g
    exclusive: true

    buildSuggestions: ->
      selection = @editor.getSelection()
      prefix = @prefixOfSelection selection
      return unless prefix.length

      suggestions = @findSuggestionsForPrefix prefix
      return unless suggestions.length
      return suggestions

    findSuggestionsForPrefix: (prefix) ->
      prefix = prefix.replace /^\{/, ''

      pattern = /^:([a-zA-Z_\-!]+):/
      textLines = @editor.getText().split(/\n/)
      currentRow = @editor.getCursorScreenRow()
      counter = 0

      potentialAttributes = _.chain(textLines)
        .filter((line) ->
            counter++
            pattern.test(line) && counter<=currentRow)
        .map((rawAttribute) ->
            pattern.exec(rawAttribute)[1]
          )
        .uniq()
        .value()

      potentialAttributes= potentialAttributes
        .concat ['lt', 'gt', 'amp', 'startsb', 'endsb', 'vbar', 'caret', 'asterisk']
        .concat ['tilde', 'apostrophe', 'backslash', 'backtick', 'two-colons', 'two-semicolons']
        .concat ['empty', 'sp', 'space', 'nbsp', 'zwsp', 'wj', 'apos', 'quot', 'lsquo', 'rsquo']
        .concat ['ldquo', 'rdquo', 'deg', 'plus', 'brvbar']
        .concat ['asciidoctor-version', 'backend', 'docdate', 'docdatetime', 'docdir', 'docfile', 'doctime']
        .concat ['doctitle', 'doctype', 'localdate', 'localdatetime', 'localtime']

      potentialAttributes= _.sortBy(potentialAttributes)

      # Filter the words using fuzzaldrin
      words = fuzzaldrin.filter potentialAttributes, prefix

      # Builds suggestions for the words
      suggestions = for word in words when word isnt prefix
        new Suggestion this, word: word, prefix: prefix, label: "{#{word}} - Asciidoc"

      return suggestions

    confirm: (suggestion) ->
      selection = @editor.getSelection()
      startPosition = selection.getBufferRange().start
      buffer = @editor.getBuffer()

      # Replace the prefix with the body
      cursorPosition = @editor.getCursorBufferPosition()
      buffer.delete Range.fromPointWithDelta(cursorPosition, 0, -suggestion.prefix.length)
      @editor.insertText "#{suggestion.word}"

      # Move the cursor behind the body
      suffixLength = suggestion.word.length - suggestion.prefix.length + 1
      @editor.setSelectedBufferRange [startPosition, [startPosition.row, startPosition.column + suffixLength]]

      return false # Don't fall back to the default behavior
