require 'rails_helper'

RSpec.describe Book, :type => :model do
  xit { is_expected.to have_many(:book_readings).dependent(:destroy) }
  xit { is_expected.to have_many(:book_exercises).dependent(:destroy) }
  xit { is_expected.to have_many(:book_interactives).dependent(:destroy) }
end
