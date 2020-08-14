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

  //========== Hides and shows the preview message box when is_preview selected ==========//
  function onIsPreviewChange() {
    const previewFG = $('#offering_preview_message').closest('.form-group');
    if ($('#offering_is_preview_available').is(":checked")) {
      previewFG.show();
    } else {
      previewFG.hide();
    }
  }
  $('#offering_is_preview_available').change(onIsPreviewChange);
  onIsPreviewChange();

  
  //========== Changes the course form when a course offering is selected ==========//
  function updateCourseForm() {
    var offering = $('#course_catalog_offering_id option:selected').first();
    if (offering.prop('value')) {
      $('#course_appearance_code').prop('placeholder', offering.attr('data-appearance_code'));
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

  //========== Demo forms ==========//
  function replaceSearch(key, value) {
    const regex = new RegExp('[$?]' + key + '=[^&?]+');
    const search = window.location.search.replace(regex, '');
    const separator = search ? '&' : '?';
    window.location.search = search + separator + key + '=' + value;
  }

  // Reload config file if the text field or select are changed
  $('#config, #book').change(function() {
    const elt = $(this);
    replaceSearch(elt[0].id, elt.val());
  });

  // Add/remove collection fields
  function removeItem() {
    const item = $(this).parent('.item');
    $('html, body').animate({ scrollTop: item.offset().top - window.innerHeight/2 }, 'fast');
    item.fadeOut('slow', function() {
      item.remove();
    });
    return false;
  }
  $('.collection .add').click(function() {
    const elt = $(this);
    const newItem = elt.siblings('.template').children('.item').last().clone();
    newItem.appendTo(elt.siblings('.list'));
    newItem.hide();
    newItem.find('input').prop("disabled", false);
    newItem.children('.remove').click(removeItem);
    newItem.fadeIn('slow');
    $('html, body').animate({ scrollTop: newItem.offset().top - window.innerHeight/2 }, 'fast');
    return false;
  });

  $('.collection .remove').click(removeItem);
});
