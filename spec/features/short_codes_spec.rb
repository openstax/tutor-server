require 'rails_helper'

RSpec.describe "short codes", type: :feature do
  context "students accessing tasks via short code" do
    let(:course)           { FactoryBot.create :course_profile_course }
    let(:period)           { FactoryBot.create :course_membership_period, course: course }

    let(:task_plan_1)      { FactoryBot.create(:tasks_task_plan, course: course) }
    let(:task_1)           do
      FactoryBot.create(:tasks_task, task_plan: task_plan_1, opens_at: 1.day.from_now)
    end
    let!(:tasking_1)       { FactoryBot.create(:tasks_tasking, role: student_role, task: task_1) }
    let(:task_plan_1_code) do
      FactoryBot.create(:short_code_short_code, uri: task_plan_1.to_global_id.to_s).code
    end

    let(:task_plan_2)      { FactoryBot.create(:tasks_task_plan, course: course) }
    let(:task_plan_2_code) do
      FactoryBot.create(:short_code_short_code, uri: task_plan_2.to_global_id.to_s).code
    end

    let(:student_user)     { FactoryBot.create(:user_profile) }
    let!(:student_role)    { AddUserAsPeriodStudent[period: period, user: student_user] }

    before { stub_current_user(student_user) }

    context "when the task is unpublished" do
      it "gives a 422 page with a useful error message" do
        visit short_code_path(short_code: task_plan_2_code)
        expect(page).to have_http_status 422
        expect(page).to have_content "not yet available"
      end
    end

    context "when the task is published and unopen" do
      it "gives a 422 page with a useful error message" do
        visit short_code_path(short_code: task_plan_1_code)
        expect(page).to have_http_status 422
        expect(page).to have_content "not yet open"
      end
    end

    context "when the task is published and open" do
      it "takes the student to the task" do
        Timecop.freeze(2.days.from_now) do
          visit short_code_path(short_code: task_plan_1_code)
          expect(page).to have_http_status 200
        end
      end
    end
  end
end
