//= require jquery
//= require jquery_ujs
//= require jquery.datetimepicker
//= require jquery-ui-1.11.4.custom.min

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
      var checkbox = $('<input type="checkbox" name="course[teacher_ids][]"/>');
      checkbox.val(ui.item.value);
      checkbox.attr('checked', true);
      checkbox.attr('id', 'checkbox-' + Date.now());
      var label = $('<label>');
      label.text(ui.item.label);
      label.attr('for', checkbox.attr('id'));
      var li = $('<li>');
      li.append(checkbox).append(label);
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
              label: item.full_name,
              value: item.id
            };
          }));
        }
      });
    }
  });
});
