require 'rails_helper'

RSpec.describe Topic, :type => :model do
  it { is_expected.to have_many(:resource_topics).dependent(:destroy) }
  
  it { is_expected.to validate_presence_of(:name) }
end
