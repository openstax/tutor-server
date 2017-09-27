require 'rails_helper'
require 'vcr_helper'

# If you need to regenerate the cassettes, remember to manually erase access_tokens,
# logins (emails), jwt assertions and visitor_ids from the new cassettes
# The private key in secrets.yml.example is not valid for box,
# but will not throw an exception when running with the cassettes
RSpec.describe Box, type: :lib, vcr: VCR_OPTS do
  let(:client)   { Box.client }
  let(:filename) { 'excluded_exercises_stats_by_course_20170925T213441Z.csv' }
  let(:filepath) { "spec/fixtures/box/#{filename}" }

  before(:each)  { RequestStore.clear! }

  it 'returns one client instance per request' do
    expect(client).to be_a(Boxr::Client)
    expect(Box.client).to eq client

    RequestStore.clear!
    client2 = Box.client
    expect(client2).not_to eq client
    expect(client2).to be_a(Boxr::Client)
  end

  it 'can upload files to box' do
    result = Box.upload_file(filepath)
    expect(result['type']).to eq 'file'
    expect(result['name']).to eq filename

    parent = result['parent']
    expect(parent['type']).to eq 'folder'
    expect(parent['name']).to eq Rails.application.secrets.box['exports_folder']
  end
end
