require 'rails_helper'

module Queues
  RSpec.describe ExportPerformanceBook do
    it 'queues a job for later' do
      allow(Jobs::ExportPerformanceBookJob).to receive(:perform_later)
      described_class[]
      expect(Jobs::ExportPerformanceBookJob).to have_received(:perform_later)
    end
  end
end
