require 'rails_helper'

RSpec.describe Content::Models::Tag, :type => :model do
  it { is_expected.to have_many(:page_tags).dependent(:destroy) }
  it { is_expected.to have_many(:exercise_tags).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:tag_type) }
end
