require 'rails_helper'

RSpec.describe Book, :type => :model do
  it { is_expected.to have_many(:book_readings).dependent(:destroy) }
  it { is_expected.to have_many(:book_exercises).dependent(:destroy) }
  it { is_expected.to have_many(:book_interactives).dependent(:destroy) }
  it { is_expected.to have_many(:book_videos).dependent(:destroy) }
end
