require 'rails_helper'

RSpec.describe CourseContent::Models::ExcludedExercise, type: :model do
  it { is_expected.to belong_to(:course) }

  it { is_expected.to validate_presence_of(:course) }
  it { is_expected.to validate_presence_of(:number) }

  it { is_expected.to validate_uniqueness_of(:number).scoped_to(:entity_course_id) }
end
