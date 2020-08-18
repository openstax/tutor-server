require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Validator::V1::RealClient, type: :external, vcr: VCR_OPTS do
  before(:all)  do
    @ignore_localhost = VCR.request_ignorer.ignore?(
      VCR::Request.new.tap { |r| r.uri = 'http://localhost' }
    )
    VCR.request_ignorer.ignore_localhost = false
  end
  after(:all)   { VCR.request_ignorer.ignore_localhost = @ignore_localhost }

  subject(:real_client) { described_class.new OpenStax::Validator::V1.configuration }

  context '#upload_ecosystem_manifest' do
    it 'works with an ecosystem with a real book uuid and exercise uid' do
      exercise = FactoryBot.create :content_exercise, number: 5918, version: 3

      ecosystem = exercise.ecosystem
      book = ecosystem.books.first
      book.uuid = '02040312-72c8-441e-a685-20e9333f3e1d'
      book.version = '14.3'
      book.save!

      response = subject.upload_ecosystem_manifest ecosystem
      expect(response['msg']).to eq 'Ecosystem successfully imported'
    end
  end
end
