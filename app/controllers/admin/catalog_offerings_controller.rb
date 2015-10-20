module Admin
  class CatalogOfferingsController < BaseController

    before_filter :set_template_variables
    def index

    end

    def new
      @offering =
      @offerings.unshift @offering
      render action: 'index'
    end

    def edit
    end

    def update
      handle_with(Admin::CatalogOfferingUpdate,
                  success: -> {
                    redirect_to admin_catalog_offerings_path, notice: 'The offering has been updated.'
                  },
                  failure: -> {
                     flash[:error] = @handler_result.errors.map(&:translate).to_sentence
                     render :edit
                  }
                 )
    end

    def create
      handle_with(Admin::CatalogOfferingCreate,
                  success: -> {
                    redirect_to admin_catalog_offerings_path, notice: 'The offering has been created.'
                  },
                  failure: -> {
                    flash[:error] = @handler_result.errors.map(&:translate).to_sentence
                    render :new
                  }
                 )
    end

    private

    def set_template_variables
      @offerings = Catalog::ListOfferings[]
      @offering = if params[:id]
                    @offerings.detect{|offering| offering.id.to_s == params[:id] }
                  else
                    false
                  end
      @ecosystems = Content::ListEcosystems[]
    end

  end
end
