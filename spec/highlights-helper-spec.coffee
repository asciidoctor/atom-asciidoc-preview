{scopeForFenceName} = require '../lib/highlights-helper'

describe 'Highlights helper', ->

  it 'should return grammar name "source.shell" when fence name is "bash"', ->
    scope = scopeForFenceName('bash')
    expect(scope).toBe 'source.shell'
