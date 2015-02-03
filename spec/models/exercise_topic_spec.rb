require 'rails_helper'

RSpec.describe ExerciseTopic, :type => :model do
  it { is_expected.to belong_to(:exercise) }
  it { is_expected.to belong_to(:topic) }

  it { is_expected.to validate_presence_of(:exercise) }
  it { is_expected.to validate_presence_of(:topic) }

  it 'must enforce that one exercise is on one topic only once' do
    et_1 = FactoryGirl.create(:exercise_topic)
    et_2 = FactoryGirl.build(:exercise_topic, exercise: et_1.exercise,
                                              topic: et_1.topic)
    expect(et_2).to_not be_valid
  end

end
