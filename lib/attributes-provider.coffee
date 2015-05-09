_ = require "underscore-plus"
path = require "path"
fs = require 'fs-plus'

module.exports =
  selector: ".source.asciidoc"
  disableForSelector: ".source.asciidoc .comment.block.asciidoc"
  inclusionPriority: 1
  excludeLowerPriority: true
  filterSuggestions: true

  getSuggestions: ({editor, bufferPosition}) ->
    prefix = @getPrefix(editor, bufferPosition)
    return unless prefix != ""

    pattern = /^:([a-zA-Z_\-!]+):/
    textLines = editor.getText().split(/\n/)
    currentRow = editor.getCursorScreenPosition().row
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

    potentialAttributes = _.map(potentialAttributes, (attribute)->
      value =
        type: "variable"
        text: attribute
        displayText: attribute
        rightLabel: "local"
    )

    asciidocAttr = _.map(@attributes, (attribute, key)->
      value =
          type: "variable"
          text: key
          displayText: key
          rightLabel: "asciidoc"
          description: attribute.description
    )

    potentialAttributes= potentialAttributes.concat asciidocAttr

    potentialAttributes= _.sortBy(potentialAttributes, (_attribute)->
      _attribute.text.toLowerCase()
    )

    new Promise (resolve) ->
      resolve(potentialAttributes)

  getPrefix: (editor, bufferPosition) ->
    # Whatever your prefix regex might be
    regex = /\{(\b\w*[a-zA-Z_\-!]\w*\b)?/g

    # Get the text for the line up to the triggered buffer position
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])

    # Match the regex to the line, and return the match
    line.match(regex)?[0] or ""

  loadCompletions: ->
    @attributes = {}
    fs.readFile path.resolve(__dirname, "..", "completions.json"), (error, content) =>
      {@attributes} = JSON.parse(content) unless error?
      return
