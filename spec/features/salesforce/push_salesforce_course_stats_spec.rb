require 'rails_helper'
require 'vcr_helper'

RSpec.describe "PushSalesforceCourseStats", vcr: VCR_OPTS do

  before(:all) { @sfh = SalesforceHelper.new }

  before(:each) { load_salesforce_user }
  before(:each) { @sfh.ensure_books_exist(%w(Chemistry Physics)) }
  before(:each) { @sfh.ensure_schools_exist(["JP University"])}

  let(:sf_contact_a) { @sfh.new_contact }
  let(:chemistry_offering) { FactoryGirl.create(:catalog_offering, salesforce_book_name: "Chemistry") }
  let(:user_sf_a) { FactoryGirl.create(:user, salesforce_contact_id: sf_contact_a.id)}
  let(:user_no_sf) { FactoryGirl.create(:user)}

  let!(:course) {
    FactoryGirl.create :course_profile_course,
                       term: :spring,
                       year: 2017,
                       offering: chemistry_offering,
                       is_concept_coach: false
  }

  before(:each) {
    period1 = CreatePeriod[course: course]
    p1students = 4.times.map { AddUserAsPeriodStudent[user: FactoryGirl.create(:user), period: period1] }

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

        ias = Salesforce::Remote::IndividualAdoption.where(
          contact_id: user_sf_a.account.salesforce_contact_id
        ).to_a

        expect(ias.size).to eq 1
        ia = ias.first

        osa = Salesforce::Remote::OsAncillary.where(individual_adoption_id: ia.id).first

        expect_osa_stats(osa)
        expect_osa_attachment(osa,course)
      end
    end

    context "when there is an existing IA" do
      let!(:ia) {
        Salesforce::Remote::IndividualAdoption.new(
          contact_id: sf_contact_a.id,
          class_start_date: "2017-01-01",
          book_id: @sfh.book_id("Chemistry"),
          school_id: @sfh.school_id("JP University")
        ).tap do |ia|
          if !ia.save
            raise "didn't save IA"
          end
        end
      }

      it 'makes an OSA and pushes stats' do
        call_expecting_no_errors

        osa = Salesforce::Remote::OsAncillary.where(individual_adoption_id: ia.id).first

        expect_osa_stats(osa)
      end
    end

  end

  context "when there is an existing OSA" do
    before(:each) do
      AddUserAsCourseTeacher[course: course, user: user_sf_a]
    end

    let!(:ia) {
      Salesforce::Remote::IndividualAdoption.new(
        contact_id: sf_contact_a.id,
        class_start_date: "2017-01-01",
        book_id: @sfh.book_id("Chemistry"),
        school_id: @sfh.school_id("JP University")
      ).tap do |ia|
        if !ia.save
          raise "didn't save IA"
        end
      end
    }

    let!(:osa) {
      Salesforce::Remote::OsAncillary.new(
        individual_adoption_id: ia.id,
        product: "Tutor"
      ).tap do |osa|
        if !osa.save
          raise "didn't save OSA"
        end
      end
    }

    it 'pushes stats if not yet attached' do
      call_expecting_no_errors
      expect_osa_stats(osa)
      expect_osa_attachment(osa,course)
    end

    it 'pushes stats if already attached' do
      Salesforce::AttachRecord[record: osa, to: course]
      expect_any_instance_of(PushSalesforceCourseStats).not_to receive(:best_sf_contact_id_for_course)
      call_expecting_no_errors
      expect_osa_stats(osa)
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

      expect(counts).to eq ({ num_courses: 2, num_updates: 1, num_errors: 1})
    end

    it 'errors when no teacher SF contact' do
      AddUserAsCourseTeacher[course: course, user: user_no_sf]
      call_expecting_errors
    end

    it 'errors when multiple IAs match' do
      2.times {
        Salesforce::Remote::IndividualAdoption.new(
          contact_id: sf_contact_a.id,
          class_start_date: "2017-01-01",
          book_id: @sfh.book_id("Chemistry"),
          school_id: @sfh.school_id("JP University")
        ).tap do |ia|
          if !ia.save
            raise "didn't save IA"
          end
        end
      }
      AddUserAsCourseTeacher[course: course, user: user_sf_a]
      call_expecting_errors
    end

    it 'errors when it cannot save a new IA' do
      AddUserAsCourseTeacher[course: course, user: user_sf_a]
      allow_any_instance_of(Salesforce::Remote::Contact).to receive(:school_id).and_return(nil)
      capture_stdout{ call_expecting_errors }
    end

    it 'errors when multiple OSAs match' do
      AddUserAsCourseTeacher[course: course, user: user_sf_a]

      ia = create_chemistry_ia
      2.times { create_osa(ia, course) }

      call_expecting_errors
    end

    context "when there is an error (no teacher)" do
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

  end


  #### HELPERS ####

  def create_chemistry_ia
    Salesforce::Remote::IndividualAdoption.new(
      contact_id: sf_contact_a.id,
      class_start_date: "2017-01-01",
      book_id: @sfh.book_id("Chemistry"),
      school_id: @sfh.school_id("JP University")
    ).tap do |ia|
      if !ia.save
        raise "didn't save IA"
      end
    end
  end

  def create_osa(ia, course)
    Salesforce::Remote::OsAncillary.new(
      individual_adoption_id: ia.id,
      product: course.is_concept_coach ? "Concept Coach" : "Tutor"
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
    expect_any_instance_of(PushSalesforceCourseStats).not_to receive(:error!)
    call
  end

  def call_expecting_errors(num_errors=1)
    raise "nyi" if num_errors != 1
    expect_any_instance_of(PushSalesforceCourseStats).to receive(:error!).and_call_original
    call
  end

  def expect_osa_stats(osa)
    expect(osa).not_to be_nil
    osa.reload # make sure we have what actually made it to SF

    expect(osa.num_sections).to eq 2
    expect(osa.num_students).to eq 6
    expect(osa.num_teachers).to eq 1
    expect(osa.course_id).to be_a(String)
    expect(osa.created_at).to be_a(Date)
    expect(osa.teacher_join_url).to be_a(String)
    expect(osa.status).to be_a(String)
    expect(osa.product).to eq "Tutor"
    expect(osa.error).to be nil
  end

  def expect_osa_attachment(osa, course)
    expect(Salesforce::Models::AttachedRecord.count).to eq 1
    ar = Salesforce::Models::AttachedRecord.first
    expect(ar.salesforce_class_name).to eq 'Salesforce::Remote::OsAncillary'
    expect(ar.salesforce_id).to eq osa.id
    expect(ar.tutor_gid).to eq course.to_global_id.to_s
  end

end
