//= require manager
//= require jquery.datetimepicker
//= require codemirror
//= require codemirror/modes/ruby

//=============== Date Time Picker ============//
$(document).on('turbolinks:load', () => {
  var datepicker_format = 'Y-m-d H:i:s';

  $('.datepicker').datetimepicker({
    format: datepicker_format
  });
  $('textarea[data-codemirror]').each(function(i, textArea) {
    CodeMirror.fromTextArea(textArea, {
      lineNumbers: true,
      styleActiveLine: true,
      matchBrackets: true,
      indentUnit: 2,
      tabSize: 2,
      readOnly: "true" == textArea.getAttribute('readOnly'),
      mode: "text/x-ruby",
    });
  })
});
