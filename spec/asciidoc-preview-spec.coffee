describe 'AsciiDoc preview', ->
  pack = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage 'asciidoc-preview'
        .then (p) ->
          pack = p

  it 'should load the package', ->
    expect(pack.name).toBe 'asciidoc-preview'
