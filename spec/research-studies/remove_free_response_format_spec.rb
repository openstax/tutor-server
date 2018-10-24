require "rails_helper"

RSpec.describe 'Task steps without free response field', type: :request, api: true, version: :v1 do

  before(:all) do
    course = FactoryBot.create :course_profile_course
    period = FactoryBot.create :course_membership_period, course: course
    user = FactoryBot.create(:user)
    user_role = AddUserAsPeriodStudent[user: user, period: period]
    @study = FactoryBot.create :research_study
    FactoryBot.create :research_cohort, name: 'control', study: @study

    Research::AddCourseToStudy[course: course, study: @study]

    task_plan = FactoryBot.create :tasks_task_plan, owner: course
    @task = FactoryBot.create :tasks_task, task_plan: task_plan,
                             step_types: [:tasks_tasked_exercise]
    FactoryBot.create :tasks_tasking, role: user_role, task: @task

    @token = FactoryBot.create :doorkeeper_access_token,
                       application: FactoryBot.create(:doorkeeper_application),
                       resource_owner_id: user.id
  end

  before(:each) {
    @study.deactivate!
  }

  it "can hide free-response formats" do
    brain = FactoryBot.create :research_modified_task_for_display,
                      study: @study,
                      code: <<~EOC
manipulation.ignore! and return unless cohort.name == 'control'
task_step_ids = []
task.task_steps.each do |ts|
  if ts.exercise?
    task_step_ids << ts.id
    ts.tasked.parser.questions_for_students.each{|q| q['formats'] -= ['free-response'] }
  end
end
if task_step_ids.any?
  manipulation.context[:task_step_ids] = task_step_ids
  manipulation.record!
else
  manipulation.ignore!
end
EOC
    @study.activate!

    api_get "/api/tasks/#{@task.id}", @token
    formats = response.body_as_hash[:steps].flat_map{|ts| ts.dig(:content, :questions, 0, :formats) }
    expect(formats).to_not include(:free_response)
    expect(brain.manipulations.last.target).to eq @task
  end

  it "can override requiring free-response when marking completed" do
    FactoryBot.create :research_modified_tasked_for_update,
                      study: @study,
                      code: <<~EOC
manipulation.ignore! and return unless tasked.exercise? && cohort.name == 'control'
tasked.parser.questions_for_students.each{|q|
  q['formats'] -= ['free-response']
}
manipulation.record!
EOC
    @study.activate!

    api_put "/api/steps/#{@task.task_steps.first.id}", @token,
            raw_post_data: { answer_id: @task.task_steps.first.tasked.question_answer_ids[0][0] }

    expect(response.body_as_hash[:errors]).to be_nil
  end

end
