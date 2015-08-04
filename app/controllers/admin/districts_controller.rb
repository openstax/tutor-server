module Admin
  class DistrictsController < BaseController
    def index
      @districts = SchoolDistrict::ListDistricts[]
      @page_header = "Manage districts"
    end

    def edit
      @district = SchoolDistrict::GetDistrict[id: params[:id]]
      @page_header = "Edit district"
    end

    def new
      @page_header = "Create a district"
    end

    def create
      @page_header = "Create a district"
      handle_with(Admin::DistrictsCreate,
                  complete: -> {
                    redirect_to admin_districts_path,
                                notice: 'The district has been created.'
                  })
    end

    def update
      @page_header = "Edit district"
      handle_with(Admin::DistrictsUpdate,
                  success: -> {
                    redirect_to admin_districts_path,
                                notice: 'The district has been updated.'
                  },
                  failure: -> {
                    @district = SchoolDistrict::GetDistrict[id: params[:id]]
                    @district.attributes.merge!(district_params)
                    render :edit
                  })
    end

    def destroy
      handle_with(Admin::DistrictsDestroy,
                  success: -> {
                    redirect_to admin_districts_path,
                                notice: 'The district has been deleted.'
                  },
                  failure: -> {
                    redirect_to admin_districts_path,
                                alert: @handler_result.errors.first.message
                  })
    end
  end
end
