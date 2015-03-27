require 'rails_helper'

RSpec.describe Content::Models::Exercise, :type => :model do
  it { is_expected.to have_many(:exercise_topics).dependent(:destroy) }
end
