require 'rails_helper'

RSpec.describe ExerciseDefinition, :type => :model do
  it { is_expected.to belong_to(:klass) }
  it { is_expected.to have_many(:exercise_definition_topics).dependent(:destroy) }
  it { is_expected.to have_many(:topics).through(:exercise_definition_topics) }
  
  it { is_expected.to validate_presence_of(:klass) }
  it { is_expected.to validate_presence_of(:url) }
  

  it 'must enforce that one url is only in one klass once' do
    # should-matcher uniqueness validations don't work on associations http://goo.gl/EcC1LQ
    # it { is_expected.to validate_uniqueness_of(:url).scoped_to(:klass_id) }

    edef_1 = FactoryGirl.create(:exercise_definition)
    edef_2 = FactoryGirl.create(:exercise_definition, url: edef_1.url)
    edef_2.klass = edef_1.klass
    expect(edef_2).to_not be_valid
  end
end
