require 'rails_helper'

RSpec.describe Tasks::GetAssistant do
  let!(:course)           { CreateCourse.call.outputs.course }
  let!(:assistant)        { FactoryGirl.create :tasks_assistant }
  let!(:course_assistant) {
    FactoryGirl.create :tasks_course_assistant, course: course,
                                                assistant: assistant,
                                                tasks_task_plan_type: 'dummy'
  }
  let!(:task_plan)        { FactoryGirl.build :tasks_task_plan, type: 'dummy' }

  it 'finds an assistant by entity course id and task plan type' do
    course_assistant = Tasks::GetAssistant[course: course, task_plan: task_plan]

    expect(course_assistant).to eq(assistant)
  end
end
