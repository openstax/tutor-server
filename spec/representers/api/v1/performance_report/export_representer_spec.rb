require 'rails_helper'

RSpec.describe Api::V1::PerformanceReport::ExportRepresenter, type: :representer do
  let(:performance_report_export) { FactoryBot.create :tasks_performance_report_export }

  subject(:representation) { described_class.new(performance_report_export).to_hash.symbolize_keys }

  it 'includes filename, url and created_at' do
    # filename is the hash for a blank file
    filename = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855.xlsx'

    secrets = Rails.application.secrets
    expect(representation).to include(
      filename: filename,
      url: "#{secrets.aws[:s3][:exports_asset_host]}/#{secrets.environment_name}/#{filename}",
      created_at: DateTimeUtilities.to_api_s(performance_report_export.created_at)
    )
  end
end
