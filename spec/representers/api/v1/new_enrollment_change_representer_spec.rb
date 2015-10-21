require 'rails_helper'

RSpec.describe Api::V1::NewEnrollmentChangeRepresenter, type: :representer do
  let(:params)          { OpenStruct.new }
  let(:enrollment_code) { 'offensive phrase' }
  let(:book_cnx_id)     { 'd52e93f4-8653-4273-86da-3850001c0786@3.14' }
  let(:json)            { { enrollment_code: enrollment_code, book_cnx_id: book_cnx_id }.to_json }

  before(:each)         { described_class.new(params).from_json(json) }

  it 'parses user input to create a new EnrollmentChange' do
    expect(params.enrollment_code).to eq enrollment_code
    expect(params.book_cnx_id).to eq book_cnx_id
  end
end
