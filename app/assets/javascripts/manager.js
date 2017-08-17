//= require jquery
//= require jquery.stickytableheaders.min

$(document).ready(function() {
  $('[data-toggle="popover"]').popover();
  $('table.concept-coach-stats').stickyTableHeaders();

  //========== Search bar show only on List of Courses tab =============//
  $(".admin ul li a").click(function(e){
    if(window.location.pathname === "/admin/courses"){
      var href = e.target.href;
      if (href.includes("#incomplete") || href.includes("#failed")){
        $("#search-courses-form").hide();
        $("#search-courses-results-pp").hide();
      } else {
        $("#search-courses-form").show();
        $("#search-courses-results-pp").show();
      }
    }
  });

  //========== Order by selected =============//
  $(".course-info-name").click(function(){
    var paramsObj = locationSearchInJSON();
    paramsObj.order_by = "name";
    window.location.search = decodeURIComponent($.param(paramsObj));
  });

  $(".ecosystem-created-at").click(function(){
    var paramsObj = locationSearchInJSON();
    paramsObj.order_by = "created_at";
    window.location.search = decodeURIComponent($.param(paramsObj));
  });

  $(".course-info-id").click(function(){
    var paramsObj = locationSearchInJSON();
    paramsObj.order_by = "id";
    window.location.search = decodeURIComponent($.param(paramsObj));
  });

  $(".course-info-profile-school").click(function(){
    var paramsObj = locationSearchInJSON();
    paramsObj.order_by = "school";
    window.location.search = decodeURIComponent($.param(paramsObj));
  });


  //========== Change results per page =============//
  $("#search-courses-results-pp").change(function(e){
    e.preventDefault();

    var perPage = $("#search-courses-results-pp option:selected").text();

    var setPerPage = function(val){
      var paramsObj = locationSearchInJSON();
      paramsObj.per_page = Number(val) || val;
      window.location.search = decodeURIComponent($.param(paramsObj));
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
