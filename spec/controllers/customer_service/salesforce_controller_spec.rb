require 'rails_helper'

RSpec.describe CustomerService::SalesforceController, type: :controller do
  let(:customer_service) { FactoryGirl.create(:user, :customer_service) }

  before { controller.sign_in(customer_service) }

  describe 'import_courses' do
    it 'receives the call and formats the flash' do
      expect(ImportSalesforceCourses)
        .to receive(:call)
        .with(include_real_salesforce_data: false)

      allow(ImportSalesforceCourses)
        .to receive(:call)
        .with(include_real_salesforce_data: false)
        .and_return(
          OpenStruct.new(num_failures: 1, num_successes: 2)
        )

      post :import_courses, use_real_data: false

      expect(flash[:notice].gsub(/[^0-9]/, '')).to eq "321"
    end
  end
end
