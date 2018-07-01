//= require jquery
//= require jquery_ujs
//= require jquery.datetimepicker
//= require jquery-ui-1.11.4.custom.min
//= require bootstrap-sprockets
//= require manager

//=============== Date Time Picker ============//
$(document).ready(function() {
  var datepicker_format = 'Y-m-d H:i:s';

  $('.datepicker').datetimepicker({
    format: datepicker_format
  });
});
