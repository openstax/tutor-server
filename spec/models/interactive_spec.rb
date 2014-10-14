require 'rails_helper'

RSpec.describe Interactive, :type => :model do
  it { is_expected.to belong_to(:resource).dependent(:destroy) }
  it { is_expected.to have_one(:task).dependent(:destroy) }
end
