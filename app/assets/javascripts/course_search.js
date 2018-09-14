$(document).ready(function() {
  //========== Course select all / deselect all ==========//
  $('#courses_select_all_on_page').change(function(e) {
    if ($(this).is(':checked')) {
      $('.course_id_select').prop('checked', true);
    } else {
      $('.course_id_select').prop('checked', false);
      $('#courses_select_all_on_all_pages').prop('checked', false);
    }
  });

  $('#courses_select_all_on_all_pages').change(function(e) {
    if ($(this).is(':checked')) {
      $('#courses_select_all_on_page').prop('checked', true).trigger('change');
    } else {
      $('#courses_select_all_on_page').prop('checked', false).trigger('change');
    }
  });

  $('.course_id_select').change(function(e) {
    if ($('.course_id_select:checked').length == $('.course_id_select').length) {
      $('#courses_select_all_on_page').prop('checked', true);
    } else {
      $('#courses_select_all_on_page').prop('checked', false);
      $('#courses_select_all_on_all_pages').prop('checked', false);
    }
  });
});
