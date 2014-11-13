require 'rails_helper'

RSpec.describe ExerciseDefinitionTopic, :type => :model do
  it { is_expected.to belong_to(:exercise_definition) }
  it { is_expected.to belong_to(:topic) }

  it { is_expected.to validate_presence_of(:exercise_definition) }
  it { is_expected.to validate_presence_of(:topic) }
  it { is_expected.to validate_uniqueness_of(:topic_id).scoped_to(:exercise_definition_id) }
end
