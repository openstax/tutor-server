require 'rails_helper'

RSpec.describe Content::UploadEcosystemManifestToValidator, type: :routine do
  let(:ecosystem) { FactoryBot.create :content_ecosystem }

  it 'calls OpenStax::Validator::V1.upload_ecosystem_manifest with the given argument' do
    expect(OpenStax::Validator::V1).to receive(:upload_ecosystem_manifest).with(ecosystem)

    described_class.call ecosystem
  end
end
