module Admin
  class CatalogOfferingsController < BaseController

    before_action :get_offerings_and_ecosystems
    before_action :get_salesforce_book_names, only: [:new, :edit]

    def index
    end

    def new
      @offerings.unshift @offering
      render :edit
    end

    def update
      handle_with(
        Admin::CatalogOfferingUpdate,
        success: -> {
          updated_courses = @handler_result.outputs.num_updated_courses
          active_courses = @handler_result.outputs.num_active_courses
          notice = "#{@offering.title} has been updated."
          notice += " #{updated_courses} out of #{active_courses} courses updated."

          redirect_to admin_catalog_offerings_path, notice: notice
        },
        failure: -> {
          flash.now[:error] = @handler_result.errors.map(&:translate).to_sentence
          @offering = @handler_result.outputs.offering \
            if @handler_result.outputs.offering.present?
          render :edit
        }
      )
    end

    def create
      handle_with(
        Admin::CatalogOfferingCreate,
        success: -> {
          title = @handler_result.outputs.offering.title

          redirect_to admin_catalog_offerings_path,
                      notice: "#{title} has been created."
        },
        failure: -> {
          flash.now[:error] = @handler_result.errors.map(&:translate).to_sentence
          @offering = @handler_result.outputs.offering \
            if @handler_result.outputs.offering.present?
          new
        }
      )
    end

    def destroy
      offering_model = @offering.to_model

      if offering_model.destroy
        redirect_to admin_catalog_offerings_path, alert: "#{offering_model.title} deleted"
      else
        flash.now[:error] = offering_model.errors.map do |att, msg|
          att = offering_model.title if att == :base

          [att, msg].join(' ')
        end

        render :index
      end
    end

    protected

    def get_offerings_and_ecosystems
      @offerings = Catalog::ListOfferings[]
      @offering = params[:id] ? @offerings.find { |offering| offering.id.to_s == params[:id] } :
                                Catalog::Offering.new(strategy: Catalog::Models::Offering.new.wrap)
      @ecosystems = Content::ListEcosystems[]
    end

    def get_salesforce_book_names
      @salesforce_book_names = GetSalesforceBookNames.call.outputs.book_names
    end

  end
end
