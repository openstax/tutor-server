require 'rails_helper'

RSpec.describe Content::Topic, :type => :model do
  it { is_expected.to have_many(:page_topics).dependent(:destroy) }
  it { is_expected.to have_many(:exercise_topics).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:name) }
end
