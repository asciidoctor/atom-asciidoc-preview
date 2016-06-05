path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
AsciiDocPreviewView = require '../lib/asciidoc-preview-view'

describe 'AsciiDocPreviewView', ->
  [file, preview, workspaceElement, originalTimeout] = []

  beforeEach ->
    filePath = atom.project.getDirectories()[0].resolve 'samples/file.adoc'
    preview = new AsciiDocPreviewView {filePath}
    jasmine.attachToDOM preview.element
    originalTimeout = jasmine.getEnv().defaultTimeoutInterval
    jasmine.getEnv().defaultTimeoutInterval = 120000

    waitsForPromise ->
      Promise.all [
        atom.packages.activatePackage 'language-ruby'
        atom.packages.activatePackage 'language-javascript'
        atom.packages.activatePackage 'language-asciidoc'
        atom.packages.activatePackage 'asciidoc-preview'
      ]

  afterEach ->
    preview.destroy()
    jasmine.getEnv().defaultTimeoutInterval = originalTimeout

  describe "::constructor", ->
    it "shows a loading spinner and renders the AsciiDoc document", ->
      preview.showLoading()
      expect(preview.find '.asciidoc-spinner').toExist()

      waitsForPromise ->
        preview.renderAsciiDoc()

      runs ->
        expect(preview.find 'h1').toExist()

    it "shows an error message when there is an error", ->
      preview.showError "Not a real file"
      expect(preview.text()).toContain "Failed"

  describe "serialization", ->
    newPreview = null

    afterEach ->
      newPreview?.destroy()

    it "recreates the preview when serialized/deserialized", ->
      newPreview = atom.deserializers.deserialize preview.serialize()
      jasmine.attachToDOM newPreview.element
      expect(newPreview.getPath()).toBe preview.getPath()

    it "does not recreate a preview when the file no longer exists", ->
      filePath = path.join temp.mkdirSync('asciidoc-preview-'), 'foo.adoc'
      fs.writeFileSync filePath, '= Hi'

      preview.destroy()
      preview = new AsciiDocPreviewView {filePath}
      serialized = preview.serialize()
      fs.removeSync filePath

      newPreview = atom.deserializers.deserialize(serialized)
      expect(newPreview).toBeUndefined()

    it "serializes the editor id when opened for an editor", ->
      preview.destroy()

      waitsForPromise ->
        atom.workspace.open 'new.adoc'

      runs ->
        preview = new AsciiDocPreviewView editorId: atom.workspace.getActiveTextEditor().id

        jasmine.attachToDOM(preview.element)
        expect(preview.getPath()).toBe atom.workspace.getActiveTextEditor().getPath()

        newPreview = atom.deserializers.deserialize preview.serialize()
        jasmine.attachToDOM newPreview.element
        expect(newPreview.getPath()).toBe preview.getPath()

  describe "code block conversion to pre tags", ->
    beforeEach ->
      waitsForPromise ->
        preview.renderAsciiDoc()

    describe "when the code block's fence name has a matching grammar", ->
      it "assigns the grammar", ->
        rubyCode = preview.find 'pre.editor-colors.lang-ruby'
        expect(rubyCode).toExist()
        expect(rubyCode.html()).toBe '<div class="line"><span class="source ruby"><span class="meta function method without-arguments ruby"><span class="keyword control def ruby"><span>def</span></span><span>&nbsp;</span><span class="entity name function ruby"><span>func</span></span></span></span></div><div class="line"><span class="source ruby"><span>&nbsp;&nbsp;x&nbsp;</span><span class="keyword operator assignment ruby"><span>=</span></span><span>&nbsp;</span><span class="constant numeric ruby"><span>1</span></span></span></div><div class="line"><span class="source ruby"><span class="keyword control ruby"><span>end</span></span></span></div>'

  describe "image resolving", ->
    beforeEach ->
      waitsForPromise ->
        preview.renderAsciiDoc()

    describe "when the image uses a relative path", ->
      it "resolves to a path relative to the file", ->
        image = preview.find 'img[alt=Image1]'
        expect(image.attr 'src' ).toBe atom.project.getDirectories()[0].resolve 'samples/image1.png'

    describe "when the image uses an absolute path that does not exist", ->
      it "resolves to a path relative to the project root", ->
        image = preview.find 'img[alt=Image2]'
        expect(image.attr 'src').toBe atom.project.getDirectories()[0].resolve 'tmp/image2.png'

    describe "when the image uses an absolute path that exists", ->
      it "doesn't change the URL", ->
        preview.destroy()

        filePath = path.join temp.mkdirSync('atom'), 'foo.adoc'
        fs.writeFileSync(filePath, "image::#{filePath}[absolute]")
        preview = new AsciiDocPreviewView {filePath}
        jasmine.attachToDOM preview.element

        waitsForPromise ->
          preview.renderAsciiDoc()

        runs ->
          image = preview.find 'img[alt=absolute]'
          expect(image.attr 'src').toBe filePath

    describe "when the image uses a web URL", ->
      it "doesn't change the URL", ->
        image = preview.find 'img[alt=Image3]'
        expect(image.attr 'src').toBe 'http://github.com/image3.png'
