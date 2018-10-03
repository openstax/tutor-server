require 'rails_helper'

RSpec.describe Research::ManipulateStudentTask do

  let!(:course) { FactoryBot.create :course_profile_course }
  let!(:task) {
    FactoryBot.create(
      :tasks_task,
      opens_at: Time.current - 1.week,
      due_at: Time.current - 1.day
    )
  }
  let!(:tasking)  { FactoryBot.create(:tasks_tasking, task: task) }
  let!(:student)  { FactoryBot.create :course_membership_student, course: course, role: tasking.role }
  let!(:study)    { FactoryBot.create :research_study }
  let!(:cohort)   { FactoryBot.create :research_cohort, study: study }
  let!(:brain)    {
    FactoryBot.create :research_study_brain, cohort: cohort, domain: :student_task
  }

  it "can modify tasks" do
    Research::AddCourseToStudy[course: course, study: study]
    brain.update_attributes code: 'task.update_attributes(title: "yo, i altered you")'
    Research::ManipulateStudentTask.call(task: task, hook: 'test')
    expect(task.reload.title).to eq 'yo, i altered you'
  end
end
