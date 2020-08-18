require 'rails_helper'

RSpec.describe OpenStax::Validator::V1, type: :external do
  subject(:v1) { described_class }

  context '#upload_ecosystem_manifest' do
    it 'delegates the method to the client implementation' do
      ecosystem = FactoryBot.create :content_ecosystem

      expect(described_class.client).to receive(:upload_ecosystem_manifest).with(ecosystem)

      expect(subject.upload_ecosystem_manifest(ecosystem)).to eq true
    end
  end
end
