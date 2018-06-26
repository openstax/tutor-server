class Research::StudiesController < Research::BaseController

  before_action :get_study, only: [:show, :edit, :update, :destroy, :add_courses]

  def index
  end

  def new
    @study = Research::Models::Study.new
  end

  def edit
  end

  def show
    @query = params[:query]
    @order_by = params[:order_by]

    if @query
      result = SearchCourses.call(query: params[:query], order_by: params[:order_by] || 'id')
      per_page = params[:per_page] || self.class.default_per_page
      per_page = result.outputs.total_count if params[:per_page] == 'all'
      params_for_pagination = { page: (params[:page] || 1), per_page: per_page }

      if result.errors.any?
        flash[:error] = "Invalid search"
        redirect_to research_study_path(@study) and return
      end

      @course_infos = result.outputs.items.preload(
        teachers: { role: [:role_user, :profile] },
        periods: :students,
        ecosystems: :books
      ).try(:paginate, params_for_pagination)
    else
      @course_infos = []
    end

  end

  def update
    if @study.update_attributes(params[:research_models_study].permit(:name))
      flash[:notice] = "Study updated"
      redirect_to research_studies_path(@study)
    else
      flash[:alert] = @study.errors.full_messages
      render :edit
    end
  end

  def create
    study = Research::Models::Study.new(name: params[:research_models_study][:name])
    if study.save
      redirect_to research_studies_path(study)
    else
      render :new
    end
  end

  def destroy
    if @study.destroy
      flash[:notice] = "Study #{@study.name} deleted"
      redirect_to research_studies_path
    else
      flash[:alert] = @study.errors.full_messages
      redirect_to research_study_path(@study)
    end
  end

  def add_courses
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

  def self.default_per_page
    50
  end

  protected

  def get_study
    @study = Research::Models::Study.find(params[:id])
  end

end
