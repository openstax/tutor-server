require 'rails_helper'

RSpec.describe Stats::Calculate, type: :routine do
  let!(:task_plan) { FactoryBot.create :tasks_task_plan }
  let!(:past_task_plan) { FactoryBot.create :tasks_task_plan, created_at: 3.month.ago }
  let!(:highlight) { FactoryBot.create :content_note, annotation: 'test' }
  let!(:reading_step) { FactoryBot.create :tasks_task_step,
      first_completed_at: 1.day.ago,
      tasked_type: :tasks_tasked_reading }

  let!(:homework_step) { FactoryBot.create :tasks_task_step,
      first_completed_at: 1.day.ago,
      tasked_type: :tasks_tasked_exercise
  }

  let(:course) { task_plan.owner }

  let(:past_course) {
      FactoryBot.create(:course_profile_course, is_test: false,
                        starts_at: 3.month.ago,
                        ends_at: 1.month.ago)
  }

  let(:period) { FactoryBot.create :course_membership_period, course: course }

  before(:each) {
    3.times do
      CourseMembership::AddStudent[period: period, role: FactoryBot.create(:entity_role)]
    end
  }

  it 'counts all the things' do
    interval = Stats::Calculate.call(
      date_range: ((Time.now - 1.week)...Time.now)
    ).outputs.interval
    expect(interval.courses.active).to include course
    expect(interval.courses.active).not_to include past_course
    expect(interval.stats).to eq({
      active_courses: 4,
      new_enrollments: 3,
      active_students: 3,
      active_instructors: 0,
      active_populated_courses: 1,
      task_plans: 1,
      notes: 1,
      highlights: 1,
      new_notes: 1,
      new_highlights: 1,
      exercise_steps: 1,
      reading_steps: 1,
    }.stringify_keys)
  end
end
