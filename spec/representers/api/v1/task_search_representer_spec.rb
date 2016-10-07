require 'rails_helper'

RSpec.describe Api::V1::TaskSearchRepresenter, type: :representer do

  context "a user" do

    let(:user)           { FactoryGirl.create :user }
    let(:course)         { FactoryGirl.create :entity_course }
    let(:period)         { FactoryGirl.create :course_membership_period, course: course }
    let(:role)           { AddUserAsPeriodStudent.call(user: user, period: period).outputs.role }
    let(:default_task)   { FactoryGirl.create(:tasks_task) }
    let(:task_count)     { rand(5..10) }
    let(:ecosystem)      { FactoryGirl.build(:content_ecosystem) }
    let(:tasks)          do
      task_count.times.map{ FactoryGirl.create(:tasks_task, ecosystem: ecosystem) }
    end

    let!(:taskings)       do
      tasks.map{ |task| FactoryGirl.create(:tasks_tasking, task: task, role: role) }
    end

    let(:output)         { Hashie::Mash.new(
      'items' => GetCourseUserTasks[course: course, user: user]
    ) }
    let(:representation) { Api::V1::TaskSearchRepresenter.new(output).as_json }

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
            json['spy']       = {'ecosystem_id' => ecosystem.id,
                                 'ecosystem_title' => ecosystem.title}
            json['is_feedback_available'] = task.feedback_available?
            json['is_deleted'] = task.deleted?
            json
          }
        )
      )
    end

  end

end
