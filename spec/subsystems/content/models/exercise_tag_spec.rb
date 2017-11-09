require 'rails_helper'

RSpec.describe Content::Models::ExerciseTag, type: :model do
  subject { FactoryBot.create :content_exercise_tag }

  it { is_expected.to belong_to(:exercise) }
  it { is_expected.to belong_to(:tag) }

  # These validations are by far the most consuming for all specs and the demo script
  # They are also enforced by the DB through non-null columns,
  # foreign key constraints and unique indices
  # Therefore, we decided to disable them until a bulk validation solution is available
  # it { is_expected.to validate_presence_of(:exercise) }
  # it { is_expected.to validate_presence_of(:tag) }

  # it { is_expected.to validate_uniqueness_of(:tag).scoped_to(:content_exercise_id) }
end
