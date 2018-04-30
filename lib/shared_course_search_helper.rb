module SharedCourseSearchHelper

  def self.get_course_ids(params)
    if params[:courses_select_all_on_all_pages] == 'on'
      SearchCourses[query: params[:query]].reorder(nil).pluck(:id)
    else
      params[:course_id]
    end
  end


end
