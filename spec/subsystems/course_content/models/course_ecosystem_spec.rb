require 'rails_helper'

RSpec.describe CourseContent::Models::CourseEcosystem, type: :model do
  it { is_expected.to belong_to(:book) }
  it { is_expected.to belong_to(:ecosystem) }

  it { is_expected.to validate_presence_of(:book) }
  it { is_expected.to validate_presence_of(:ecosystem) }
end
