//= require jquery
//= require best_in_place
//= require jquery_ujs
//= require jquery.datetimepicker
//= require jquery-ui-1.11.4.custom.min
//= require best_in_place.jquery-ui
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
