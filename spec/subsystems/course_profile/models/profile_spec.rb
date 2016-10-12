require 'rails_helper'

RSpec.describe CourseProfile::Models::Profile, type: :model do
  subject(:profile) { FactoryGirl.create :course_profile_profile }

  it { is_expected.to belong_to(:time_zone).dependent(:destroy).autosave(true) }

  it { is_expected.to belong_to(:school) }
  it { is_expected.to belong_to(:course) }
  it { is_expected.to belong_to(:offering) }

  it { is_expected.to validate_presence_of(:course) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:starts_at) }
  it { is_expected.to validate_presence_of(:ends_at) }

  it { is_expected.to validate_uniqueness_of(:course) }
  it { is_expected.to validate_uniqueness_of(:time_zone) }

  it 'validates format of default times' do
    profile.default_open_time = '16:32'
    expect(profile).to be_valid

    profile.default_due_time = '16:'
    expect(profile).not_to be_valid

    profile.default_open_time = '24:00'
    expect(profile).not_to be_valid

    profile.default_due_time = '23:60'
    expect(profile).not_to be_valid
  end

  it 'knows if it is active' do
    expect(profile).to be_active

    profile.starts_at = Time.current.tomorrow
    expect(profile).not_to be_active

    profile.starts_at = Time.current - 1.week
    profile.ends_at = Time.current.yesterday
    expect(profile).not_to be_active

    profile.ends_at = Time.current + 1.week
    expect(profile).to be_active
  end

  it 'cannot end before it starts' do
    expect(profile).to be_valid

    profile.starts_at = Time.current.tomorrow
    profile.ends_at = Time.current.yesterday

    expect(profile).not_to be_valid
  end
end
