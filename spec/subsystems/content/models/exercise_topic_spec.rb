require 'rails_helper'

RSpec.describe Content::ExerciseTopic, :type => :model do
  # subject { FactoryGirl.create :content_exercise_topic }

  it { is_expected.to belong_to(:content_exercise) }
  it { is_expected.to belong_to(:content_topic) }

  it { is_expected.to validate_presence_of(:content_exercise) }
  it { is_expected.to validate_presence_of(:content_topic) }

  it { is_expected.to validate_uniqueness_of(:content_topic).scoped_to(:content_exercise_id) }
end
