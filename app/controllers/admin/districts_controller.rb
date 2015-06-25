module Admin
  class DistrictsController < BaseController
    def index
      @districts = ListDistricts[]
    end

    def create
      handle_with(Admin::DistrictsCreate,
                  complete: -> {
                    redirect_to admin_districts_path,
                                notice: 'The district has been created.'
                  })
    end
  end
end
