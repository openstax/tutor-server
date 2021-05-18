//= require manager

//========== Courses table ordering =============//
$(document).on('turbolinks:load', () => {
  $(".courses-table th").on("click", function(e){
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
})
