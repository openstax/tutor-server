require 'rails_helper'

module ActiveJob
  describe Base, type: :lib do
    let(:job)            { ::ActiveJob::Base.new }
    let(:exception_class) { ActiveRecord::RecordNotFound }

    it 'triggers exception notifications on failure' do
      expect(job).to receive(:perform) { raise exception_class }
      expect(ExceptionNotifier).to receive(:notify_exception) do |exception, options|
        expect(exception).to be_a exception_class
      end

      expect{ job.perform_now }.to raise_error exception_class
    end
  end
end
