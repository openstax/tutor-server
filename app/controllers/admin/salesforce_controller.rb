module Admin
  class SalesforceController < BaseController
    def actions
    end

    def update_salesforce
      outputs = PushSalesforceCourseStats.call(allow_error_email: true)

      flash[:notice] = "Ran on #{outputs[:num_courses]} course(s); " +
                       "updated #{outputs[:num_updates]} course(s); " +
                       "#{outputs[:num_errors]} error(s) occurred; " +
                       "#{outputs[:num_skips]} skip(s)"

      redirect_to actions_admin_salesforce_path
    end
  end
end
