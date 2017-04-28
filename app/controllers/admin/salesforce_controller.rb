module Admin
  class SalesforceController < BaseController

    def show
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

    def update_salesforce
      outputs = UpdateSalesforceCourseStats.call

      flash[:notice] = "Ran on #{outputs[:num_records]} record(s); " +
                       "updated #{outputs[:num_updates]} record(s); #{outputs[:num_errors]} error(s) occurred."

      redirect_to admin_salesforce_path
    end

    protected

    def salesforce_path
      admin_salesforce_path
    end

  end
end
