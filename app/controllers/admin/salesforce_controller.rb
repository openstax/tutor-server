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

  end
end
