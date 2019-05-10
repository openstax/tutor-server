require 'rails_helper'
require 'vcr_helper'

# If you need to regenerate the cassettes, remember to manually erase access_tokens,
# logins (emails), jwt assertions and visitor_ids from the new cassettes
# The private key in secrets.yml.example is not valid for box,
# but will not throw an exception when running with the cassettes
RSpec.describe Box, type: :lib, vcr: VCR_OPTS do
  let(:client)       { described_class.client }
  let(:filename)     { 'excluded_exercises_stats_by_course_20170925T213441Z.csv' }
  let(:zip_filename) { "#{File.basename(filename, '.*')}.zip" }
  let(:filepath)     { "spec/fixtures/box/#{filename}" }
  let(:zip_filepath) { "tmp/box/#{zip_filename}" }

  after(:each)       { File.delete(zip_filepath) if File.exist?(zip_filepath) }

  it 'can return new instances of Boxr::Client' do
    expect(client).to be_a(Boxr::Client)
    expect(described_class.client).not_to eq (client)
  end

  it 'can zip files and delete the zip after the block' do
    described_class.with_zip(zip_filename: zip_filename, files: [ filepath ]) do |zf|
      expect(zf).to eq zip_filepath
      expect(File.exist?(zip_filepath)).to eq true
    end

    expect(File.exist?(zip_filepath)).to eq false
  end

  it 'can zip and upload files to box' do
    expect(described_class).to(
      receive(:with_zip).with(zip_filename: zip_filename, files: [ filepath ]).and_call_original
    )
    result = described_class.upload_files(zip_filename: zip_filename, files: [ filepath ])
    expect(result['type']).to eq 'file'
    expect(result['name']).to eq zip_filename

    parent = result['parent']
    expect(parent['type']).to eq 'folder'
    expect(parent['name']).to eq Rails.application.secrets.box[:exports_folder]
  end
end
