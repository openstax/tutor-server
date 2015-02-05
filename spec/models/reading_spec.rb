require 'rails_helper'

RSpec.describe Reading, :type => :model do
  it { is_expected.to have_many(:book_readings).dependent(:destroy) }
end
