//= require jquery
//= require jquery_ujs
//= require jquery.datetimepicker
//= require jquery-ui-1.11.4.custom.min
//= require bootstrap-sprockets
//= require codemirror
//= require codemirror/modes/ruby
//= require manager

//=============== Date Time Picker ============//
$(document).ready(function() {
  var datepicker_format = 'Y-m-d H:i:s';

  $('.datepicker').datetimepicker({
    format: datepicker_format
  });
  $('textarea[data-codemirror]').each((i, textArea) => {
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
