require 'rails_helper'

RSpec.describe Content::Models::ExerciseTag, :type => :model do
  subject { FactoryGirl.create :content_exercise_tag }

  it { is_expected.to belong_to(:exercise) }
  it { is_expected.to belong_to(:tag) }

  it { is_expected.to validate_presence_of(:exercise) }
  it { is_expected.to validate_presence_of(:tag) }

  it { is_expected.to validate_uniqueness_of(:tag)
                        .scoped_to(:content_exercise_id) }
end
