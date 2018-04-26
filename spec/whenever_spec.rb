require 'rails_helper'

RSpec.describe 'whenever schedule' do
  let (:schedule) { Whenever::Test::Schedule.new(file: 'config/schedule.rb') }

  context 'basics' do
    before(:each) { expect(OpenStax::RescueFrom).not_to receive(:perform_rescue) }

    it 'makes sure `runner` statements exist' do
      expect(schedule.jobs[:runner].count).to be >= 5

      expect_any_instance_of(PushSalesforceCourseStats).to receive(:call)
      expect_any_instance_of(GetSalesforceBookNames).to receive(:call)
      expect(Lms::Models::TrustedLaunchData).to receive(:where).and_call_original

      # Executes the actual ruby statement to make sure all constants and methods exist:
      schedule.jobs[:runner].each { |job| eval job[:task] }
    end
  end

  # For running one specific runner task, e.g. `eval_runner_tasks('ImportSalesforceCourses')`
  def eval_runner_tasks(regex)
    schedule.jobs[:runner].each { |job| eval job[:task] if job[:task].match(regex)}
  end

end
