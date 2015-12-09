module Admin
  class SalesforceController < BaseController

    def index
      @user = Salesforce::Models::User.first
    end

    def callback
      user = Salesforce::Models::User.save_from_omniauth!(env["omniauth.auth"])
      Salesforce::Models::User.all.reject{|uu| uu.id == user.id}.each(&:destroy)
      redirect_to admin_salesforce_path
    end

    def destroy_user
      Salesforce::Models::User.destroy_all
      redirect_to admin_salesforce_path
    end

    def import_courses
      import_salesforce = ImportSalesforceCourses.call(
        include_real_salesforce_data: params[:use_real_data]
      )

      flash[:notice] = "Of #{import_salesforce.num_failures + import_salesforce.num_successes} candidate records in Salesforce, " +
        "#{import_salesforce.num_successes} were successfully imported and #{import_salesforce.num_failures} failed."

      redirect_to admin_salesforce_path
    end

    def update_salesforce
      update_salesforce = UpdateSalesforceStats.call

      flash[:notice] = "Ran on #{update_salesforce.num_records} record(s); " +
                       "updated #{update_salesforce.num_updates} record(s); #{update_salesforce.num_errors} error(s) occurred."

      redirect_to admin_salesforce_path
    end

  end
end
