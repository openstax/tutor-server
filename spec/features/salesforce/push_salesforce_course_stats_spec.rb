require 'rails_helper'
require 'vcr_helper'

RSpec.describe "PushSalesforceCourseStats", vcr: VCR_OPTS do

  before(:all) do
    VCR.use_cassette('PushSalesforceCourseStats/sf_setup', VCR_OPTS) do
      @proxy = SalesforceProxy.new
      load_salesforce_user
      @proxy.ensure_books_exist(%w(Chemistry Physics))
      @proxy.ensure_schools_exist(["JP University"])
    end

    @uuids = 300.times.map{ SecureRandom.uuid }
    VCR.configure do |config|
      @uuids.each_with_index{|uuid,ii| config.define_cassette_placeholder("<UUID_#{ii}>") { uuid }}
    end
  end

  before(:each) { load_salesforce_user }

  let(:sf_contact_a) { @proxy.new_contact }
  let(:chemistry_offering) { FactoryGirl.create(:catalog_offering, salesforce_book_name: "Chemistry") }
  let(:user_sf_a) { FactoryGirl.create(:user, salesforce_contact_id: sf_contact_a.id)}
  let(:user_no_sf) { FactoryGirl.create(:user)}

  let!(:course) {
    FactoryGirl.create :course_profile_course,
                       term: :spring,
                       year: 2017,
                       starts_at: Chronic.parse("January 1, 2017"),
                       offering: chemistry_offering,
                       is_concept_coach: false,
                       estimated_student_count: 42,
                       uuid: @uuids.shift
  }

  before(:each) {
    period1 = CreatePeriod[course: course]
    p1students = 4.times.map { AddUserAsPeriodStudent[user: FactoryGirl.create(:user), period: period1] }

    p1students[0].student.update_attribute(:is_paid, true)
    p1students[1].student.update_attribute(:is_comped, true)
    p1students[2].student.update_attribute(:is_comped, true)
    p1students[3].student.update_attribute(:first_paid_at, Time.now) # refunded

    period2 = CreatePeriod[course: course]
    p2students = 2.times.map { AddUserAsPeriodStudent[user: FactoryGirl.create(:user), period: period1] }

    CourseMembership::InactivateStudent[student: p2students.first.student]

    MoveStudent[student: p1students.first.student, period: period2]

    period3 = CreatePeriod[course: course]
    6.times { AddUserAsPeriodStudent[user: FactoryGirl.create(:user), period: period3] }

    period3.to_model.destroy
  }

  context "when there is no existing OSA" do

    before(:each) do
      AddUserAsCourseTeacher[course: course, user: user_sf_a]
    end

    context "when there is no existing IA" do
      it 'makes both and pushes stats' do
        call_expecting_no_errors

        ias = OpenStax::Salesforce::Remote::IndividualAdoption.where(
          contact_id: user_sf_a.account.salesforce_contact_id
        ).to_a

        expect(ias.size).to eq 1
        ia = ias.first

        expect(ia.id).not_to be_blank
        expect(ia.source).to eq "Tutor Signup"
        expect(ia.book_name).to eq "Chemistry"
        expect(ia.school.name).to eq "JP University"
        expect(ia.contact_id).not_to be_blank
        expect(ia.adoption_level).to eq "Confirmed Adoption Won"

        osa = OpenStax::Salesforce::Remote::OsAncillary.where(individual_adoption_id: ia.id).first

        expect_osa_stats(osa)
        expect_osa_attachment(osa,course)
      end
    end

    context "when there is an existing IA" do
      let!(:ia) { create_chemistry_ia }

      it 'makes an OSA and pushes stats' do
        call_expecting_no_errors

        # The term start date should have been set on the IA during the call; check
        # adoption level and description just to make sure, but would probably have
        # exploded if they didn't get set.

        ia.reload
        expect(ia.adoption_level).not_to be_blank
        expect(ia.description).not_to be_blank

        osa = OpenStax::Salesforce::Remote::OsAncillary.where(individual_adoption_id: ia.id).first

        expect_osa_stats(osa)
      end

      it 'errors when cannot make an OSA' do
        allow_any_instance_of(OpenStax::Salesforce::Remote::OsAncillary).to receive(:save) { false }
        call_expecting_errors(/Could not make new OsAncillary/)
      end
    end

  end

  context "when there is an existing OSA" do
    before(:each) do
      AddUserAsCourseTeacher[course: course, user: user_sf_a]
    end

    let!(:ia) { create_chemistry_ia }
    let!(:osa) { create_osa(ia, course, sf_contact_a) }

    it 'pushes stats if not yet attached' do
      call_expecting_no_errors
      osa.reload
      expect_osa_stats(osa)
      expect_osa_attachment(osa,course)
    end

    it 'pushes stats if already attached' do
      Salesforce::AttachRecord[record: osa, to: course]
      expect_any_instance_of(PushSalesforceCourseStats).not_to receive(:best_sf_contact_id_for_course)
      call_expecting_no_errors
      expect_osa_stats(osa)
    end

    it 'recovers if the attached OSA no longer exists' do
      Salesforce::AttachRecord[record: osa, to: course]
      osa.destroy
      call_expecting_no_errors
      new_osas = OpenStax::Salesforce::Remote::OsAncillary.where(individual_adoption_id: ia.id).to_a
      expect(new_osas.size).to eq 1
      new_osa = new_osas.first
      expect(new_osa.id).not_to eq osa.id
      expect_osa_stats(new_osa)
    end

    it 'handle exceptions around saving final stats' do
      # convenient to have the test here b/c of the setup that exists in this context
      allow_any_instance_of(OpenStax::Salesforce::Remote::OsAncillary).to receive(:changed?) { raise "kaboom" }
      call_expecting_errors
    end

    it 'handles final OSA save errors' do
      allow_any_instance_of(OpenStax::Salesforce::Remote::OsAncillary).to receive(:save).and_wrap_original do |m, *args|
        m.call(*args)
        m.receiver.errors.add(:base, "Test Error")
        false
      end

      call_expecting_errors(/Test Error/)
    end

    it 'is ok with another course being in the same term same teacher' do
      other_course =
        FactoryGirl.create :course_profile_course,
                           term: :spring,
                           year: 2017,
                           starts_at: Chronic.parse("January 1, 2017"),
                           offering: chemistry_offering,
                           is_concept_coach: false,
                           uuid: @uuids.shift
      AddUserAsCourseTeacher[course: other_course, user: user_sf_a]

      call_expecting_no_errors

      expect(OpenStax::Salesforce::Remote::OsAncillary.where(individual_adoption_id: ia.id).count).to eq 2
    end
  end

  context "skips happen" do
    it "skips courses that have no teachers" do
      call_expecting_skips("No teachers")
    end
  end

  context "errors happen" do
    it 'continues processing later courses when an earlier one errors' do
      AddUserAsCourseTeacher[course: course, user: user_sf_a]
      allow_any_instance_of(PushSalesforceCourseStats).to receive(:applicable_courses) {
        [nil, course]
      }
      expect_any_instance_of(PushSalesforceCourseStats).to receive(:call_for_course).twice.and_call_original

      counts = call

      expect(counts).to eq ({ num_courses: 2, num_updates: 1, num_errors: 1, num_skips: 0})
    end

    it 'errors when no teacher SF contact' do
      AddUserAsCourseTeacher[course: course, user: user_no_sf]
      call_expecting_errors(/No teachers have a SF contact ID/)
    end

    # it 'errors when multiple IAs match' do
    #   # Changes made to SF now prohibit duplicate IAs being made in this way, so commenting
    #   # out this spec
    #   2.times { create_chemistry_ia }
    #   AddUserAsCourseTeacher[course: course, user: user_sf_a]
    #   call_expecting_errors(/Too many IndividualAdoptions/)
    # end

    it 'errors when it cannot save a new IA' do
      AddUserAsCourseTeacher[course: course, user: user_sf_a]
      allow_any_instance_of(OpenStax::Salesforce::Remote::Contact).to receive(:school_id).and_return(nil)
      capture_stdout{ call_expecting_errors(/Could not make new IndividualAdoption for inputs/) }
    end

    it 'errors when no offering' do
      AddUserAsCourseTeacher[course: course, user: user_sf_a]
      course.offering = nil
      course.save!
      call_expecting_errors(/No offering/)
    end

    context "when there is an error (no teacher with SF contact)" do
      before(:each) { AddUserAsCourseTeacher[course: course, user: user_no_sf] }

      it 'does not send error email in non-production' do
        expect{
          call_expecting_errors
        }.to change { ActionMailer::Base.deliveries.count }.by(0)
      end

      it 'does send error email in production' do
        allow(Rails.application.secrets).to receive(:environment_name) { 'prodtutor' }
        expect{
          call_expecting_errors
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context "when there is an error in writing stats" do
      it 'writes the error to the OSA' do
        allow(UrlGenerator).to receive(:teach_course_url) { raise "kaboom" }
        AddUserAsCourseTeacher[course: course, user: user_sf_a]
        call_expecting_errors

        ia = OpenStax::Salesforce::Remote::IndividualAdoption.where(
          contact_id: user_sf_a.account.salesforce_contact_id
        ).to_a.first
        osa = OpenStax::Salesforce::Remote::OsAncillary.where(individual_adoption_id: ia.id).first

        expect(osa.error).to match /Unable to update stats: kaboom/
      end
    end

  end


  #### HELPERS ####

  def create_chemistry_ia
    OpenStax::Salesforce::Remote::IndividualAdoption.new(
      contact_id: sf_contact_a.id,
      fall_start_date: "2016-08-01",
      book_id: @proxy.book_id("Chemistry"),
      school_id: @proxy.school_id("JP University"),
      adoption_level: "Confirmed Adoption Won",
      description: "blah"
    ).tap do |ia|
      if !ia.save
        raise "didn't save IA"
      end
    end
  end

  def create_osa(ia, course, contact)
    OpenStax::Salesforce::Remote::OsAncillary.new(
      individual_adoption_id: ia.id,
      product: course.is_concept_coach ? "Concept Coach" : "Tutor",
      contact_id: contact.id,
      course_uuid: course.uuid,
      term: "Spring"
    ).tap do |osa|
      if !osa.save
        raise "didn't save OSA"
      end
    end
  end

  def call
    PushSalesforceCourseStats.call(allow_error_email: true)
  end

  def call_expecting_no_errors
    instance = PushSalesforceCourseStats.new(allow_error_email: true)
    expect(instance).not_to receive(:error!)
    instance.call
  end

  def call_expecting_errors(error_messages = [anything()])
    error_messages = [error_messages].flatten
    raise "nyi" if error_messages.size != 1
    instance = PushSalesforceCourseStats.new(allow_error_email: true)
    expect(instance)
      .to receive(:error!)
      .with(hash_including(message: error_messages.first))
      .and_call_original
    instance.call
  end

  def call_expecting_skips(skip_messages = [anything()])
    skip_messages = [skip_messages].flatten
    raise "nyi" if skip_messages.size != 1
    instance = PushSalesforceCourseStats.new(allow_error_email: true)
    expect(instance)
      .to receive(:skip!)
      .with(hash_including(message: skip_messages.first))
      .and_call_original
    instance.call
  end

  def expect_osa_stats(osa)
    expect(osa).not_to be_nil
    osa.reload # make sure we have what actually made it to SF

    expect(osa.num_sections).to eq 2
    expect(osa.num_students).to eq 6
    expect(osa.num_students_paid).to eq 1
    expect(osa.num_students_comped).to eq 2
    expect(osa.num_students_refunded).to eq 1
    expect(osa.num_teachers).to eq 1
    expect(osa.estimated_enrollment).to eq 42
    expect(osa.course_id).to be_a(String)
    expect(osa.created_at).to be_a(Date)
    expect(osa.teacher_join_url).to be_a(String)
    expect(osa.status).to be_a(String)
    expect(osa.product).to eq "Tutor"
    expect(osa.error).to be nil
    expect(osa.term).to be_a(String)
    expect(osa.course_start_date).to eq Date.parse("2017-01-01")
    expect(osa.base_year).to eq 2016
  end

  def expect_osa_attachment(osa, course)
    expect(Salesforce::Models::AttachedRecord.count).to eq 1
    ar = Salesforce::Models::AttachedRecord.first
    expect(ar.salesforce_class_name).to eq 'OpenStax::Salesforce::Remote::OsAncillary'
    expect(ar.salesforce_id).to eq osa.id
    expect(ar.tutor_gid).to eq course.to_global_id.to_s
  end

end
