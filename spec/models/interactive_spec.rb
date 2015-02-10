require 'rails_helper'

RSpec.describe Interactive, :type => :model do
  it { is_expected.to have_many(:interactive_topics).dependent(:destroy) }
end
