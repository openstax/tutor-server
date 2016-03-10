module Admin
  class CatalogOfferingsController < BaseController

    before_filter :set_template_variables
    before_filter :get_salesforce_book_names, only: [:new, :edit]

    def new
      @offerings.unshift @offering
      render action: :edit
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
                    @offerings.unshift @offering
                    render :edit
                  }
                 )
    end

    private

    def set_template_variables
      @offerings = Catalog::ListOfferings[]
      @offering = if params[:id]
                    @offerings.detect{|offering| offering.id.to_s == params[:id] }
                  else
                    Catalog::Models::Offering.new
                  end
      @ecosystems = Content::ListEcosystems[]
    end

    def get_salesforce_book_names
      @salesforce_book_names = GetSalesforceBookNames.call.outputs.book_names
    end

  end
end
