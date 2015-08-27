//= require jquery
//= require jquery_ujs
//= require jquery.datetimepicker
//= require jquery-ui-1.11.4.custom.min
//= require bootstrap-sprockets

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
        data: {search_term: searchParam},
        type: 'GET',
        beforeSend: function(xhr) {
          xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
        },
        success: function(data) {
          response($.map(data.items, function(item) {
            return {
              label: item.name + ' (' + item.username + ')',
              value: item.entity_user_id
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
});

// === Admin/Jobs === //
$(function(){
  $(document).on('click', '.filter_job_status', function(e) {
    var desiredStatus = this.href.replace(/^\S+#/, ''),
        $showRows = $('.' + desiredStatus),
        $hideRows = $('#jobs tr').not('.' + desiredStatus);

    if (desiredStatus === 'all') {
      $showRows = $('#jobs tr');
      $hideRows = $();
    } else if (desiredStatus === 'incomplete') {
      $showRows = $('#jobs tr').not('.completed');
      $hideRows = $('.completed');
    }

    $showRows.show();
    $hideRows.hide();
  });
});
