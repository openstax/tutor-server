require 'rails_helper'

RSpec.describe Research::ModifiedTask do

  let!(:course) { FactoryBot.create :course_profile_course }
  let!(:task) {
    FactoryBot.create(
      :tasks_task,
      opens_at: Time.current - 1.week,
      due_at: Time.current - 1.day
    )
  }
  let!(:tasking) { FactoryBot.create(:tasks_tasking, task: task) }
  let!(:student) { tasking.role.student.tap { |student| student.update_attribute :course, course } }
  let!(:study)   { FactoryBot.create :research_study }

  let!(:cohort)  { FactoryBot.create :research_cohort, study: study }
  let!(:brain)   {
    FactoryBot.create :research_modified_task, study: study,
                      code: 'manipulation.record!; task.title = "yo, i altered you"'
  }

  before(:each) {
    Research::AddCourseToStudy[course: course, study: study]
    study.activate!
  }

  it "can modify task" do
    updated_task = described_class[task: task]
    expect(updated_task.title).to eq 'yo, i altered you'
  end
end
