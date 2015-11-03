require 'rails_helper'

RSpec.describe UniqueTokenable do
  let(:period) { CourseMembership::Models::Period.new }

  it 'sets a random hex on a tokenable model' do
    allow(SecureRandom).to receive(:hex) { '123987' }
    CourseMembership::Models::Period.unique_token :enrollment_code, mode: :hex

    period.valid?

    expect(period.enrollment_code).to eq('123987')
  end

  it 'allows the caller to change the mode' do
    allow(SecureRandom).to receive(:urlsafe_base64) { 'abc_12-3' }

    CourseMembership::Models::Period.unique_token :enrollment_code,
                                                  mode: :urlsafe_base64
    period.valid?

    expect(period.enrollment_code).to eq('abc_12-3')
  end

  it 'works with the memorable babbler plugin' do
    allow(Babbler).to receive(:babble) { 'memorable code' }

    CourseMembership::Models::Period.unique_token :enrollment_code,
                                                  mode: :memorable
    period.valid?

    expect(period.enrollment_code).to eq('memorable code')
  end
end
