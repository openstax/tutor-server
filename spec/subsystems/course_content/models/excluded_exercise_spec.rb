require 'rails_helper'

RSpec.describe CourseContent::Models::ExcludedExercise, type: :model do
  subject { FactoryGirl.create :course_content_excluded_exercise }

  it { is_expected.to belong_to(:course) }

  it { is_expected.to validate_presence_of(:course) }
  it { is_expected.to validate_presence_of(:exercise_number) }

  it { is_expected.to validate_uniqueness_of(:exercise_number).scoped_to(:entity_course_id) }
end
