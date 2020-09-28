require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tutor::Assets, vcr: VCR_OPTS do
  before { RequestStore.store[:assets_manifest] = nil }

  it 'defaults to name.js when manifest is missing' do
    expect_any_instance_of(Faraday::Connection).to receive(:get).and_return(
      OpenStruct.new success?: false
    )
    expect(Tutor::Assets.tags_for(:foo)).to include "src='http://localhost:8000/dist/foo.js'"
  end

  it 'reads asset url from manifest' do
    expect_any_instance_of(Faraday::Connection).to receive(:get).and_return(
      OpenStruct.new(
        success?: true,
        body: { entrypoints: { foo: { js: [ 'foo-732c56c32ff399b62.min.bar' ] } } }.to_json
      )
    )
    expect(Tutor::Assets.tags_for(:foo)).to include(
      "src='http://localhost:8000/dist/foo-732c56c32ff399b62.min.bar'"
    )
  end

  context 'loading remote manifest' do
    before do
      @previous_assets_url = Rails.application.secrets.assets_url
      Rails.application.secrets.assets_url = 'https://tutor-dev.openstax.org/assets'
    end
    after  { Rails.application.secrets.assets_url = @previous_assets_url }

    it 'uses remote json' do
      expect(Tutor::Assets.manifest).to be_kind_of Tutor::Assets::Manifest
      expect(Tutor::Assets.tags_for(:tutor)).to(
        eq "<script type='text/javascript' src='https://tutor-dev.openstax.org/assets/tutor-b920eb0be760a7c440bf.min.js' crossorigin='anonymous' async></script>"
      )
    end
  end
end
