require 'rails_helper'

RSpec.describe Research::ModifiedTasked do

  let!(:course) { FactoryBot.create :course_profile_course }
  let!(:task) {
    FactoryBot.create(
      :tasks_task,
      opens_at: Time.current - 1.week,
      due_at: Time.current - 1.day
    )
  }
  let(:task_step) { FactoryBot.create :tasks_task_step, task: task }

  let(:exercise) { FactoryBot.create :tasks_tasked_exercise, task_step: task_step }
  let!(:tasking) { FactoryBot.create(:tasks_tasking, task: task) }
  let!(:student) { tasking.role.student.tap { |student| student.update_attribute :course, course } }
  let!(:study)   { FactoryBot.create :research_study }

  let!(:cohort)  { FactoryBot.create :research_cohort, study: study }
  let!(:brain)   {
    FactoryBot.create :research_modified_tasked, study: study,
                      code: 'manipulation.record!; return { task_step: { is_new: true }, update: { modified: true } }'
  }

  before(:each) {
    Research::AddCourseToStudy[course: course, study: study]
    study.activate!
  }

  it "can modify step and update" do
    result = described_class.call(tasked: task_step.tasked)
    expect(result.outputs[:task_step].is_new).to eq true
  end
end
