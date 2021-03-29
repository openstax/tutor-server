require 'rails_helper'

RSpec.describe 'cron:day', type: :rake do
  include_context 'rake'

  it 'calls all configured routines' do
    expect(GetSalesforceBookNames).to receive(:call).with(true)
    expect(PushSalesforceCourseStats).to receive(:call)
    expect(Lms::Models::TrustedLaunchData).to receive(:cleanup)

    call
  end
end
