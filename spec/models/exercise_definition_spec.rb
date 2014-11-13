require 'rails_helper'

RSpec.describe ExerciseDefinition, :type => :model do
  it { is_expected.to belong_to(:klass) }
  it { is_expected.to have_many(:exercise_definition_topics).dependent(:destroy) }
  it { is_expected.to have_many(:topics).through(:exercise_definition_topics) }
  
  it { is_expected.to validate_presence_of(:klass) }
  it { is_expected.to validate_presence_of(:url) }
  it { is_expected.to validate_uniqueness_of(:url).scoped_to(:klass_id) }
end
