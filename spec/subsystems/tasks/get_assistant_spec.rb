require 'rails_helper'

RSpec.describe Tasks::GetAssistant, type: :routine do
  let(:course)            { FactoryGirl.create :course_profile_course }
  let!(:assistant)        { FactoryGirl.create :tasks_assistant }
  let!(:course_assistant) {
    FactoryGirl.create :tasks_course_assistant, course: course,
                                                assistant: assistant,
                                                tasks_task_plan_type: 'dummy'
  }
  let(:task_plan)        { FactoryGirl.build :tasks_task_plan, type: 'dummy' }
  let(:hw_task_plan)     { FactoryGirl.build :tasks_task_plan, type: 'homework' }

  it 'finds an assistant by entity course id and task plan type' do
    resulting_assistant = Tasks::GetAssistant[course: course, task_plan: task_plan]

    expect(resulting_assistant).to eq(assistant)
  end

  it 'finds a default assistant even if it has not been explicitly added' do
    resulting_assistant = Tasks::GetAssistant[course: course, task_plan: hw_task_plan]
    Tasks::Models::Assistant.where(id: resulting_assistant.id).delete_all # pretend it wasn't there
    resulting_assistant = Tasks::GetAssistant[course: course, task_plan: hw_task_plan]
    expect(resulting_assistant.code_class_name).to eq 'Tasks::Assistants::HomeworkAssistant'
  end
end
