require 'rails_helper'

RSpec.describe Content::Models::ExerciseTopic, :type => :model do
  it { is_expected.to belong_to(:exercise) }
  it { is_expected.to belong_to(:topic) }

  it { is_expected.to validate_presence_of(:exercise) }
  it { is_expected.to validate_presence_of(:topic) }

  # should-matcher uniqueness validations don't work on associations http://goo.gl/EcC1LQ
  # it { is_expected.to validate_uniqueness_of(:topic).scoped_to(:content_exercise_id) }
end
