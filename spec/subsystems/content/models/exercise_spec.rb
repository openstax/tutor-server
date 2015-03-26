require 'rails_helper'

RSpec.describe Content::Exercise, :type => :model do
  it { is_expected.to have_many(:exercise_tags).dependent(:destroy) }
end
