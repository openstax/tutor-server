require 'rails_helper'
require 'database_cleaner'

RSpec.describe OpenStax::Biglearn::Sparfa, type: :external do
  before(:each) { RequestStore.clear! }
  after(:all)   { RequestStore.clear! }

  context 'configuration' do
    it 'can be configured' do
      configuration = described_class.configuration
      expect(configuration).to be_a described_class::Configuration

      described_class.configure { |config| expect(config).to eq configuration }
    end
  end

  context 'api calls' do
    before(:all) do
      DatabaseCleaner.start

      @student = FactoryBot.create :course_membership_student
    end

    after(:all) { DatabaseCleaner.clean }

    it "delegates fetch_ecosystem_matrices to the client and returns a response" do
      requests = [
        { ecosystem_matrix_uuid: SecureRandom.uuid },
        {
          ecosystem_matrix_uuid: SecureRandom.uuid,
          student: @student,
          responded_before: Time.current
        }
      ]

      expect(described_class.client).to receive(:fetch_ecosystem_matrices).and_call_original

      results = described_class.fetch_ecosystem_matrices requests

      results = results.values if requests.is_a?(Array) && results.is_a?(Hash)

      [results].flatten.each { |result| expect(result).to be_a Hash }
    end
  end
end
