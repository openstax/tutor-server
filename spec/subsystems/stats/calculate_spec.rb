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

  let(:past_course) {
      FactoryBot.create(:course_profile_course, is_test: false,
                        starts_at: 3.month.ago,
                        ends_at: 1.month.ago)
  }

  before(:each) {
    add_students = -> (course) {
      period = FactoryBot.create :course_membership_period, course: course
      3.times do
        CourseMembership::AddStudent[period: period, role: FactoryBot.create(:entity_role)]
      end
    }
    add_students[task_plan.owner]
    add_students[homework_step.task.task_plan.owner]
    add_students[reading_step.task.task_plan.owner]
  }

  it 'counts all the things' do
    interval = Stats::Calculate.call(
      date_range: ((Time.now - 1.week)...Time.now)
    ).outputs.interval
    expect(interval.courses.active).to include task_plan.owner
    expect(interval.courses.active).not_to include past_course
    expect(interval.stats).to eq({
      new_courses: 4,
      active_courses: 4,
      new_students: 9,
      new_instructors: 0,
      active_students: 9,
      active_instructors: 0,
      active_populated_courses: 3,
      reading_task_plans: 3,
      homework_task_plans: 0,
      notes: 1,
      highlights: 1,
      new_notes: 1,
      new_highlights: 1,
      exercise_steps: 1,
      reading_steps: 1,
      practice_steps: 0,
      nudge_calculated: 0,
      nudge_retry_correct: 0,
      nudge_initially_invalid: 0,
    }.stringify_keys)
  end
end
