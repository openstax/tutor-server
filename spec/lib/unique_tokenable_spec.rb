require 'rails_helper'

RSpec.describe UniqueTokenable do
  before(:all) { @original_mode = CourseMembership::Models::Period.unique_token_mode }

  after(:all) do
    CourseMembership::Models::Period.unique_token :enrollment_code, mode: @original_mode
  end

  let(:tokenable_class) { CourseMembership::Models::Period }

  it 'sets a random hex on a tokenable model by default' do
    tokenable_class.unique_token :enrollment_code

    allow(SecureRandom).to receive(:hex) { '123987' }
    period = tokenable_class.new
    period.valid?

    expect(period.enrollment_code).to eq('123987')
  end

  it 'allows the caller to change the mode' do
    tokenable_class.unique_token :enrollment_code, mode: :urlsafe_base64

    allow(SecureRandom).to receive(:urlsafe_base64) { 'abc_12-3' }
    period = tokenable_class.new
    period.valid?

    expect(period.enrollment_code).to eq('abc_12-3')
  end

  it 'works with the memorable babbler plugin' do
    tokenable_class.unique_token :enrollment_code, mode: :memorable

    allow(Babbler).to receive(:babble) { 'memorable code' }
    period = tokenable_class.new
    period.valid?

    expect(period.enrollment_code).to eq('memorable code')
  end

  it "doesn't overwrite existing values" do
    period = tokenable_class.new(enrollment_code: 'anything i want here')
    period.valid?
    expect(period.enrollment_code).to eq('anything i want here')
  end

  it "prevents token duplication" do
    course = CreateCourse[name: 'Great Course']
    period = CreatePeriod[course: course, name: 'Cool period']

    period.to_model.update_attributes(enrollment_code: "dontCopyMe!")
    expect(period.to_model).to be_valid

    period2 = CreatePeriod[course: course, name: 'Next period']

    period2.to_model.update_attributes(enrollment_code: "dontCopyMe!")
    expect(period2.to_model).not_to be_valid
  end
end
