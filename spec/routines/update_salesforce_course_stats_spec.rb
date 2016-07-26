require 'rails_helper'

RSpec.describe UpdateSalesforceCourseStats, type: :routine do

  context "full test" do
    # Includes 1 deleted period, 2 orphaned periods (one of which requires a new
    # SF object), 1 dropped student

    let(:course_1) { Entity::Course.create! }

    let(:period_1) { CreatePeriod[course: course_1] }
    let(:period_2) { CreatePeriod[course: course_1] }
    let(:period_3) { CreatePeriod[course: course_1] }

    let!(:student_1_role) do
      AddUserAsPeriodStudent[user: FactoryGirl.create(:user), period: period_1]
    end
    let!(:student_2_role) do
      AddUserAsPeriodStudent[user: FactoryGirl.create(:user), period: period_2]
    end
    let!(:student_3_role) do
      AddUserAsPeriodStudent[user: FactoryGirl.create(:user), period: period_2]
    end

    before(:each) do
      3.times { AddUserAsCourseTeacher[user: FactoryGirl.create(:user), course: course_1] }

      CourseMembership::InactivateStudent[student: student_3_role.student]

      # We're not really testing the existing being either OsAncillary or ClassSize b/c
      # the type of SF object doesn't really matter to the described_class (tho does matter
      # in 'renew' call)

      @existing_sf_object = Salesforce::Remote::OsAncillary.new(
        product: "Concept Coach", account_type: "High School", id: "123", term_year: '2015 - 16 Spring'
      )

      # period_1 is the only one to have an attached SF object, period_2 is orphaned
      # and will need a new SF object, period_3 is orphaned but should reuse the existing
      # SF object from the course (period_3 is the case where all periods will fall on the
      # first run)

      allow_any_instance_of(UpdateSalesforceCourseStats).to receive(:attached_records).and_return(
        [
          FactoryGirl.create(:salesforce_attached_record,
                             tutor_object: period_1.to_model,
                             salesforce_object: @existing_sf_object).wrap,
          FactoryGirl.create(:salesforce_attached_record,
                             tutor_object: course_1,
                             salesforce_object: @existing_sf_object).wrap,
        ]
      )

      period_2.to_model.update_attribute(:created_at, Time.zone.local(2016,4,20))
      period_3.to_model.update_attribute(:created_at, Time.zone.local(2016,4,10))

      @new_sf_object = Salesforce::Remote::OsAncillary.new(
        product: "Concept Coach", account_type: "High School", id: "42", term_year: '2016 - 17 Fall'
      )

      allow(Salesforce::RenewOsAncillary).to receive(:call).once { @new_sf_object }
      allow_any_instance_of(Salesforce::Remote::OsAncillary).to receive(:save) { nil }
      allow_any_instance_of(Salesforce::Remote::ClassSize).to receive(:save) { nil }

      period_1.to_model.destroy

      @outputs = described_class.call
    end

    it "works" do
      expect(@outputs.num_errors).to eq 0
      expect(@outputs.num_updates).to eq 2

      expect(@existing_sf_object.num_teachers).to eq 3
      expect(@existing_sf_object.num_sections).to eq 2
      expect(@existing_sf_object.num_students).to eq 1

      expect(@new_sf_object.num_teachers).to eq 3
      expect(@new_sf_object.num_sections).to eq 1
      expect(@new_sf_object.num_students).to eq 2
    end
  end

  context "#initialize_organizer" do
    context "when an SF object is not found for an AR" do
      before(:each) do
        allow_any_instance_of(UpdateSalesforceCourseStats).to receive(:attached_records) {
          [OpenStruct.new(attached_to_class_name: "Entity::Course",
                          attached_to_id: "foo",
                          salesforce_id: "blah")]
        }
      end

      it "does not explode" do
        expect{described_class.new.initialize_organizer}.not_to raise_error
      end

      it "notifies devs" do
        expect_any_instance_of(described_class)
          .to receive(:notify)
          .with(a_string_matching(/are missing!/), salesforce_ids: ["blah"])
        described_class.new.initialize_organizer
      end
    end
  end

  context "#attach_orphaned_periods_to_sf_objects" do
    let(:course)          { Entity::Course.create! }
    let(:period_1)        { CreatePeriod[course: course] }
    let(:period_2)        { CreatePeriod[course: course] }
    let(:period_3)        { CreatePeriod[course: course] }
    let(:sf_object)       { OpenStruct.new(changed?: true, save: nil) }
    let(:attached_record) { OpenStruct.new(record: sf_object) }

    before(:each) do
      @organizer = stub_organizer do |organizer|
        allow(organizer).to receive(:orphaned_periods) { [period_3.to_model] }
        allow(organizer).to receive(:get_course) { course }
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
        Salesforce::Remote::OsAncillary.new(term_year: "2015 - 16 Fall"),
        Salesforce::Remote::OsAncillary.new(term_year: "2015 - 16 Fall"),
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
      existing_sf_object = Salesforce::Remote::OsAncillary.new(term_year: term_year.to_s, id: 'foo')

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
      existing_sf_object = OpenStruct.new(term_year: term_year.to_s, id: 'foo')

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
    let(:course)          { Entity::Course.create! }
    let(:period_1)        { CreatePeriod[course: course] }
    let(:period_2)        { CreatePeriod[course: course] }
    let(:record)          { OpenStruct.new(changed?: true, save: nil) }
    let(:attached_record) { OpenStruct.new(record: record) }

    before(:each) do
      @s1, @s2, @s3 = 3.times.map { AddUserAsPeriodStudent[user: FactoryGirl.create(:user), period: period_1] }
      2.times { AddUserAsCourseTeacher[user: FactoryGirl.create(:user), course: course] }

      stub_organizer do |organizer|
        allow(organizer).to receive(:each).and_yield(record, course, [period_1.to_model, period_2.to_model])
      end
    end

    it "counts and saves on the happy path" do
      expect(record).to receive(:save)
      outputs = described_class.call(handle_orphaned_periods: false)
      expect(record.num_teachers).to eq 2
      expect(record.num_students).to eq 3
      expect(record.num_sections).to eq 2
      expect(outputs.num_updates).to eq 1
      expect(outputs.num_errors).to eq 0
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

    it "counts moved students correctly" do
      MoveStudent[period: period_2, student: @s1.student]
      described_class.call(handle_orphaned_periods: false)
      expect(record.num_students).to eq 3
    end

    it "counts dropped students correctly" do
      CourseMembership::InactivateStudent[student: @s1.student]
      described_class.call(handle_orphaned_periods: false)
      expect(record.num_students).to eq 3
    end
  end

  it "can find the methods it needs in potential SF object classes" do
    # Have this check since we're mostly otherwise stubbing these classes
    [Salesforce::Remote::OsAncillary, Salesforce::Remote::ClassSize].each do |sf_class|
      expect(sf_class.new).to respond_to(:num_teachers=, :num_sections=, :num_students=,
                                         :error=, :changed?, :save)
    end
  end

  context "Organizer" do
    let(:organizer) { UpdateSalesforceCourseStats::Organizer.new }

    it "has working period methods" do
      fake_period = OpenStruct.new(id: 2)
      fake_sf_object = new_dummy_sf_object
      organizer.add_period_id(salesforce_object: fake_sf_object, period_id: fake_period.id)
      organizer.remember_period(fake_period)
      organizer.each do |sf_object, course, periods|
        expect(sf_object).to eq fake_sf_object
        expect(periods).to eq [fake_period]
      end
      expect(organizer.no_salesforce_object_for_period?(fake_period)).to be_falsy
      expect(organizer.no_salesforce_object_for_period?(OpenStruct.new(id: 'boo'))).to be_truthy
    end

    it "has working course methods" do
      fake_course = OpenStruct.new(id: 42)
      fake_sf_object = new_dummy_sf_object
      organizer.set_course_id(salesforce_object: fake_sf_object, course_id: fake_course.id)
      organizer.remember_course(fake_course)
      organizer.each do |sf_object, course, periods|
        expect(sf_object).to eq fake_sf_object
        expect(course).to eq fake_course
      end
    end

    context "with multiple ARs per one course" do
      before(:each) do
        organizer.set_course_id(salesforce_object: new_dummy_sf_object, course_id: 42)
        organizer.set_course_id(salesforce_object: new_dummy_sf_object, course_id: 42)
      end

      it "gets unduplicated course_ids" do
        expect(organizer.course_ids).to eq [42]
      end

      it "has all 3 ARs" do
        expect(organizer.size).to eq 2
      end
    end
  end

  context "preloading deleted periods" do
    let(:course_1) { Entity::Course.create! }

    let(:period_1) { CreatePeriod[course: course_1] }
    let(:period_2) { CreatePeriod[course: course_1] }
    let(:user_1)   { FactoryGirl.create :user }
    let(:user_2)   { FactoryGirl.create :user }

    let!(:student_1_role) { AddUserAsPeriodStudent[user: user_1, period: period_1] }
    let(:enrollment_1)    { student_1_role.student.latest_enrollment }

    let!(:student_2_role) { AddUserAsPeriodStudent[user: user_2, period: period_2] }
    let(:enrollment_2)    { student_2_role.student.latest_enrollment }

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

  def stub_organizer
    double.tap do |dbl|
      allow_any_instance_of(described_class).to receive(:initialize_organizer) { dbl }
      yield dbl
    end
  end

  def new_dummy_sf_object
    @id ||= 0
    OpenStruct.new(id: @id+=1)
  end

end
