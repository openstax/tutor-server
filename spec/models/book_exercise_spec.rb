require 'rails_helper'

RSpec.describe BookExercise, :type => :model do
  subject { FactoryGirl.create :book_exercise }

  it { is_expected.to belong_to(:book) }
  it { is_expected.to belong_to(:exercise) }

  it { is_expected.to validate_presence_of(:book) }
  it { is_expected.to validate_presence_of(:exercise) }

  it { is_expected.to validate_uniqueness_of(:exercise).scoped_to(:book_id) }
end
