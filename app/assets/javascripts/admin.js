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

  //========== Disable is_concept_coach checkbox when a course offering is selected ==========//
  function updateIsConceptCoachCheckbox() {
    selected = $('#profile_catalog_offering_id option:selected').first();
    if (selected.prop('value')) {
      $('#profile_appearance_code').prop('placeholder', selected.attr('data-appearance_code'));
      $('#profile_is_concept_coach').prop('disabled', true);
      $('#profile_is_concept_coach').prop('checked',
                                         selected.attr('data-is_concept_coach') == '1');
    }
    else {
      $('#profile_appearance_code').prop('placeholder', '');
      $('#profile_is_concept_coach').prop('disabled', false);
    }
  }
  $('#profile_catalog_offering_id').change(updateIsConceptCoachCheckbox);
  updateIsConceptCoachCheckbox();
});
