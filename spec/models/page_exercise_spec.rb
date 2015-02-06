require 'rails_helper'

RSpec.describe PageExercise, :type => :model do
  subject { FactoryGirl.create :page_exercise }

  it { is_expected.to belong_to(:page) }
  it { is_expected.to belong_to(:exercise) }

  it { is_expected.to validate_presence_of(:page) }
  it { is_expected.to validate_presence_of(:exercise) }

  it { is_expected.to validate_uniqueness_of(:exercise).scoped_to(:page_id) }
end
