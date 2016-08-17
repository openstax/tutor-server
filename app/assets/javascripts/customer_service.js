//= require jquery
//= require jquery_ujs
//= require jquery-ui-1.11.4.custom.min
//= require bootstrap-sprockets
//= require manager

//========== Courses table ordering =============//
  $(document).ready(function(){
    $(".courses-table th").on("click", function(e){
      var oldSearch = window.location.search;
      var locationSearch = {}
      location.search.substr(1).split("&").forEach(function(item) {locationSearch[item.split("=")[0]] = item.split("=")[1]})

      var field = e.target.textContent.toLowerCase();
      if(field.includes("teacher")){
        field = "teacher";
      }

      var toggleOrderBy = function(){
        if(locationSearch.order_by && locationSearch.order_by.includes("desc")){
          locationSearch.order_by = field + " asc";
        } else {
          locationSearch.order_by = field + " desc";
        }
      };

      toggleOrderBy();

      locationSearch.utf8 = "✓";
      window.location.search = $.param(locationSearch);
    });
  })
