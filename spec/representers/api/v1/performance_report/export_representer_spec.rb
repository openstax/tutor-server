require 'rails_helper'

BLANK_FILENAME = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855.xlsx'

RSpec.describe Api::V1::PerformanceReport::ExportRepresenter, type: :representer do
  let(:performance_report_export) { FactoryBot.create :tasks_performance_report_export }

  subject(:representation) { described_class.new(performance_report_export).to_hash.symbolize_keys }

  it 'includes filename, url and created_at' do
    secrets = Rails.application.secrets
    url = "#{CarrierWave::Uploader::Base.asset_host}/#{secrets.environment_name}/#{BLANK_FILENAME}"
    expect(representation).to include(
      filename: BLANK_FILENAME,
      url: url,
      created_at: DateTimeUtilities.to_api_s(performance_report_export.created_at)
    )
  end

  after(:all) { FileUtils.rm Rails.root.join('public', 'test', BLANK_FILENAME) }
end
