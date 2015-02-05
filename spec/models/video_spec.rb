require 'rails_helper'

RSpec.describe Video, :type => :model do
  it { is_expected.to have_many(:book_videos).dependent(:destroy) }
end
