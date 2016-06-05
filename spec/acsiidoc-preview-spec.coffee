path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
fse = require 'fs-extra'
{$} = require 'atom-space-pen-views'
AsciidocPreviewView = require '../lib/asciidoc-preview-view'

describe "Asciidoc preview package", ->
  [workspaceElement, preview, originalTimeout] = []

  beforeEach ->
    fixturesPath = path.join(__dirname, 'fixtures')
    tempPath = temp.mkdirSync('atom')

    fse.copySync(fixturesPath, tempPath, clobber: true)
    atom.project.setPaths([tempPath])

    originalTimeout = jasmine.getEnv().defaultTimeoutInterval
    jasmine.getEnv().defaultTimeoutInterval = 120000
    jasmine.useRealClock()

    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    waitsForPromise ->
      Promise.all [
        atom.packages.activatePackage('language-asciidoc')
        atom.packages.activatePackage('asciidoc-preview')
      ]

  afterEach ->
    jasmine.getEnv().defaultTimeoutInterval = originalTimeout

  expectPreviewInSplitPane = ->
    runs ->
      expect(atom.workspace.getPanes()).toHaveLength 2

    waitsFor "Asciidoc preview to be created", ->
      preview = atom.workspace.getPanes()[1].getActiveItem()

    runs ->
      expect(preview).toBeInstanceOf(AsciidocPreviewView)
      expect(preview.getPath()).toBe atom.workspace.getActivePaneItem().getPath()

  describe "when a preview has not been created for the file", ->
    it "displays a Asciidoc preview in a split pane", ->
      waitsForPromise -> atom.workspace.open("samples/file.adoc")
      runs -> atom.commands.dispatch workspaceElement, 'asciidoc-preview:toggle'
      expectPreviewInSplitPane()

      runs ->
        [editorPane] = atom.workspace.getPanes()
        expect(editorPane.getItems()).toHaveLength 1
        expect(editorPane.isActive()).toBe true

    describe "when the editor's path does not exist", ->
      it "splits the current pane to the right with a Asciidoc preview for the file", ->
        waitsForPromise -> atom.workspace.open("new.adoc")
        runs -> atom.commands.dispatch workspaceElement, 'asciidoc-preview:toggle'
        expectPreviewInSplitPane()

    describe "when the editor does not have a path", ->
      it "splits the current pane to the right with a Asciidoc preview for the file", ->
        waitsForPromise -> atom.workspace.open("")
        runs -> atom.commands.dispatch workspaceElement, 'asciidoc-preview:toggle'
        expectPreviewInSplitPane()

    describe "when the path contains a space", ->
      it "renders the preview", ->
        waitsForPromise -> atom.workspace.open("samples/file with space.adoc")
        runs -> atom.commands.dispatch workspaceElement, 'asciidoc-preview:toggle'
        expectPreviewInSplitPane()

    describe "when the path contains accented characters", ->
      it "renders the preview", ->
        waitsForPromise -> atom.workspace.open("samples/áccéntéd.adoc")
        runs -> atom.commands.dispatch workspaceElement, 'asciidoc-preview:toggle'
        expectPreviewInSplitPane()

  describe "when a preview has been created for the file", ->
    beforeEach ->
      waitsForPromise -> atom.workspace.open("samples/file.adoc")
      runs -> atom.commands.dispatch workspaceElement, 'asciidoc-preview:toggle'
      expectPreviewInSplitPane()

    it "closes the existing preview when toggle is triggered a second time on the editor", ->
      atom.commands.dispatch workspaceElement, 'asciidoc-preview:toggle'

      [editorPane, previewPane] = atom.workspace.getPanes()
      expect(editorPane.isActive()).toBe true
      expect(previewPane.getActiveItem()).toBeUndefined()

    it "closes the existing preview when toggle is triggered on it and it has focus", ->
      [editorPane, previewPane] = atom.workspace.getPanes()
      previewPane.activate()

      atom.commands.dispatch workspaceElement, 'asciidoc-preview:toggle'
      expect(previewPane.getActiveItem()).toBeUndefined()

    describe "when the editor is modified", ->

      it "invokes ::onDidChangeAsciidoc listeners", ->
        asciidocEditor = atom.workspace.getActiveTextEditor()
        preview.onDidChangeAsciidoc(listener = jasmine.createSpy('didChangeAsciiDocListener'))

        runs ->
          asciidocEditor.setText("Hey!")

        waitsFor "::onDidChangeAsciidoc handler to be called", ->
          listener.callCount > 0

      describe "when the preview is in the active pane but is not the active item", ->
        it "re-renders the preview but does not make it active", ->
          asciidocEditor = atom.workspace.getActiveTextEditor()
          previewPane = atom.workspace.getPanes()[1]
          previewPane.activate()

          waitsForPromise ->
            atom.workspace.open()

          runs ->
            asciidocEditor.setText("Hey!")

          waitsFor ->
            preview.text().indexOf("Hey!") >= 0

          runs ->
            expect(previewPane.isActive()).toBe true
            expect(previewPane.getActiveItem()).not.toBe preview

      describe "when the preview is not the active item and not in the active pane", ->
        it "re-renders the preview and makes it active", ->
          asciidocEditor = atom.workspace.getActiveTextEditor()
          [editorPane, previewPane] = atom.workspace.getPanes()
          previewPane.splitRight(copyActiveItem: true)
          previewPane.activate()

          waitsForPromise ->
            atom.workspace.open()

          runs ->
            editorPane.activate()
            asciidocEditor.setText("Hey!")

          waitsFor ->
            preview.text().indexOf("Hey!") >= 0

          runs ->
            expect(editorPane.isActive()).toBe true
            expect(previewPane.getActiveItem()).toBe preview

      describe "when the renderOnSaveOnly config is set to false", ->
        it "only re-renders the AsciiDoc when the editor is saved, not when the contents are modified", ->
          atom.config.set 'asciidoc-preview.renderOnSaveOnly', false

          didStopChangingHandler = jasmine.createSpy('didStopChangingHandler')
          atom.workspace.getActiveTextEditor().getBuffer().onDidStopChanging didStopChangingHandler
          atom.workspace.getActiveTextEditor().setText('ch ch changes')

          waitsFor ->
            didStopChangingHandler.callCount > 0

          runs ->
            expect(preview.text()).not.toContain("ch ch changes")
            atom.workspace.getActiveTextEditor().save()

          waitsFor ->
            preview.text().indexOf("ch ch changes") >= 0

  describe "when the AsciiDoc preview view is requested by file URI", ->

    it "opens a preview editor and watches the file for changes", ->

      waitsForPromise "atom.workspace.open promise to be resolved", ->
        atom.workspace.open "asciidoc-preview://#{atom.project.getDirectories()[0].resolve('samples/file.adoc')}"

      runs ->
        preview = atom.workspace.getActivePaneItem()
        expect(preview).toBeInstanceOf(AsciidocPreviewView)

        spyOn(preview, 'renderAsciiDocText')
        preview.file.emitter.emit 'did-change'

      waitsFor "AsciiDoc to be re-rendered after file changed", ->
        preview.renderAsciiDocText.callCount > 0

  describe "when the editor's grammar it not enabled for preview", ->

    it "does not open the AsciiDoc preview", ->
      atom.config.set 'asciidoc-preview.grammars', []

      waitsForPromise ->
        atom.workspace.open "samples/file.adoc"

      runs ->
        spyOn(atom.workspace, 'open').andCallThrough()
        atom.commands.dispatch workspaceElement, 'asciidoc-preview:toggle'
        expect(atom.workspace.open).not.toHaveBeenCalled()

  describe "when the editor's path changes on #win32 and #darwin", ->
    it "updates the preview's title", ->
      titleChangedCallback = jasmine.createSpy('titleChangedCallback')

      waitsForPromise -> atom.workspace.open("samples/file.adoc")
      runs -> atom.commands.dispatch workspaceElement, 'asciidoc-preview:toggle'

      expectPreviewInSplitPane()

      runs ->
        expect(preview.getTitle()).toBe 'file.adoc Preview'
        preview.onDidChangeTitle(titleChangedCallback)
        editorPath = atom.workspace.getActiveTextEditor().getPath()
        fs.renameSync(editorPath, path.join(path.dirname(editorPath), 'file2.adoc'))

      waitsFor ->
        preview.getTitle() is "file2.adoc Preview"

      runs ->
        expect(titleChangedCallback).toHaveBeenCalled()

  describe "when the URI opened does not have a asciidoc-preview protocol", ->
    it "does not throw an error trying to decode the URI (regression)", ->
      waitsForPromise ->
        atom.workspace.open('%')

      runs ->
        expect(atom.workspace.getActiveTextEditor()).toBeTruthy()
