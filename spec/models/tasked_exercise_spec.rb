require 'rails_helper'

RSpec.describe TaskedExercise, :type => :model do
  it { is_expected.to validate_presence_of(:url) }
  it { is_expected.to validate_presence_of(:content) }
end
