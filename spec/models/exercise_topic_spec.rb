require 'rails_helper'

RSpec.describe ExerciseTopic, :type => :model do
  subject { FactoryGirl.create :exercise_topic }

  it { is_expected.to belong_to(:exercise) }
  it { is_expected.to belong_to(:topic) }

  it { is_expected.to validate_presence_of(:exercise) }
  it { is_expected.to validate_presence_of(:topic) }

  it { is_expected.to validate_uniqueness_of(:topic).scoped_to(:exercise_id) }
end
