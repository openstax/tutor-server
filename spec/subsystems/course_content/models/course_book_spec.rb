require 'rails_helper'

RSpec.describe CourseContent::Models::CourseBook, :type => :model do
  it { is_expected.to belong_to(:book) }
  it { is_expected.to belong_to(:course) }
  it { is_expected.to validate_presence_of(:book) }
  it { is_expected.to validate_presence_of(:course) }
end
