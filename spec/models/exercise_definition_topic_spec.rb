require 'rails_helper'

RSpec.describe ExerciseDefinitionTopic, :type => :model do
  it { is_expected.to belong_to(:exercise_definition) }
  it { is_expected.to belong_to(:topic) }

  it { is_expected.to validate_presence_of(:exercise_definition) }
  it { is_expected.to validate_presence_of(:topic) }

  it 'must enforce that one topic is only on one exercise definition once' do
    # should-matcher uniqueness validations don't work on associations http://goo.gl/EcC1LQ
    # it { is_expected.to validate_uniqueness_of(:topic_id).scoped_to(:exercise_definition_id) }

    edt_1 = FactoryGirl.create(:exercise_definition_topic)
    edt_2 = FactoryGirl.create(:exercise_definition_topic, exercise_definition: edt_1.exercise_definition)
    edt_2.topic = edt_1.topic
    expect(edt_2).to_not be_valid
  end

end
