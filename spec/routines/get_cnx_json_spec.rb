require 'rails_helper'

RSpec.describe GetCnxJson, :type => :routine do
  cnx_book_id = '031da8d3-b525-429c-80cf-6c8ed997733a'

  fixture_file = 'spec/fixtures/m50577/index.cnxml.html'

  it 'returns the hash for the fixture file' do
    hash = {
      title: 'Dummy',
      id: 'dummy',
      version: '1.0',
      content: open(fixture_file) { |f| f.read }
    }

    allow_any_instance_of(GetCnxJson).to(
      receive(:open).and_return(hash.to_json))

    result = GetCnxJson.call('dummy')
    expect(result.errors).to be_empty
    expect(result.outputs[:hash]).to eq JSON.parse(hash.to_json)
  end

  it 'returns the hash for a real web request' do
    result = GetCnxJson.call(cnx_book_id)
    expect(result.errors).to be_empty
    expect(result.outputs[:hash]).not_to be_nil
  end
end
