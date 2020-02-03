require 'rails_helper'
require 'vcr_helper'

RSpec.describe 'PushSalesforceCourseStats', vcr: VCR_OPTS do
  before(:all) do
    VCR.use_cassette('PushSalesforceCourseStats/sf_setup', VCR_OPTS) do
      VCR.configure do |config|
        config.define_cassette_placeholder('<salesforce_instance_url>') do
          'https://example.salesforce.com'
        end
        config.define_cassette_placeholder('<salesforce_instance_url_lower>') do
          'https://example.salesforce.com'
        end
        authentication = ActiveForce.sfdc_client.authenticate!
        config.define_cassette_placeholder('<salesforce_instance_url>') do
          authentication.instance_url
        end
        config.define_cassette_placeholder('<salesforce_instance_url_lower>') do
          authentication.instance_url.downcase
        end
        config.define_cassette_placeholder('<salesforce_id>' ) do
          authentication.id
        end
        config.define_cassette_placeholder('<salesforce_access_token>') do
          authentication.access_token
        end
        config.define_cassette_placeholder('<salesforce_signature>' ) do
          authentication.signature
        end

        @proxy = SalesforceProxy.new
        @proxy.ensure_books_exist(%w(Chemistry Physics))
        @proxy.ensure_schools_exist(["JP University"])

        [ :course, :period1, :period2, :period3, :other_course, :other_period].each do |uuid_name|
          uuid = SecureRandom.uuid
          instance_variable_set "@#{uuid_name}_uuid".to_sym, uuid
          config.define_cassette_placeholder("<#{uuid_name.upcase}_UUID>") { uuid }
        end
      end
    end
  end

  let(:instance)     { PushSalesforceCourseStats.new }
  let(:sf_contact_a) { @proxy.new_contact }
  let(:chemistry_offering) do
    FactoryBot.create(:catalog_offering, salesforce_book_name: "Chemistry")
  end
  let(:user_sf_a) { FactoryBot.create(:user_profile, salesforce_contact_id: sf_contact_a.id)}
  let(:user_no_sf) { FactoryBot.create(:user_profile)}

  let!(:course) do
    FactoryBot.create :course_profile_course,
                       name: "A Fun Course",
                       term: :spring,
                       year: 2017,
                       starts_at: Time.parse("January 1, 2017"),
                       offering: chemistry_offering,
                       is_concept_coach: false,
                       estimated_student_count: 42,
                       does_cost: true,
                       uuid: @course_uuid,
                       latest_adoption_decision: "For course credit"
  end
  let!(:period_uuids) { [ @period1_uuid, @period2_uuid, @period3_uuid ] }

  before do
    @period1 = CreatePeriod[course: course, uuid: period_uuids.first]
    p1students = 4.times.map do
      AddUserAsPeriodStudent[user: FactoryBot.create(:user_profile), period: @period1]
    end
    p1students[0].student.update_attribute(:is_paid, true)
    p1students[1].student.update_attribute(:is_comped, true)
    p1students[2].student.update_attribute(:is_comped, true)
    p1students[3].student.update_attribute(:first_paid_at, Time.now) # refunded
    # Add two fake tasks to test reporting of students with work (one above, one below threshold)
    [
      [p1students[0], 10],
      [p1students[1], 3], # this student should have enough across 2 tasks
      [p1students[1], 7],
      [p1students[2], 9]
    ].each do |student, num_steps|
      task = FactoryBot.build :tasks_task,
                              title: "A",
                              task_type: :homework,
                              task_plan: nil,
                              tasked_to: student,
                              completed_steps_count: num_steps
      task.save validate: false
    end

    @period2 = CreatePeriod[course: course, uuid: period_uuids.second]
    p2students = 2.times.map do
      AddUserAsPeriodStudent[user: FactoryBot.create(:user_profile), period: @period1]
    end
    p2students.each { |user| MoveStudent[student: user.student, period: @period2] }
    CourseMembership::InactivateStudent[student: p2students.first.student]

    @period3 = CreatePeriod[course: course, uuid: period_uuids.third]
    6.times { AddUserAsPeriodStudent[user: FactoryBot.create(:user_profile), period: @period3] }
    @period3.destroy
  end

  context "when there is no existing TutorCoursePeriod" do
    before { AddUserAsCourseTeacher[course: course, user: user_sf_a] }

    it 'creates it and pushes stats' do
      call_expecting_no_errors

      expect(OpenStax::Salesforce::Remote::TutorCoursePeriod.where(course_uuid: course.uuid).count)
        .to eq 3
      expect_tcp_stats(@period1, num_students: 4, num_students_paid: 1, num_students_comped: 2,
                       num_students_refunded: 1, num_students_dropped: 0, num_students_with_work: 2)
      expect_tcp_stats(@period2, num_students: 2, num_students_paid: 0, num_students_comped: 0,
                       num_students_refunded: 0, num_students_dropped: 1, num_students_with_work: 0)
      expect_tcp_stats(@period3, num_students: 6, num_students_paid: 0, num_students_comped: 0,
                       num_students_refunded: 0, num_students_dropped: 0, num_students_with_work: 0)
    end
  end

  context "when there is an existing TutorCoursePeriod" do
    # TutorCoursePeriods already created by the spec above
    before(:each) { AddUserAsCourseTeacher[course: course, user: user_sf_a] }

    it 'pushes stats' do
      call_expecting_no_errors

      expect_tcp_stats(@period1, num_students: 4, num_students_paid: 1, num_students_comped: 2,
                       num_students_refunded: 1, num_students_dropped: 0, num_students_with_work: 2)
      expect_tcp_stats(@period2, num_students: 2, num_students_paid: 0, num_students_comped: 0,
                       num_students_refunded: 0, num_students_dropped: 1, num_students_with_work: 0)
      expect_tcp_stats(@period3, num_students: 6, num_students_paid: 0, num_students_comped: 0,
                       num_students_refunded: 0, num_students_dropped: 0, num_students_with_work: 0)
    end

    it 'handle exceptions around saving final stats' do
      # convenient to have the test here b/c of the setup that exists in this context
      exception = RuntimeError.new('kaboom')
      allow_any_instance_of(OpenStax::Salesforce::Remote::TutorCoursePeriod).to(
        receive(:changed?) { raise exception }
      )
      call_expecting_errors(exception: exception)
    end

    it 'handles final TCP save errors' do
      allow_any_instance_of(OpenStax::Salesforce::Remote::TutorCoursePeriod).to(
        receive(:save).and_wrap_original do |m, *args|
          m.call(*args)
          m.receiver.errors.add(:base, "Test Error")
          false
        end
      )

      call_expecting_errors(/Test Error/)
    end

    it 'is ok with another course being in the same term same teacher' do
      other_course =
        FactoryBot.create :course_profile_course,
                           term: :spring,
                           year: 2017,
                           starts_at: Time.parse("January 1, 2017"),
                           offering: chemistry_offering,
                           is_concept_coach: false,
                           uuid: @other_course_uuid
      other_period = FactoryBot.create :course_membership_period,
                                       course: other_course,
                                       uuid: @other_period_uuid
      AddUserAsCourseTeacher[course: other_course, user: user_sf_a]

      call_expecting_no_errors

      expect(
        OpenStax::Salesforce::Remote::TutorCoursePeriod.where(
          period_uuid: period_uuids + [ other_period.uuid ]
        ).count
      ).to eq 4
    end

    it 'is ok with no offering' do
      course.offering = nil
      course.save!
      call_expecting_no_errors
    end
  end

  context "skips happen" do
    it "skips courses that have no teachers" do
      call_expecting_skips("No teachers")
    end

    context 'when no teachers have a SF Contact ID' do
      before(:each) { AddUserAsCourseTeacher[course: course, user: user_no_sf] }

      it 'does not log the error to Sentry or send error emails' do
        expect(Raven).not_to receive(:capture_message)
        expect(Raven).not_to receive(:capture_exception)
        expect do
          call_expecting_skips(/No teachers have a SF contact ID/)
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end
  end

  context "errors happen" do
    it 'continues processing later courses when an earlier one errors' do
      broken_course = FactoryBot.create :course_profile_course
      AddUserAsCourseTeacher[course: course, user: user_sf_a]
      expect(broken_course).to receive(:teachers) { raise 'boom' }
      allow_any_instance_of(PushSalesforceCourseStats).to receive(:applicable_courses) do
        [broken_course, course]
      end

      outputs = call.outputs
      expect(outputs.num_courses).to eq 2
      expect(outputs.num_periods).to eq 3
      expect(outputs.num_updates).to eq 3
      expect(outputs.num_errors).to eq 1
      expect(outputs.num_skips).to eq 0
    end

    context "when there is an error in writing stats" do
      it 'writes the error to the TCP, logs the error to Sentry and does not send error emails' do
        allow_any_instance_of(OpenStax::Salesforce::Remote::TutorCoursePeriod).to(
          receive(:reset_stats) { raise "kaboom" }
        )
        AddUserAsCourseTeacher[course: course, user: user_sf_a]
        expect(Raven).to receive(:capture_exception).at_least(:once) do |exception, *|
          expect(exception).to be_a RuntimeError
          expect(exception.message).to eq 'kaboom'
        end
        expect do
          call_expecting_errors(/Unable to update stats: kaboom/)
        end.not_to change { ActionMailer::Base.deliveries.count }

        OpenStax::Salesforce::Remote::TutorCoursePeriod
          .where(period_uuid: period_uuids)
          .each { |tcp| expect(tcp.error).to match /Unable to update stats: kaboom/ }
      end
    end
  end


  #### HELPERS ####

  def call
    PushSalesforceCourseStats.call
  end

  def call_expecting_no_errors
    expect(instance).not_to receive(:error!)
    instance.call
  end

  def call_expecting_errors(hash_or_message)
    hash = hash_or_message.is_a?(Hash) ? hash_or_message : { message: hash_or_message }
    expect(instance).to receive(:error!).at_least(:once)
                                        .with(hash_including(hash))
                                        .and_call_original

    instance.call
  end

  def call_expecting_skips(hash_or_message)
    hash = hash_or_message.is_a?(Hash) ? hash_or_message : { message: hash_or_message }
    expect(instance).to receive(:skip!).at_least(:once)
                                       .with(hash_including(hash))
                                       .and_call_original

    instance.call
  end

  def expect_tcp_stats(period, extras = {})
    tcp = OpenStax::Salesforce::Remote::TutorCoursePeriod.where(period_uuid: period.uuid).first
    expect(tcp).not_to be_nil

    expect(tcp.base_year).to eq 2016
    expect(tcp.book_name).to eq "Chemistry"
    expect(tcp.contact_id).to eq sf_contact_a.id
    expect(tcp.course_id).to be_a(String)
    expect(tcp.course_name).to eq course.name
    expect(tcp.course_start_date).to eq Date.parse("2017-01-01")
    expect(tcp.course_uuid).to eq course.uuid
    expect(tcp.does_cost).to eq true
    expect(tcp.estimated_enrollment).to eq 14
    expect(tcp.latest_adoption_decision).to eq "For course credit"
    expect(tcp.num_periods).to eq 3
    expect(tcp.num_teachers).to eq 1
    expect(tcp.term).to be_a(String)

    expect(tcp.error).to be nil
    expect(tcp.created_at).to be_a(Date)
    expect(tcp.status).to be_a(String)

    expect(tcp.attributes).to match hash_including(extras.stringify_keys)
  end
end
