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
  $('#course_teacher').autocomplete({
    minLength: 2,
    select: function(event_, ui) {
      var hidden = $('<input type="hidden" name="course[teacher_ids][]"/>');
      hidden.val(ui.item.value);
      var label = $('<label>');
      label.text(ui.item.label);
      var remove = $('<button class="btn btn-default btn-xs">');
      remove.text('remove');
      remove.click(function() {
        $(this).parent().detach();
        return false;
      });
      var li = $('<li>');
      li.append(hidden).append(label).append('&nbsp;&nbsp;').append(remove);
      $('#assigned-teachers').append(li);
      $('#course_teacher').val('');
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
              label: item.full_name + ' (' + item.username + ')',
              value: item.id
            };
          }));
        }
      });
    }
  });
});
