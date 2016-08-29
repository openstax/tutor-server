//= require jquery
//= require jquery.stickytableheaders.min

// === Manager/Jobs === //
$(function(){
  $(document).on('click', '.filter_job_status', function(e) {
    var desiredStatus = this.href.replace(/^\S+#/, ''),
        $showRows = $('.' + desiredStatus),
        $hideRows = $('#jobs tbody tr').not('.' + desiredStatus),
        $plainTxt = $('<span/>').text(desiredStatus),
        $prevSpan = $($(this).siblings('span')[0]),
        prevSpanTxt = $prevSpan.text(),
        $linkedTxt = $('<a/>').addClass('filter_job_status')
                              .text(prevSpanTxt)
                              .attr('href', '#' + prevSpanTxt);

    if (desiredStatus === 'all') {
      $showRows = $('#jobs tbody tr');
      $hideRows = $();
    } else if (desiredStatus === 'incomplete') {
      $showRows = $('#jobs tbody tr').not('.succeeded');
      $hideRows = $('.succeeded');
    }

    $prevSpan.replaceWith($linkedTxt);
    $(this).replaceWith($plainTxt);
    $showRows.show();
    $hideRows.hide();
  }).on('keyup', '#filter_id', function(e) {
    var span = $(this).siblings('span')[0];

    if ($(this).val() !== '' && span === undefined) {
      var placeholder = $(this).attr('placeholder'),
          $label = $('<span/>').text(placeholder);

      $('#search_by_id').prepend($label);
    }

    if ($(this).val() === '') {
      $(span).remove();
    }

    $('#jobs tbody tr').hide();
    $("#jobs tbody tr:contains('" + $(this).val() + "')").show();
  });
});

$(document).ready(function() {
  $('[data-toggle="popover"]').popover();
  $('table.concept-coach-stats').stickyTableHeaders();

  //========== Searh bar show only on List of Courses tab =============//
  $(".admin ul li a").click(function(e){
    var href = e.target.href;
    if (href.includes("#incomplete") || href.includes("#failed")){
      $("#search-courses-form").hide();
      $("#search-courses-results-pp").hide();
    } else {
      $("#search-courses-form").show();
      $("#search-courses-results-pp").show();
    }
  });

  $("#search-courses-results-pp").change(function(e){
    e.preventDefault();

    var perPage = $("#search-courses-results-pp option:selected").text();

    var setPerPage = function(val){
      var paramsObj = locationSearchInJSON();
      paramsObj.per_page = val;

      window.location.search = $.param(paramsObj);
    }

    setPerPage(perPage);
  });
});

function locationSearchInJSON(){
  if (window.location.search && window.location.search.startsWith("?")){
    var params = window.location.search.substr(1);
  } else {
    return {};
  }

  var paramsJSON = {}
  params.split("&").forEach(function(item) {
     var keyValues = item.split("=");
     paramsJSON[keyValues[0]] = keyValues[1]
  })

  paramsJSON.utf8 = "✓";

  return paramsJSON;
}
