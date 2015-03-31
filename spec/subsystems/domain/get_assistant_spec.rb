require 'rails_helper'

RSpec.describe Domain::GetAssistant do
  let!(:course)           { Domain::CreateCourse.call.outputs.course }
  let!(:assistant)        { FactoryGirl.create :assistant }
  let!(:course_assistant) {
    FactoryGirl.create :course_assistant, course: course, assistant: assistant,
                                          task_plan_type: 'dummy'
  }
  let!(:task_plan)        { FactoryGirl.build :task_plan, type: 'dummy' }

  it 'finds an assistant by entity course id and task plan type' do
    entity_course = Domain::CreateCourse.call.outputs.course
    course_assistant = Domain::GetAssistant[course: course, task_plan: task_plan]

    expect(course_assistant).to eq(assistant)
  end
end
