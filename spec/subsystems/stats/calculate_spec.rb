require 'rails_helper'

RSpec.describe Stats::Calculate, type: :routine do
  let!(:courses) { 3.times.map do
      FactoryBot.create(:course_profile_course,
                        is_test: false,
                        starts_at: Time.now - 1.day,
                        ends_at: Time.now + 1.day)
    end
  }

  let(:past_course) {
      FactoryBot.create(:course_profile_course, is_test: false,
                        starts_at: Time.now - 3.month,
                        ends_at: Time.now - 1.month)
  }

  let(:period) { FactoryBot.create :course_membership_period, course: courses.first }

  before(:each) {
    CourseMembership::AddStudent[period: period, role: FactoryBot.create(:entity_role)]
  }

  it 'counts things' do
    stats = Stats::Calculate.call(date_range: (Time.now - 1.week ... Time.now)).outputs
    expect(stats.active_courses).to include courses.first
    expect(stats.active_courses).not_to include past_course
    expect(stats.num_active_courses).to eq 3
    expect(stats.num_new_enrollments).to eq 1
    expect(stats.num_active_students).to eq 1
  end
end
