require 'rails_helper'

RSpec.describe Content::PageTopic, :type => :model do
  subject { FactoryGirl.create :page_topic }

  it { is_expected.to belong_to(:page) }
  it { is_expected.to belong_to(:topic) }

  it { is_expected.to validate_presence_of(:page) }
  it { is_expected.to validate_presence_of(:topic) }

  it { is_expected.to validate_uniqueness_of(:topic).scoped_to(:page_id) }
end
