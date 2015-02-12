require 'rails_helper'

RSpec.describe ResourceTopic, :type => :model do
  subject { FactoryGirl.create :resource_topic }

  it { is_expected.to belong_to(:resource) }
  it { is_expected.to belong_to(:topic) }

  it { is_expected.to validate_presence_of(:resource) }
  it { is_expected.to validate_presence_of(:topic) }

  it { is_expected.to validate_uniqueness_of(:topic).scoped_to(:resource_id) }
end
