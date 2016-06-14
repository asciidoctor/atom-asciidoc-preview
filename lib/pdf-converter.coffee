path = require 'path'
opn = require 'opn'

module.exports =

  convert: ({target}) ->
    if atom.config.get 'asciidoc-preview.exportAsPdf.enabled'

      sourceFilePath = target.dataset.path

      cmd = executeAsciiDoctorPdf sourceFilePath

      cmd.stdout.on 'data', (data) ->
        atom.notifications.addInfo 'Export as PDF:', detail: data.toString() or '', dismissable: true

      cmd.stderr.on 'data', (data) ->
        console.error "stderr: #{data}"
        atom.notifications.addError 'Error:', detail: data.toString() or '', dismissable: true

      cmd.on 'close', (code) ->
        basename = path.basename(sourceFilePath, path.extname(sourceFilePath))
        pdfFilePath = path.join(path.dirname(sourceFilePath), basename) + '.pdf'

        if code is 0
          atom.notifications.addSuccess 'Export as PDF completed!', detail: pdfFilePath or '', dismissable: false

          if atom.config.get 'asciidoc-preview.exportAsPdf.openWithExternal'
            opn(pdfFilePath).catch (error) ->
              atom.notifications.addError error.toString(), detail: error?.stack or '', dismissable: true
              console.error error
        else
          atom.notifications.addWarning 'Export as PDF completed with errors.', detail: pdfFilePath or '', dismissable: false

    else
      message = '''
        This feature is experimental.
        You must manually activate this feature in the package settings.
        `asciidoctor-pdf` must be installed in you computer.
        '''
      atom.notifications.addWarning 'Export as PDF:', detail: message or '', dismissable: true

executeAsciiDoctorPdf = (sourceFilePath) ->
  {spawn} = require 'child_process'

  if process.platform is 'win32'
    shell = process.env['SHELL'] or 'cmd.exe'
    spawn 'asciidoctor-pdf.bat', [sourceFilePath], shell: "#{shell} -i -l"
  else
    shell = process.env['SHELL'] or 'bash'
    spawn 'asciidoctor-pdf', [sourceFilePath], shell: "#{shell} -i -l"
