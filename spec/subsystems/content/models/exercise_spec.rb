require 'rails_helper'

RSpec.describe Content::Models::Exercise, :type => :model do
  subject{ FactoryGirl.create :content_exercise }

  it { is_expected.to have_many(:exercise_tags).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:number) }
  it { is_expected.to validate_presence_of(:version) }

  it { is_expected.to validate_uniqueness_of(:version).scoped_to(:number) }
end
