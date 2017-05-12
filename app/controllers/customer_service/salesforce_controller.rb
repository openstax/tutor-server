module CustomerService
  class SalesforceController < BaseController

    def show
    end

    protected

    def salesforce_path
      customer_service_salesforce_path
    end
  end
end
