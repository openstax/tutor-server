//= require jquery
//= require best_in_place
//= require jquery_ujs
//= require jquery.datetimepicker
//= require jquery-ui
//= require best_in_place.jquery-ui
//= require bootstrap-sprockets
//= require moment.min
//= require manager

//=============== Date Time Picker ============//
$(document).ready(function() {
  var midnight_today = moment().startOf('day');
  var midnight_tomorrow = midnight_today.clone().add(1, 'day');

  var moment_format = 'YYYY-MM-DD HH:mm:ss';
  var datepicker_format = 'Y-m-d H:i:s';

  $('.datepicker.start').val(midnight_today.format(moment_format));
  $('.datepicker.end'  ).val(midnight_tomorrow.format(moment_format));

  $('.datepicker').datetimepicker({
    format: datepicker_format
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

  //========== Course tab selection =============//
  var tab = window.location.hash;
  if (tab) {
    $('a[href="' + tab + '"]').click();
  }

  //========== Courses table ordering =============//
  $(".courses-table th:not(:first-child)").on("click", function(e){
    var paramsObject = locationSearchInJSON();

    var field = e.target.textContent.toLowerCase();
    if(field.includes("teacher")){
      field = "teacher";
    }

    var toggleOrderBy = function(){
      if(paramsObject.order_by && paramsObject.order_by.includes("desc")){
        paramsObject.order_by = field + " asc";
      } else {
        paramsObject.order_by = field + " desc";
      }
    };

    toggleOrderBy();

    window.location.search = $.param(paramsObject);
  });

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

  //========== Clears course start/end dates when a new Term or Year is selected ==========//
  function clearCourseDates() {
    $('#course_starts_at').prop('value', '');
    $('#course_ends_at').prop('value', '');
  }
  $('#course_term').change(clearCourseDates);
  $('#course_year').change(clearCourseDates);
});
