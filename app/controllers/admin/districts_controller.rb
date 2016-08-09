module Admin
  class DistrictsController < BaseController

    before_filter :get_district, only: [:edit, :update, :destroy]

    def index
      @districts = SchoolDistrict::ListDistricts[]
      @page_header = "Manage districts"
    end

    def edit
      @page_header = "Edit district"
    end

    def new
      @page_header = "Create a district"
      @district = SchoolDistrict::Models::District.new
    end

    def create
      handle_with(Admin::DistrictsCreate,
                  success: -> {
                    redirect_to admin_districts_path, notice: 'The district has been created.'
                  },
                  failure: -> {
                    @page_header = "Create a district"
                    flash.now[:error] = @handler_result.errors.full_messages
                    @district = @handler_result.outputs.district
                    render :new, status: :unprocessable_entity
                  })
    end

    def update
      handle_with(Admin::DistrictsUpdate,
                  district: @district,
                  success: -> {
                    redirect_to admin_districts_path, notice: 'The district has been updated.'
                  },
                  failure: -> {
                    @page_header = "Edit district"
                    flash.now[:error] = @handler_result.errors.full_messages
                    @district = @handler_result.outputs.district
                    render :edit, status: :unprocessable_entity
                  })
    end

    def destroy
      handle_with(Admin::DistrictsDestroy,
                  district: @district,
                  success: -> {
                    redirect_to admin_districts_path, notice: 'The district has been deleted.'
                  },
                  failure: -> {
                    flash[:error] = @handler_result.errors.full_messages
                    redirect_to admin_districts_path
                  })
    end

    protected

    def get_district
      @district = SchoolDistrict::GetDistrict[id: params[:id]] ||
                  raise(ActiveRecord::RecordNotFound)
    end

  end
end
