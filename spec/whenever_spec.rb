require 'rails_helper'

RSpec.describe 'whenever schedule' do
  let (:schedule) { Whenever::Test::Schedule.new(file: 'config/schedule.rb') }

  context 'basics' do
    before(:each) { expect(OpenStax::RescueFrom).not_to receive(:perform_rescue) }

    it 'makes sure `runner` statements exist' do
      expect(schedule.jobs[:rake].count).to be >= 3
      expect(schedule.jobs[:runner].count).to be >= 1

      # Make sure all constants and methods exist

      schedule.jobs[:rake].each { |job| expect { Rake::Task[job[:task]] }.not_to raise_error }

      expect(CourseProfile::BuildPreviewCourses).to receive(:call)
      schedule.jobs[:runner].each { |job| eval job[:task] }
    end
  end
end
