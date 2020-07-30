require 'rails_helper'

RSpec.describe CourseProfile::Models::Cache, type: :model do
  subject(:cache) { FactoryBot.create :course_profile_cache }

  it { is_expected.to belong_to(:course) }
end
