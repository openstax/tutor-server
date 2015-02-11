require 'rails_helper'

RSpec.describe InteractiveTopic, type: :model do
  subject { FactoryGirl.create :interactive_topic }

  it { is_expected.to belong_to(:interactive) }
  it { is_expected.to belong_to(:topic) }

  it { is_expected.to validate_presence_of(:interactive) }
  it { is_expected.to validate_presence_of(:topic) }

  it {
    is_expected.to validate_uniqueness_of(:interactive).scoped_to(:topic_id)
  }
end
