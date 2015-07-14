module Admin
  class SchoolsController < BaseController
    before_filter :populate_districts, except: [:destroy, :index]

    def index
      @schools = CourseDetail::ListSchools[]
    end

    def edit
      @school = CourseDetail::GetSchool[id: params[:id]]
    end

    def create
      handle_with(Admin::SchoolsCreate,
                  success: -> {
                    redirect_to admin_schools_path,
                                notice: 'The school has been created.'
                  },
                  failure: -> {
                    @school = CourseDetail::Models::School.new(school_params)
                    render :new
                  })
    end

    def update
      handle_with(Admin::SchoolsUpdate,
                  success: -> {
                    redirect_to admin_schools_path,
                                notice: 'The school has been updated.'
                  },
                  failure: -> {
                    @school = CourseDetail::GetSchool[id: params[:id]]
                    @school.attributes.merge!(school_params)
                    render :edit
                  })
    end

    def destroy
      handle_with(Admin::SchoolsDestroy,
                  success: -> {
                    redirect_to admin_schools_path,
                                notice: 'The school has been deleted.'
                  })
    end

    private
    def populate_districts
      @districts = CourseDetail::ListDistricts[]
    end

    def school_params
      params.require(:school).permit(:name, :district_id)
    end
  end
end
