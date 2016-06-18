require 'rails_helper'

RSpec.describe UpdateSalesforceCourseStats, type: :routine do

  context "big test" do
    let!(:course_1) { Entity::Course.create! }

    let!(:period_1) { CreatePeriod[course: course_1] }
    let!(:period_2) { CreatePeriod[course: course_1] }
    let!(:user_1)   { FactoryGirl.create :user }
    let!(:user_2)   { FactoryGirl.create :user }

    let!(:student_1_role) { AddUserAsPeriodStudent[user: user_1, period: period_1] }
    let!(:enrollment_1)   { student_1_role.student.latest_enrollment }

    let!(:student_2_role) { AddUserAsPeriodStudent[user: user_2, period: period_2] }
    let!(:enrollment_2)   { student_2_role.student.latest_enrollment }

    before(:each) do
      osa = Salesforce::Remote::OsAncillary.new(
              product: "Concept Coach", account_type: "High School", id: "123",
              opportunity: Salesforce::Remote::Opportunity.new(term_year: '2016 - 17 Fall')
            )

      allow_any_instance_of(UpdateSalesforceCourseStats).to receive(:attached_records).and_return(
        [
          FactoryGirl.create(:salesforce_attached_record, tutor_object: period_1.to_model, salesforce_object: osa),
          FactoryGirl.create(:salesforce_attached_record, tutor_object: course_1, salesforce_object: osa),
        ]
      )

      allow(Salesforce::RenewOsAncillary).to receive(:call) {
        Salesforce::Remote::OsAncillary.new(product: "Concept Coach", account_type: "High School", id: "42")
      }

      period_1.to_model.destroy
    end

    # TODO test original as ClassSize and OsAncillary

    it "works" do
      outputs = described_class.call

      expect(outputs.num_records).to eq 1
      expect(outputs.num_errors).to eq 0
      expect(outputs.num_updates).to eq 1
    end


    xit "reuses existing SF object when period created before initial cutoff" do
    end

    xit "renews SF object when period created after initial cutoff" do
    end

    xit "works ok if there were no prior periods or ARs" do

    end

    xit "works ok if the period's course has never had an AR" do
    end

  end

  def stub_organizer
    double.tap do |dbl|
      allow_any_instance_of(described_class).to receive(:initialize_organizer) { dbl }
      yield dbl
    end
  end

  context "#attach_orphaned_periods_to_sf_objects" do
    let!(:course)          { Entity::Course.create! }
    let!(:period_1)        { CreatePeriod[course: course] }
    let!(:period_2)        { CreatePeriod[course: course] }
    let!(:period_3)        { CreatePeriod[course: course] }
    let!(:sf_object)       { OpenStruct.new(changed?: true, save: nil) }
    let!(:attached_record) { OpenStruct.new(record: sf_object) }

    before(:each) do
      @organizer = stub_organizer do |organizer|
        allow(organizer).to receive(:orphaned_periods) { [period_3.to_model] }
        allow(organizer).to receive(:get_course) { course }
        allow(organizer).to receive(:get_sf_objects) { [sf_object] }
      end
    end

    it "notifies if no course SF objects" do
      allow(@organizer).to receive(:get_sf_objects) { [] }
      expect_any_instance_of(described_class).to receive(:notify)
                                             .with(a_string_matching(/No Salesforce/), anything())
      described_class.call(write_stats: false)
    end

    it "notifies if too many eligible SF objects" do
      allow(@organizer).to receive(:get_sf_objects) { [
        OpenStruct.new(term_year: Salesforce::Remote::TermYear.from_string("2015 - 16 Fall")),
        OpenStruct.new(term_year: Salesforce::Remote::TermYear.from_string("2015 - 16 Fall")),
      ] }
      allow(Salesforce::Remote::TermYear).to receive(:guess_from_created_at) {
        Salesforce::Remote::TermYear.from_string("2015 - 16 Fall")
      }

      expect_any_instance_of(described_class).to receive(:notify)
                                             .with(a_string_matching(/Multiple Sales/), anything())
      described_class.call(write_stats: false)
    end

    it "reuses an existing eligible SF object" do
      term_year = Salesforce::Remote::TermYear.from_string("2015 - 16 Fall")
      existing_sf_object = OpenStruct.new(term_year: term_year, id: 'foo')

      allow(@organizer).to receive(:get_sf_objects) { [existing_sf_object] }
      allow(Salesforce::Remote::TermYear).to receive(:guess_from_created_at) { term_year.dup }

      expect(Salesforce::RenewOsAncillary).not_to receive(:call)
      expect(Salesforce::AttachRecord).to receive(:[]).with(record: existing_sf_object, to: period_3.to_model)
      expect(@organizer).not_to receive(:set_course_id)
      expect(@organizer).to receive(:add_period_id)

      described_class.call(write_stats: false)
    end

    it "makes a new SF object if no eligible ones available" do
      term_year = Salesforce::Remote::TermYear.from_string("2015 - 16 Fall")
      existing_sf_object = OpenStruct.new(term_year: term_year, id: 'foo')

      allow(@organizer).to receive(:get_sf_objects) { [existing_sf_object] }
      allow(Salesforce::Remote::TermYear).to receive(:guess_from_created_at) { term_year.next }
      allow(Salesforce::RenewOsAncillary).to receive(:call) { Salesforce::Remote::OsAncillary.new(id: 'bar') }

      expect(Salesforce::RenewOsAncillary).to receive(:call)
      expect(Salesforce::AttachRecord).to receive(:[]).twice
      expect(@organizer).to receive(:set_course_id)
      expect(@organizer).to receive(:add_period_id)

      described_class.call(write_stats: false)
    end
  end

  context "#write_stats_to_salesforce" do
    let!(:course)          { Entity::Course.create! }
    let!(:period)          { CreatePeriod[course: course] }
    let!(:record)          { OpenStruct.new(changed?: true, save: nil) }
    let!(:attached_record) { OpenStruct.new(record: record) }

    before(:each) do
      AddUserAsPeriodStudent[user: FactoryGirl.create(:user), period: period]
      AddUserAsPeriodStudent[user: FactoryGirl.create(:user), period: period]
      AddUserAsPeriodStudent[user: FactoryGirl.create(:user), period: period]
      AddUserAsCourseTeacher[user: FactoryGirl.create(:user), course: course]
      AddUserAsCourseTeacher[user: FactoryGirl.create(:user), course: course]

      stub_organizer do |organizer|
        allow(organizer).to receive(:each).and_yield(attached_record, course, [period.to_model])
      end
    end

    it "counts and saves on the happy path" do
      expect(record).to receive(:save)
      outputs = described_class.call(handle_orphaned_periods: false)
      expect(record.num_teachers).to eq 2
      expect(record.num_students).to eq 3
      expect(record.num_sections).to eq 1
      expect(outputs.num_updates).to eq 1
      expect(outputs.num_errors).to eq 0
      expect(outputs.num_records).to eq 1
    end

    it "handles stat update errors if no record" do
      allow(attached_record).to receive(:record).and_raise(StandardError, "howdy")
      outputs = rescuing_exceptions{ described_class.call(handle_orphaned_periods: false) }
      expect(record.error).to be_nil
      expect(outputs.num_errors).to eq 1
    end

    it "handles stat update errors if record" do
      allow(course).to receive(:teachers).and_raise(StandardError, "howdy")
      outputs = rescuing_exceptions{ described_class.call(handle_orphaned_periods: false) }
      expect(record.error).to eq "Unable to update stats: howdy"
      expect(outputs.num_errors).to eq 1
    end

    it "handles errors if save bombs" do
      allow(record).to receive(:save).and_raise(StandardError, "howdy")
      outputs = rescuing_exceptions{ described_class.call(handle_orphaned_periods: false) }
      expect(outputs.num_errors).to eq 1
    end
  end

  context "Organizer" do
    let!(:organizer) { UpdateSalesforceCourseStats::Organizer.new }

    it "has working period methods" do
      fake_period = OpenStruct.new(id: 2)
      organizer.add_period_id(attached_record: "dummy", period_id: fake_period.id)
      organizer.remember_period(fake_period)
      organizer.each do |ar, course, periods|
        expect(ar).to eq "dummy"
        expect(periods).to eq [fake_period]
      end
      expect(organizer.no_attached_record_for_period?(fake_period)).to be_falsy
      expect(organizer.no_attached_record_for_period?(OpenStruct.new(id: 'boo'))).to be_truthy
    end

    it "has working course methods" do
      fake_course = OpenStruct.new(id: 42)
      organizer.set_course_id(attached_record: "dummy", course_id: fake_course.id)
      organizer.remember_course(fake_course)
      organizer.each do |ar, course, periods|
        expect(ar).to eq "dummy"
        expect(course).to eq fake_course
      end
    end

    context "with multiple ARs per one course" do
      before(:each) do
        fake_ar_1 = OpenStruct.new(created_at: 3.years.ago)
        @fake_ar_2 = OpenStruct.new(created_at: Time.now)
        fake_ar_3 = OpenStruct.new(created_at: 6.years.ago)

        organizer.set_course_id(attached_record: fake_ar_1, course_id: 42)
        organizer.set_course_id(attached_record: @fake_ar_2, course_id: 42)
        organizer.set_course_id(attached_record: fake_ar_3, course_id: 42)
      end

      it "get latest attached records for a course" do
        expect(organizer.latest_attached_record(course_id: 42)).to eq @fake_ar_2
      end

      it "gets unduplicated course_ids" do
        expect(organizer.course_ids).to eq [42]
      end

      it "has all 3 ARs" do
        expect(organizer.size).to eq 3
      end
    end
  end

  context "preloading deleted periods" do
    let!(:course_1) { Entity::Course.create! }

    let!(:period_1) { CreatePeriod[course: course_1] }
    let!(:period_2) { CreatePeriod[course: course_1] }
    let!(:user_1)   { FactoryGirl.create :user }
    let!(:user_2)   { FactoryGirl.create :user }

    let!(:student_1_role) { AddUserAsPeriodStudent[user: user_1, period: period_1] }
    let!(:enrollment_1)   { student_1_role.student.latest_enrollment }

    let!(:student_2_role) { AddUserAsPeriodStudent[user: user_2, period: period_2] }
    let!(:enrollment_2)   { student_2_role.student.latest_enrollment }

    before(:each) do
      Rails.cache.clear
      period_2.to_model.destroy

      expect {
        allow_any_instance_of(UpdateSalesforceCourseStats::Organizer).to receive(:course_ids) { [course_1.id] }
        allow_any_instance_of(UpdateSalesforceCourseStats).to receive(:attached_records) { [] }

        organizer = described_class.new.initialize_organizer
        @preloaded_course = organizer.get_course(course_1.id)
      }.to make_database_queries(count: 4)
    end

    it "preloads deleted periods" do
      num_periods = nil

      expect{
        num_periods = @preloaded_course.periods_with_deleted.size
      }.not_to make_database_queries

      expect(num_periods).to eq 2
    end

    it "preloads deleted enrollments" do
      period_1_enrollments, period_2_enrollments = nil

      expect {
        period_1_enrollments = @preloaded_course.periods_with_deleted[0].latest_enrollments_with_deleted.size
        period_2_enrollments = @preloaded_course.periods_with_deleted[1].latest_enrollments_with_deleted.size
      }.not_to make_database_queries

      expect(period_1_enrollments).to eq 1
      expect(period_2_enrollments).to eq 1
    end
  end

end
