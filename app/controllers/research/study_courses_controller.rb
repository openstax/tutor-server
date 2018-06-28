class Research::StudyCoursesController < Research::BaseController

  def create
    @study = Research::Models::Study.find(params[:study_id])

    course_ids = SharedCourseSearchHelper.get_course_ids(params)

    errors = []

    CourseProfile::Models::Course.where(id: course_ids).all.each do |course|
      result = Research::AddCourseToStudy.call(course: course, study: @study)
      if result.errors.any?
        errors.push("Couldn't add course #{course.id} '#{course.name}': #{result.errors.full_messages}")
      end
    end

    if errors.any?
      flash[:alert] = <<-MSG
          #{course_ids.count - errors.count} courses added; #{errors.count} courses not added
          due to errors: #{errors.join(", ")}
        MSG
    else
      flash[:notice] = "Courses added"
    end

    redirect_to research_study_path(@study)
  end

  def destroy
    @study_course = Research::Models::StudyCourse.find(params[:id])
    study = @study_course.study

    if @study_course.destroy
      flash[:notice] = "Course #{@study_course.course.name} removed"
      redirect_to research_study_path(study)
    else
      flash[:alert] = @study.errors.full_messages
      redirect_to research_study_path(study)
    end
  end

end
