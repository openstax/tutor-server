require 'rails_helper'

RSpec.describe Api::V1::ApproveEnrollmentChangeRepresenter, type: :representer do
  let(:params)             { OpenStruct.new }
  let(:student_identifier) { 'N0B0DY' }
  let(:json)               { { student_identifier: student_identifier }.to_json }

  before(:each)         { described_class.new(params).from_json(json) }

  it 'parses user input to approve an EnrollmentChange' do
    expect(params.student_identifier).to eq student_identifier
  end
end
