require 'rails_helper'

describe 'whenever schedule' do
  before(:all) { load 'Rakefile' }

  let (:schedule) { Whenever::Test::Schedule.new(file: 'config/schedule.rb') }

  context 'basics' do
    before(:each) { expect(OpenStax::RescueFrom).not_to receive(:perform_rescue) }

    it 'makes sure `runner` statements exist' do
      assert_equal 3, schedule.jobs[:runner].count

      expect_any_instance_of(PushSalesforceCourseStats).to receive(:call)
      expect_any_instance_of(ImportSalesforceCourses).to receive(:call)
      expect_any_instance_of(GetSalesforceBookNames).to receive(:call)

      # Executes the actual ruby statement to make sure all constants and methods exist:
      schedule.jobs[:runner].each { |job| eval job[:task] }
    end
  end

  # For running one specific runner task, e.g. `eval_runner_tasks('ImportSalesforceCourses')`
  def eval_runner_tasks(regex)
    schedule.jobs[:runner].each { |job| eval job[:task] if job[:task].match(regex)}
  end

end
