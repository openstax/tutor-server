require 'rails_helper'

RSpec.describe Exercise, :type => :model do
  it { is_expected.to have_many(:page_exercises).dependent(:destroy) }
end
