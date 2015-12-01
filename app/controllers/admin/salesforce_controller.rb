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
      outputs = ImportSalesforceCourses.call(
        include_real_salesforce_data: params[:use_real_data]
      ).outputs

      flash[:notice] = "Of #{outputs.num_failures + outputs.num_successes} candidate records in Salesforce, " +
        "#{outputs.num_successes} were successfully imported and #{outputs.num_failures} failed."

      redirect_to admin_salesforce_path
    end

    def update_salesforce
      outputs = UpdateSalesforceStats.call

      flash[:notice] = "Ran on #{outputs[:num_records]} record(s); " +
                       "updated #{outputs[:num_updates]} record(s); #{outputs[:num_errors]} error(s) occurred."

      redirect_to admin_salesforce_path
    end

  end
end
