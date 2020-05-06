require 'rails_helper'

RSpec.describe Api::V1::Lms::CoursesController, type: :request, api: true, version: :v1 do
  let(:course)   { FactoryBot.create :course_profile_course }
  let!(:lms_app) { FactoryBot.create(:lms_app, owner: course) }
  let(:user)     { FactoryBot.create(:user_profile) }
  let(:token)    { FactoryBot.create(:doorkeeper_access_token, resource_owner_id: user.id) }

  let(:willo)          { Lms::WilloLabs.new }
  let(:launch_request) { FactoryBot.create(:launch_request, app: willo) }

  let!(:teacher)       { AddUserAsCourseTeacher[course: course, user: user].teacher }

  context '#course' do
    it 'allows teachers to retrieve secrets' do
      api_get api_lms_course_url(course.id), token
      expect(response).to have_http_status(:ok)

      expect(
        response.body_as_hash
      ).to match(
        a_hash_including(
          key: lms_app.key,
          secret: lms_app.secret
        )
      )

    end

    it 'rejects non-teachers' do
      teacher.really_destroy!

      expect do
        api_get api_lms_course_url(course.id), token
      end.to raise_error(SecurityTransgression)
    end
  end

  context '#pair' do
    it 'pairs a course to lms' do
      sign_in! user

      # Need to make this request first to store the launch_id in the session
      expect_any_instance_of(
        ::IMS::LTI::Services::MessageAuthenticator
      ).to receive(:valid_signature?).and_return(true)
      post lms_launch_url, params: launch_request.request_parameters
      expect(session[:launch_id]).not_to be_nil

      api_post pair_api_lms_course_url(course.id), token
      expect(response.body_as_hash[:success]).to eq true

      lms_launch = Lms::Launch.from_id(session[:launch_id]).validate!
      expect(lms_launch.context.reload.course).to eq course
      expect(course.reload.is_lms_enabled).to be true
    end
  end

  context 'lms score push' do
    let(:teacher_token) do
      FactoryBot.create :doorkeeper_access_token, resource_owner_id: teacher.role.user_profile_id
    end

    let(:simulator)     { Lms::Simulator.new(self) }
    let(:launch_helper) { Lms::LaunchHelper.new(self) }

    before do
      course.update_attribute :is_lms_enabled, true

      simulator.install_tutor(app: lms_app, course: "physics")
      simulator.set_launch_defaults(course: "physics", assignment: "tutor")
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

      allow(Tasks::GetPerformanceReport).to receive(:[]) { report }
    end

    it 'works for one user who has a score' do
      simulator.add_student("bob")
      simulator.launch(user: "bob")
      launch_helper.complete_the_launch_locally

      bob_user = launch_helper.get_user("bob")
      stub_perf_report([{period: "1st", user: bob_user, score: 0.9111}])

      expect(course.last_lms_scores_push_job_id).to be_blank
      simulator.expect_to_receive_score(user: "bob", assignment: "tutor", score: 0.9111)

      api_put(push_scores_api_lms_course_url(course.id), teacher_token)
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

      api_put(push_scores_api_lms_course_url(course.id), teacher_token)
      expect(response).to have_http_status :accepted

      expect_job_info(data: {"num_callbacks" => 2, "num_missing_scores" => 0})
    end

    it 'notes when a score cannot be sent because it is not yet in the perf report' do
      simulator.add_student("bob")
      simulator.launch(user: "bob")
      launch_helper.complete_the_launch_locally

      bob_user = launch_helper.get_user("bob")
      stub_perf_report([{period: "1st", user: FactoryBot.create(:user_profile), score: 0}])

      simulator.expect_not_to_receive_score(user: "bob", assignment: "tutor")

      api_put(push_scores_api_lms_course_url(course.id), teacher_token)
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

      expect(Raven).to receive(:capture_message) do |message, *|
        expect(message).to eq 'User is dropped'
      end
      expect do
        api_put(push_scores_api_lms_course_url(course.id), teacher_token)
      end.not_to change { ActionMailer::Base.deliveries.count }
      expect(response).to have_http_status :accepted

      expect_job_info(errors: [a_hash_including("message" => /User is dropped/)],
                      data: {"num_callbacks" => 1, "num_missing_scores" => 0})
    end

    it 'copes with exceptions when sending errors' do
      simulator.add_student("bob")
      simulator.launch(user: "bob")
      launch_helper.complete_the_launch_locally

      bob_user = launch_helper.get_user("bob")
      stub_perf_report([{period: "1st", user: bob_user, score: 0.9111}])

      allow_any_instance_of(Lms::SendCourseScores).to receive(:basic_outcome_xml) { raise "Wowsers!" }

      expect(Raven).to receive(:capture_exception) do |exception, *|
        expect(exception).to be_a(RuntimeError)
        expect(exception.message).to eq 'Wowsers!'
      end
      expect do
        api_put(push_scores_api_lms_course_url(course.id), teacher_token)
      end.not_to change { ActionMailer::Base.deliveries.count }
      expect(response).to have_http_status :accepted

      expect_job_info(errors: [a_hash_including("message" => "Wowsers!")])
    end
  end
end
