require 'rails_helper'
require 'vcr_helper'

RSpec.describe Import::CnxResource, :type => :routine, vcr: VCR_OPTS do
  cnx_book_id = '031da8d3-b525-429c-80cf-6c8ed997733a'

  fixture_file = 'spec/fixtures/m50577/index.cnxml.html'

  it 'returns the hash for the fixture file' do
    hash = {
      title: 'Dummy',
      id: 'dummy',
      version: '1.0',
      content: open(fixture_file) { |f| f.read }
    }

    allow_any_instance_of(Import::CnxResource).to(
      receive(:open).and_return(hash.to_json))

    result = Import::CnxResource.call('dummy')
    expect(result.errors).to be_empty
    out = result.outputs
    expect(out[:hash]).to eq JSON.parse(hash.to_json)
    expect(out[:url]).not_to be_blank
    expect(out[:content]).not_to be_blank
  end

  it 'returns the hash for a real web request' do
    result = Import::CnxResource.call(cnx_book_id)
    expect(result.errors).to be_empty
    out = result.outputs
    expect(out[:hash]).not_to be_blank
    expect(out[:url]).not_to be_blank
    expect(out[:content]).not_to be_blank
  end
end
