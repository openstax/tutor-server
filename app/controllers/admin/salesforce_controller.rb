module Admin
  class SalesforceController < BaseController
    def show
    end

    def update
      outputs = PushSalesforceCourseStats.call

      flash[:notice] = "Ran on #{outputs[:num_courses]} course(s); " +
                       "updated #{outputs[:num_updates]} course(s); " +
                       "#{outputs[:num_errors]} error(s) occurred; " +
                       "#{outputs[:num_skips]} skip(s)"

      redirect_to admin_salesforce_path
    end
  end
end
