require 'rails_helper'

RSpec.describe SendGlobalExerciseExclusionsToBiglearn, type: :routine do
  let(:num_extra_courses) { 2 }
  let!(:courses)          do
    num_extra_courses.times.map { FactoryBot.create :course_profile_course }
  end

  it 'calls OpenStax::Biglearn::Api.update_globally_excluded_exercises for each course' do
    courses = CourseProfile::Models::Course.all.to_a

    expect(OpenStax::Biglearn::Api).to(
      receive(:update_globally_excluded_exercises).exactly(courses.size).times do |course:|
        expect(course).to be_in(courses)
      end
    )

    described_class.call
  end
end
