module Admin
  class SalesforceController < BaseController

    def actions
    end

    def update_salesforce
      outputs = UpdateSalesforceCourseStats.call

      flash[:notice] = "Ran on #{outputs[:num_records]} record(s); " +
                       "updated #{outputs[:num_updates]} record(s); #{outputs[:num_errors]} error(s) occurred."

      redirect_to actions_admin_salesforce_path
    end

  end
end
