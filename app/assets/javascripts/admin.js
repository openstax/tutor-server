//= require jquery
//= require jquery_ujs
//= require jquery.datetimepicker
//= require jquery-ui-1.11.4.custom.min
//= require bootstrap-sprockets
//= require manager

//=============== Date Time Picker ============//
$(document).ready(function() {
  $('.datepicker').datetimepicker({
  });
});

//============= Courses =================//
$(document).ready(function() {
  //=========== Course teacher auto complete ==============//
  $('#course_teacher').autocomplete({
    autoFocus: true,
    minLength: 2,
    select: function(event_, ui) {
      $('#course_teacher').val(ui.item.label);
      var hidden = $('<input type="hidden" name="teacher_ids[]"/>');
      hidden.val(ui.item.value);
      $('#course_teacher').after(hidden);
      $('#assign-teachers-form').submit();
      return false;
    },
    source: function(request, response, url) {
      var searchParam = request.term;
      $.ajax({
        url: '/admin/users.json',
        data: {query: searchParam},
        type: 'GET',
        beforeSend: function(xhr) {
          xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
        },
        success: function(data) {
          response($.map(data.items, function(item) {
            return {
              label: item.name + ' (' + item.username + ')',
              value: item.id
            };
          }));
        }
      });
    }
  });

  //========== Course select all / deselect all ==========//
  $('#courses_select_all').change(function(e) {
    if ($(this).is(':checked')) {
      $('.course_id_select').prop('checked', true);
    } else {
      $('.course_id_select').prop('checked', false);
    }
  });

  $('.course_id_select').change(function(e) {
    if ($('.course_id_select:checked').length == $('.course_id_select').length) {
      $('#courses_select_all').prop('checked', true);
    } else {
      $('#courses_select_all').prop('checked', false);
    }
  });

  //========== Course tab selection =============//
  var tab = window.location.hash;
  if (tab) {
    $('a[href="' + tab + '"]').click();
  }

  //========== Changes the course form when a course offering is selected ==========//
  function updateCourseForm() {
    var offering = $('#course_catalog_offering_id option:selected').first();
    if (offering.prop('value')) {
      $('#course_appearance_code').prop('placeholder', offering.attr('data-appearance_code'));
      $('#course_is_concept_coach').prop('disabled', true);
      $('#course_is_concept_coach').prop('checked',
                                         offering.attr('data-is_concept_coach') == '1');
    }
    else {
      $('#course_appearance_code').prop('placeholder', '');
      $('#course_is_concept_coach').prop('disabled', false);
    }
  }
  $('#course_catalog_offering_id').change(updateCourseForm);
  updateCourseForm();
});
