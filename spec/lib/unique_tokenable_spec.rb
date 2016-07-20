require 'rails_helper'

RSpec.describe UniqueTokenable, type: :lib do
  class DummyModel < ActiveRecord::Base; end

  before(:all) do
    DatabaseCleaner.start

    capture_stdout do
      ActiveRecord::Schema.define do
        create_table :dummy_models do |t|
          t.string :enrollment_code
        end unless table_exists?(:dummy_models)
      end
    end
  end

  after(:all) { DatabaseCleaner.clean }

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

  it 'allows for a length option on secure random modes' do
    DummyModel.unique_token :enrollment_code, mode: { hex: { length: 10 } }
    dummy = DummyModel.new
    dummy.valid?
    expect(dummy.enrollment_code.length).to be(20)
    # hex length is twice the value passed in

    DummyModel.unique_token :enrollment_code, mode: { urlsafe_base64: { length: 9 } }
    dummy = DummyModel.new
    dummy.valid?
    expect(dummy.enrollment_code.length).to be(12)
    # result of urlsafe_base64 is about 4/3 of n

    DummyModel.unique_token :enrollment_code, mode: { base64: { length: 9 } }
    dummy = DummyModel.new
    dummy.valid?
    expect(dummy.enrollment_code.length).to be(12)
    # result of base64 is about 4/3 of n
  end

  it 'allows for a random number mode' do
    DummyModel.unique_token :enrollment_code, mode: { random_number: { length: 3 } }
    dummy = DummyModel.new
    dummy.valid?
    expect(dummy.enrollment_code.length).to eq 3
    expect(dummy.enrollment_code.to_i).to be < 1000
  end

  it 'allows for a padding option on urlsafe_base64 mode' do
    DummyModel.unique_token :enrollment_code, mode: { urlsafe_base64: { padding: true } }
    dummy = DummyModel.new
    dummy.valid?
    expect(dummy.enrollment_code).to match(/=\z/)
  end

  it 'cannot be nil' do
    DummyModel.unique_token :enrollment_code
    dummy = DummyModel.new(enrollment_code: nil)
    dummy.valid?
    expect(dummy.enrollment_code).not_to be_blank
  end

  it "lets you know when a mode is already handled" do
    expect {
      class DummyTokenGenerator
        def self.handled_modes; [:hex]; end
        TokenGenerator.register(self)
      end
    }.to raise_error(TokenGenerator::TokenGeneratorModeAlreadyHandled, "hex")
  end

  it "lets you know when a mode is unhandled" do
    expect {
      DummyModel.unique_token :enrollment_code, mode: :nope
      DummyModel.create
    }.to raise_error(TokenGenerator::UnhandledTokenGeneratorMode, "nope")
  end
end
