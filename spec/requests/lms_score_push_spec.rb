require "rails_helper"

RSpec.describe 'LMS Score Push', type: :request, version: :v1 do

  let(:course) { FactoryBot.create(:course_profile_course, is_lms_enabled: true) }
  let(:period) { FactoryBot.create :course_membership_period, course: course }
  let(:lms_app) { FactoryBot.create(:lms_app, owner: course) }
  let(:teacher_user) { FactoryBot.create(:user) }
  let(:teacher_token) do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: teacher_user.id
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

    expect(course.last_lms_scores_push_job_id).to be_blank
    simulator.expect_to_receive_score(user: "bob", assignment: "tutor", score: 0.9111)

    api_put("/api/lms/courses/#{course.id}/push_scores", teacher_token)
    expect(response).to have_http_status :accepted

    expect(course.reload.last_lms_scores_push_job_id).not_to be_blank

    expect_job_info(data: {"num_callbacks" => 1, "num_missing_scores" => 0})
  end

  it 'works for users across two periods' do
    simulator.add_student("bob")
    simulator.launch(user: "bob")
    launch_helper.complete_the_launch_locally

    simulator.add_student("tim")
    simulator.launch(user: "tim")
    launch_helper.complete_the_launch_locally

    bob_user = launch_helper.get_user("bob")
    tim_user = launch_helper.get_user("tim")
    stub_perf_report([{period: "1st", user: bob_user, score: 0.9111},
                      {period: "2nd", user: tim_user, score: 1.0}])

    simulator.expect_to_receive_score(user: "bob", assignment: "tutor", score: 0.9111)
    simulator.expect_to_receive_score(user: "tim", assignment: "tutor", score: 1.0)

    api_put("/api/lms/courses/#{course.id}/push_scores", teacher_token)
    expect(response).to have_http_status :accepted

    expect_job_info(data: {"num_callbacks" => 2, "num_missing_scores" => 0})
  end

  it 'notes when a score cannot be sent because it is not yet in the perf report' do
    simulator.add_student("bob")
    simulator.launch(user: "bob")
    launch_helper.complete_the_launch_locally

    bob_user = launch_helper.get_user("bob")
    stub_perf_report([{period: "1st", user: FactoryBot.create(:user), score: 0}])

    simulator.expect_not_to_receive_score(user: "bob", assignment: "tutor")

    api_put("/api/lms/courses/#{course.id}/push_scores", teacher_token)
    expect(response).to have_http_status :accepted

    expect_job_info(data: {"num_callbacks" => 1, "num_missing_scores" => 1})
  end

  it 'handles LMS erroring on receiving grade for a LMS-dropped student' do
    simulator.add_student("bob")
    simulator.launch(user: "bob")
    launch_helper.complete_the_launch_locally

    bob_user = launch_helper.get_user("bob")
    stub_perf_report([{period: "1st", user: bob_user, score: 0.9111}])

    simulator.fail_when_receive_score_for_dropped_student!
    simulator.drop_student("bob")

    # Should still get it
    simulator.expect_to_receive_score(user: "bob", assignment: "tutor", score: 0.9111)

    ActionMailer::Base.deliveries.clear

    api_put("/api/lms/courses/#{course.id}/push_scores", teacher_token)
    expect(response).to have_http_status :accepted

    expect_job_info(errors: [a_hash_including("lms_description" => /User is dropped/)],
                    data: {"num_callbacks" => 1, "num_missing_scores" => 0})

    expect(ActionMailer::Base.deliveries.count).to eq 1
    expect(ActionMailer::Base.deliveries.last.subject).to eq "[Tutor] (test) Lms::SendCourseScores errors"
  end

  it 'copes with exceptions when sending errors' do
    simulator.add_student("bob")
    simulator.launch(user: "bob")
    launch_helper.complete_the_launch_locally

    bob_user = launch_helper.get_user("bob")
    stub_perf_report([{period: "1st", user: bob_user, score: 0.9111}])

    allow_any_instance_of(Lms::SendCourseScores).to receive(:basic_outcome_xml) { raise "Wowsers!" }

    api_put("/api/lms/courses/#{course.id}/push_scores", teacher_token)
    expect(response).to have_http_status :accepted

    expect_job_info(errors: [a_hash_including("unhandled_error" => "Wowsers!")])
  end

  def expect_job_info(errors: [], progress: 1.0, data: nil)
    job_status_id = response.body_as_hash[:job].match(/api\/jobs\/(.*)/)[1]
    job_status = Jobba.find(job_status_id)

    expect(job_status.errors).to match a_collection_including(*errors)
    expect(job_status.progress).to eq progress
    expect(job_status.data).to match a_hash_including(data) if data.present?
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
            course_average: entry[:score]
          }
        end
      })
    end

    allow(Tasks::GetTpPerformanceReport).to receive(:[]) { report }
  end

end
