module Admin
  class DistrictsController < BaseController
    def index
      @districts = ListDistricts[]
    end

    def edit
      @district = GetDistrict[id: params[:id],
                              action: :edit,
                              caller: current_user]
    end

    def create
      handle_with(Admin::DistrictsCreate,
                  complete: -> {
                    redirect_to admin_districts_path,
                                notice: 'The district has been created.'
                  })
    end

    def update
      handle_with(Admin::DistrictsUpdate,
                  success: -> {
                    redirect_to admin_districts_path,
                    notice: 'The district has been updated.'
                  },
                  failure: -> {
                    @district = GetDistrict[id: params[:id],
                                            action: :edit,
                                            caller: current_user]
                    @district.attributes.merge!(district_params)
                    render :edit
                  })
    end
  end
end
