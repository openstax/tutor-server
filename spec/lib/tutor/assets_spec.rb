require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tutor::Assets, vcr: VCR_OPTS do
  it 'defaults to url when manifest is missing' do
    expect(Tutor::Assets).to receive(:manifest)
    expect(Tutor::Assets.tags(:foo)).to include "src='http://localhost:8000/dist/foo.js'"
  end

  it 'reads json from manifest' do
    expect(Tutor::Assets).to receive(:manifest).thrice.and_return(
      HashWithIndifferentAccess.new(
        'foo' => [ { 'src' => 'http://localhost:8000/dist/foo-732c56c32ff399b62.min.bar' } ]
      )
    )
    expect(Tutor::Assets.tags(:foo)).to include(
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
      Tutor::Assets.read_manifest
      expect(Tutor::Assets.manifest.present?).to be true
      expect(Tutor::Assets.manifest).to be_kind_of Tutor::Assets::Manifest::ManifestParser
      expect(Tutor::Assets.tags(:tutor)).to(
        eq "<script type='text/javascript' src='https://tutor-dev.openstax.org/assets/tutor-b920eb0be760a7c440bf.min.js' crossorigin='anonymous' async></script>"
      )
    end
  end
end
