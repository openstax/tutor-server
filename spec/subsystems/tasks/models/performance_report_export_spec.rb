require 'rails_helper'

RSpec.describe Tasks::Models::PerformanceReportExport, type: :model do
  before(:all) do |all|
    CarrierWave::Uploader::Base.storage = :fog

    @file = File.open(
      'spec/fixtures/exports/Sociology_with_Courseware_Review_Scores_20200807-163104.xlsx'
    )

    VCR.use_cassette('Tasks_Models_PerformanceReportExport/with_export', VCR_OPTS) do
      @performance_report_export = FactoryBot.create :tasks_performance_report_export, export: @file
    end
  end

  after(:all) do
    @file.close

    CarrierWave::Uploader::Base.storage = :file
  end

  before { @performance_report_export.reload }

  subject(:performance_report_export) { @performance_report_export }

  it { is_expected.to belong_to(:course) }
  it { is_expected.to belong_to(:role)   }

  it { is_expected.to validate_presence_of(:export) }

  context '#filename' do
    it 'returns the expected value' do
      expect(performance_report_export.filename).to(
        eq 'f30204859d1220abd380bda909d7cfba6744c9455668affd2f0e03d94872dc75.xlsx'
      )
    end
  end

  context '#url' do
    it 'returns the expected value' do
      expect(performance_report_export.url).not_to be_blank
    end
  end
end
