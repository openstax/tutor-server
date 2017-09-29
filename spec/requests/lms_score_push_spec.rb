require "rails_helper"

RSpec.describe 'LMS Score Push', type: :request, version: :v1 do

  let(:course) { FactoryGirl.create(:course_profile_course, is_lms_enabled: true) }
  let(:period) { FactoryGirl.create :course_membership_period, course: course }
  let(:lms_app) { FactoryGirl.create(:lms_app, owner: course) }
  let(:teacher_user) { FactoryGirl.create(:user) }
  let(:teacher_token) do
    FactoryGirl.create :doorkeeper_access_token, resource_owner_id: teacher_user.id
  end

  let(:simulator) { Lms::Simulator.new(self) }
  let(:launch_helper) { Lms::LaunchHelper.new(self) }

  before(:each) {
    AddUserAsCourseTeacher[user: teacher_user, course: course]

    simulator.install_tutor(app: lms_app, course: "physics")
    simulator.set_launch_defaults(course: "physics", assignment: "tutor")
  }

  it 'works for one user who has a score' do
    simulator.add_student("bob")
    simulator.launch(user: "bob")
    launch_helper.complete_the_launch_locally

    bob_user = launch_helper.get_user("bob")
    stub_perf_report([{period: "1st", user: bob_user, score: 0.9111}])

    simulator.expect_to_receive_score(user: "bob", assignment: "tutor", score: 0.9111)

    api_put("/api/lms/courses/#{course.id}/push_scores", teacher_token)
    expect(response).to have_http_status :accepted

    job_status_id = response.body_as_hash[:job].match(/api\/jobs\/(.*)/)[1]
    job_status = Jobba.find(job_status_id)

    expect(job_status.errors).to be_empty
    expect(job_status.progress).to eq 1.0
    expect(job_status.data).to eq({"num_callbacks" => 1, "num_missing_scores" => 0})
  end

  it 'works for users across two periods' do

  end

  it 'notes when a score cannot be sent because it is not yet in the perf report' do

  end

  it 'handles LMS erroring on receiving grade for a LMS-dropped student' do

  end

  def stub_perf_report(entries)
    report = []

    entries_by_period = entries.group_by{|entry| entry[:period]}
    entries_by_period.each do |period, entries|
      report.push({
        period: {
          name: period
        },
        students: entries.map do |entry|
          {
            name: entry[:user].name,
            student_identifier: entry[:user].name + "_sid",
            user: entry[:user].id,
            average_score: entry[:score]
          }
        end
      })
    end

    allow(Tasks::GetTpPerformanceReport).to receive(:[]) { report }
  end

end
