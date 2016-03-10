require 'rails_helper'

RSpec.describe CourseProfile::Models::Profile, type: :model do
  subject { FactoryGirl.create :course_profile_profile }

  it { is_expected.to belong_to(:course) }

  it { is_expected.to validate_presence_of(:course) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:timezone) }

  it { is_expected.to validate_uniqueness_of(:course) }

  it { is_expected.to validate_inclusion_of(:timezone)
                        .in_array(ActiveSupport::TimeZone.all.collect{ |tz| tz.name }) }
end
