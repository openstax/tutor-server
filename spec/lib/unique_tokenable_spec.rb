require 'rails_helper'


RSpec.describe UniqueTokenable do
  class DummyModel < ActiveRecord::Base; end

  before(:all) do
    ActiveRecord::Schema.define do
      create_table :dummy_models do |t|
        t.string :enrollment_code
      end unless table_exists?(:dummy_models)
    end
  end

  it 'sets a random hex on a tokenable model by default' do
    DummyModel.unique_token :enrollment_code

    allow(SecureRandom).to receive(:hex) { '123987' }
    dummy = DummyModel.new
    dummy.valid?

    expect(dummy.enrollment_code).to eq('123987')
  end

  it 'allows the caller to change the mode' do
    DummyModel.unique_token :enrollment_code, mode: :urlsafe_base64

    allow(SecureRandom).to receive(:urlsafe_base64) { 'abc_12-3' }
    dummy = DummyModel.new
    dummy.valid?

    expect(dummy.enrollment_code).to eq('abc_12-3')
  end

  it 'works with the memorable babbler plugin' do
    DummyModel.unique_token :enrollment_code, mode: :memorable

    allow(Babbler).to receive(:babble) { 'memorable code' }
    dummy = DummyModel.new
    dummy.valid?

    expect(dummy.enrollment_code).to eq('memorable code')
  end

  it "doesn't overwrite existing values" do
    dummy = DummyModel.new(enrollment_code: 'anything i want here')
    dummy.valid?
    expect(dummy.enrollment_code).to eq('anything i want here')
  end

  it "prevents token duplication" do
    dummy = DummyModel.create!(enrollment_code: "dontCopyMe!")
    expect(dummy).to be_valid

    dummy = DummyModel.new(enrollment_code: "dontCopyMe!")
    expect(dummy).not_to be_valid
  end
end
