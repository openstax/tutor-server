require 'rails_helper'

RSpec.describe Api::V1::TaskSearchRepresenter, type: :representer do

  context "a user" do

    let!(:user)           { FactoryGirl.create(:user) }
    let!(:course)         { FactoryGirl.create(:entity_course) }
    let!(:period)         { CreatePeriod.call(course: course).period }
    let!(:role)           { AddUserAsPeriodStudent.call(user: user, period: period).role }
    let!(:default_task)   { FactoryGirl.create(:tasks_task) }
    let!(:task_count)     { rand(5..10) }
    let!(:ecosystem)      { FactoryGirl.build(:content_ecosystem) }
    let!(:tasks)          { task_count.times.collect {
                              FactoryGirl.create(:tasks_task, ecosystem: ecosystem)
                           } }

    let!(:taskings)       { tasks.collect { |t| FactoryGirl.create(
      :tasks_tasking, task: t.entity_task, role: role
    ) } }

    let!(:output)         { Hashie::Mash.new(
      'items' => GetCourseUserTasks.call(course: course, user: user).collect{|t| t.task}
    ) }
    let!(:representation) { Api::V1::TaskSearchRepresenter.new(output).as_json }

    it "generates a JSON representation of their tasks" do
      expect(representation).to include(
        "total_count" => task_count,
        "items" => a_collection_containing_exactly(
          *tasks.map{ | task |
            json = task.as_json.slice('title')
            json['id']        = task.id.to_s
            json['type']      = task.task_type
            json['opens_at']  = DateTimeUtilities.to_api_s(task.opens_at)
            json['due_at']    = DateTimeUtilities.to_api_s(task.due_at)
            json['is_shared'] = task.is_shared?
            json['steps']     = task.task_steps.as_json
            json['spy']       = {'ecosystem_id' => ecosystem.id, 'ecosystem_title' => ecosystem.title}
            json
          }
        )
      )
    end

  end

end
