module Admin
  class SchoolsController < BaseController

    before_filter :get_districts, only: [:new, :edit]
    before_filter :get_school, only: [:edit, :update, :destroy]

    def index
      @schools = SchoolDistrict::ListSchools[]
      @page_header = "Manage schools"
    end

    def edit
      @page_header = "Edit school"
    end

    def new
      @page_header = "Create a school"
      @school = SchoolDistrict::Models::School.new
    end

    def create
      @page_header = "Create a school"
      handle_with(Admin::SchoolsCreate,
                  success: -> {
                    redirect_to admin_schools_path, notice: 'The school has been created.'
                  },
                  failure: -> {
                    flash.now[:error] = [@handler_result.errors.first.data.try(:[], :attribute),
                                         @handler_result.errors.first.message]
                                           .compact.join(' ').humanize
                    get_districts
                    @school = @handler_result.outputs.school
                    render :new, status: :unprocessable_entity
                  })
    end

    def update
      @page_header = "Edit school"
      handle_with(Admin::SchoolsUpdate,
                  school: @school,
                  success: -> {
                    redirect_to admin_schools_path, notice: 'The school has been updated.'
                  },
                  failure: -> {
                    flash.now[:error] = [@handler_result.errors.first.data.try(:[], :attribute),
                                         @handler_result.errors.first.message]
                                           .compact.join(' ').humanize
                    get_districts
                    @school = @handler_result.outputs.school
                    render :edit, status: :unprocessable_entity
                  })
    end

    def destroy
      handle_with(Admin::SchoolsDestroy,
                  school: @school,
                  success: -> {
                    redirect_to admin_schools_path, notice: 'The school has been deleted.'
                  },
                  failure: -> {
                    flash[:error] = [@handler_result.errors.first.data.try(:[], :attribute),
                                     @handler_result.errors.first.message]
                                       .compact.join(' ').humanize
                    redirect_to admin_schools_path
                  })
    end

    protected

    def get_districts
      @districts = SchoolDistrict::ListDistricts[]
    end

    def get_school
      @school = SchoolDistrict::GetSchool[id: params[:id]] || raise(ActiveRecord::RecordNotFound)
    end

  end
end
