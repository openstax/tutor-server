require 'rails_helper'

RSpec.describe Api::V1::TaskSearchRepresenter, type: :representer do

  context "a user" do

    let(:user)           { FactoryGirl.create :user }
    let(:course)         { FactoryGirl.create :course_profile_course }
    let(:period)         { FactoryGirl.create :course_membership_period, course: course }
    let(:role)           { AddUserAsPeriodStudent.call(user: user, period: period).outputs.role }
    let(:default_task)   { FactoryGirl.create(:tasks_task) }
    let(:task_count)     { rand(5..10) }
    let(:ecosystem)      { FactoryGirl.create(:content_ecosystem) }
    let(:tasks)          do
      task_count.times.map{ FactoryGirl.create(:tasks_task, ecosystem: ecosystem) }
    end

    let!(:taskings)       do
      tasks.map{ |task| FactoryGirl.create(:tasks_tasking, task: task, role: role) }
    end

    let(:output)         { Hashie::Mash.new(items: GetCourseUserTasks[course: course, user: user]) }

    let(:representation) { Api::V1::TaskSearchRepresenter.new(output).as_json }

    it "generates a JSON representation of their tasks" do
      expect(representation.deep_symbolize_keys).to match(
        total_count: task_count,
        items: a_collection_containing_exactly(
          *tasks.map do | task |
            {
              id: task.id.to_s,
              title: task.title,
              type: task.task_type,
              opens_at: DateTimeUtilities.to_api_s(task.opens_at),
              due_at: DateTimeUtilities.to_api_s(task.due_at),
              is_shared: task.is_shared?,
              steps: task.task_steps.as_json,
              spy: { ecosystem_id: ecosystem.id, ecosystem_title: ecosystem.title},
              is_feedback_available: task.feedback_available?,
              is_deleted: task.deleted?
            }
          end
        )
      )
    end

  end

end
