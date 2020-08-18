require 'rails_helper'

RSpec.describe OpenStax::Validator::V1::FakeClient, type: :external do
  subject(:fake_client) { described_class.new OpenStax::Validator::V1.configuration }

  context '#upload_ecosystem_manifest' do
    it 'works with any ecosystem' do
      ecosystem = FactoryBot.create :content_ecosystem

      response = subject.upload_ecosystem_manifest ecosystem
      expect(response['msg']).to eq 'Ecosystem successfully imported'
    end
  end
end
