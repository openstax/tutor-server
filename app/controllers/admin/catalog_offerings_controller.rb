module Admin
  class CatalogOfferingsController < BaseController
    before_action :get_offerings_and_ecosystems
    before_action :get_salesforce_book_names, only: [ :new, :edit ]
    before_action :get_books, only: [ :new, :edit ]

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
      if !@offering.deleted? && @offering.destroy
        redirect_to admin_catalog_offerings_path, alert: "#{@offering.title} deleted"
      else
        if @offering.deleted?
          flash.now[:error] = "#{@offering.title} is already deleted"
        else
          flash.now[:error] = @offering.errors.map do |att, msg|
            att = @offering.title if att == :base

            [att, msg].join(' ')
          end
        end

        render :index
      end
    end

    def restore
      if @offering.deleted? && @offering.restore
        redirect_to admin_catalog_offerings_path, alert: "#{@offering.title} restored"
      else
        if @offering.deleted?
          flash.now[:error] = @offering.errors.map do |att, msg|
            att = @offering.title if att == :base

            [att, msg].join(' ')
          end
        else
          flash.now[:error] = "#{@offering.title} is not deleted"
        end

        render :index
      end
    end

    protected

    def get_offerings_and_ecosystems
      @deleted_offerings, @offerings = Catalog::Models::Offering.all.partition(&:deleted?)
      @offering = params[:id].blank? ? Catalog::Models::Offering.new :
                                       Catalog::Models::Offering.find(params[:id])
      @ecosystems = Content::ListEcosystems[]
    end

    def get_salesforce_book_names
      @salesforce_book_names = GetSalesforceBookNames.call.outputs.book_names
    end

    def get_books
      @books = Content::Models::Book.all.map {|b| ["#{b.title} - #{b.cnx_id}", b.id] }
    end
  end
end
