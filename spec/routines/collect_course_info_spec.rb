require 'rails_helper'

RSpec.describe CollectCourseInfo, type: :routine do
  let(:course_1)        { FactoryGirl.create(:course_profile_course) }
  let(:course_2)        { FactoryGirl.create(:course_profile_course) }

  let!(:period_model_1) { FactoryGirl.create :course_membership_period, course: course_1 }
  let!(:period_model_2) { FactoryGirl.create :course_membership_period, course: course_1 }
  let!(:period_model_3) { FactoryGirl.create :course_membership_period, course: course_2 }

  let(:period_1)        { CourseMembership::Period.new(strategy: period_model_1.wrap) }
  let(:period_2)        { CourseMembership::Period.new(strategy: period_model_2.wrap) }
  let(:period_3)        { CourseMembership::Period.new(strategy: period_model_3.wrap) }

  let(:profile_1)       { FactoryGirl.create :user_profile }
  let(:profile_2)       { FactoryGirl.create :user_profile }

  let(:user_1)          { User::User.new(strategy: profile_1.wrap) }
  let(:user_2)          { User::User.new(strategy: profile_2.wrap) }

  let!(:role)           { AddUserAsPeriodStudent[user: user_2, period: period_3] }

  context "when a course is given" do
    it "returns information about the course" do
      result = described_class[courses: course_1]
      expect(result).to contain_exactly(
        {
          id: course_1.id,
          name: course_1.name,
          term: course_1.term,
          year: course_1.year,
          num_sections: course_1.num_sections,
          starts_at: be_within(1e-6).of(course_1.starts_at),
          ends_at: be_within(1e-6).of(course_1.ends_at),
          active?: course_1.active?,
          is_concept_coach: false,
          is_college: true,
          time_zone: course_1.time_zone.name,
          default_open_time: course_1.default_open_time,
          default_due_time: course_1.default_due_time,
          offering: course_1.offering,
          catalog_offering_id: course_1.offering.id,
          school_name: course_1.school_name,
          salesforce_book_name: course_1.offering.salesforce_book_name,
          appearance_code: course_1.offering.appearance_code
        }
      )
    end
  end

  context "when multiple courses are given" do
    let(:ecosystem_model_1) { FactoryGirl.create :content_ecosystem }
    let(:ecosystem_1)       { Content::Ecosystem.new(strategy: ecosystem_model_1.wrap) }

    let(:ecosystem_model_2) { FactoryGirl.create :content_ecosystem }
    let(:ecosystem_2)       { Content::Ecosystem.new(strategy: ecosystem_model_2.wrap) }

    before do
      AddEcosystemToCourse[ecosystem: ecosystem_1, course: course_1]
      AddEcosystemToCourse[ecosystem: ecosystem_2, course: course_2]
    end

    it "returns information about all given courses" do
      result = described_class[courses: [course_1, course_2], with: [:ecosystem, :ecosystem_book]]
      expect(result).to contain_exactly(
        {
          id: course_1.id,
          name: course_1.name,
          term: course_1.term,
          year: course_1.year,
          num_sections: course_1.num_sections,
          starts_at: be_within(1e-6).of(course_1.starts_at),
          ends_at: be_within(1e-6).of(course_1.ends_at),
          active?: course_1.active?,
          is_concept_coach: false,
          is_college: true,
          time_zone: course_1.time_zone.name,
          default_open_time: course_1.default_open_time,
          default_due_time: course_1.default_due_time,
          offering: course_1.offering,
          catalog_offering_id: course_1.offering.id,
          school_name: course_1.school_name,
          salesforce_book_name: course_1.offering.salesforce_book_name,
          appearance_code: course_1.offering.appearance_code,
          ecosystem: ecosystem_1,
          ecosystem_book: ecosystem_1.books.first
        },
        {
          id: course_2.id,
          name: course_2.name,
          term: course_2.term,
          year: course_2.year,
          num_sections: course_2.num_sections,
          starts_at: be_within(1e-6).of(course_2.starts_at),
          ends_at: be_within(1e-6).of(course_2.ends_at),
          active?: course_2.active?,
          is_concept_coach: false,
          is_college: true,
          time_zone: course_2.time_zone.name,
          default_open_time: course_2.default_open_time,
          default_due_time: course_2.default_due_time,
          offering: course_2.offering,
          catalog_offering_id: course_2.offering.id,
          school_name: course_2.school_name,
          salesforce_book_name: course_2.offering.salesforce_book_name,
          appearance_code: course_2.offering.appearance_code,
          ecosystem: ecosystem_2,
          ecosystem_book: ecosystem_2.books.first
        }
      )
    end
  end

  context "when a user is given" do
    context "when the user is a teacher" do
      before { AddUserAsCourseTeacher[user: user_1, course: course_1] }

      it "returns information about the user's active courses" do
        result = described_class[user: user_1]
        expect(result).to contain_exactly(
          {
            id: course_1.id,
            name: course_1.name,
            term: course_1.term,
            year: course_1.year,
            num_sections: course_1.num_sections,
            starts_at: be_within(1e-6).of(course_1.starts_at),
            ends_at: be_within(1e-6).of(course_1.ends_at),
            active?: course_1.active?,
            is_concept_coach: false,
            is_college: true,
            time_zone: course_1.time_zone.name,
            default_open_time: course_1.default_open_time,
            default_due_time: course_1.default_due_time,
            offering: course_1.offering,
            catalog_offering_id: course_1.offering.id,
            school_name: course_1.school_name,
            salesforce_book_name: course_1.offering.salesforce_book_name,
            appearance_code: course_1.offering.appearance_code
          }
        )
      end

      it "returns all of the course's periods" do
        result = described_class[user: user_1, with: :periods]
        expect(result).to contain_exactly(
          {
            id: course_1.id,
            name: course_1.name,
            term: course_1.term,
            year: course_1.year,
            num_sections: course_1.num_sections,
            starts_at: be_within(1e-6).of(course_1.starts_at),
            ends_at: be_within(1e-6).of(course_1.ends_at),
            active?: course_1.active?,
            is_concept_coach: false,
            is_college: true,
            time_zone: course_1.time_zone.name,
            default_open_time: course_1.default_open_time,
            default_due_time: course_1.default_due_time,
            offering: course_1.offering,
            catalog_offering_id: course_1.offering.id,
            school_name: course_1.school_name,
            salesforce_book_name: course_1.offering.salesforce_book_name,
            appearance_code: course_1.offering.appearance_code,
            periods: a_collection_containing_exactly(period_1, period_2)
          }
        )
      end
    end

    context "when the user is a student" do
      before {
        result = AddUserAsPeriodStudent.call(user: user_1, period: period_1)
        @student = result.outputs.student
      }

      it "returns information about the user's active courses" do
        result = described_class[user: user_1]
        expect(result).to contain_exactly(
          {
            id: course_1.id,
            name: course_1.name,
            term: course_1.term,
            year: course_1.year,
            num_sections: course_1.num_sections,
            starts_at: be_within(1e-6).of(course_1.starts_at),
            ends_at: be_within(1e-6).of(course_1.ends_at),
            active?: course_1.active?,
            is_concept_coach: false,
            is_college: true,
            time_zone: course_1.time_zone.name,
            default_open_time: course_1.default_open_time,
            default_due_time: course_1.default_due_time,
            offering: course_1.offering,
            catalog_offering_id: course_1.offering.id,
            school_name: course_1.school_name,
            salesforce_book_name: course_1.offering.salesforce_book_name,
            appearance_code: course_1.offering.appearance_code
          }
        )
      end

      it "returns only the user's current period" do
        result = described_class[user: user_1, with: :periods]
        expect(result).to contain_exactly(
          {
            id: course_1.id,
            name: course_1.name,
            term: course_1.term,
            year: course_1.year,
            num_sections: course_1.num_sections,
            starts_at: be_within(1e-6).of(course_1.starts_at),
            ends_at: be_within(1e-6).of(course_1.ends_at),
            active?: course_1.active?,
            is_concept_coach: false,
            is_college: true,
            time_zone: course_1.time_zone.name,
            default_open_time: course_1.default_open_time,
            default_due_time: course_1.default_due_time,
            offering: course_1.offering,
            catalog_offering_id: course_1.offering.id,
            school_name: course_1.school_name,
            salesforce_book_name: course_1.offering.salesforce_book_name,
            appearance_code: course_1.offering.appearance_code,
            periods: [ period_1 ]
          }
        )
      end

      it "returns student info for the user" do
        result = described_class[user: user_1, with: :students]

        expect(result.length).to eq 1
        expect(result.first.students.map(&:id)).to eq [@student.id]
      end
    end

    context "when the user is a teacher and students" do
      before do
        AddUserAsCourseTeacher[user: user_1, course: course_1]
        result = AddUserAsPeriodStudent.call(user: user_1, period: period_1)
        @student1 = result.outputs.student
        result = AddUserAsPeriodStudent.call(user: user_1, period: period_2)
        @student2 = result.outputs.student
      end

      it "returns student info for the user" do
        result = described_class[user: user_1, with: :students]
        expect(Set.new result.first.students.map(&:id)).to eq Set[@student1.id, @student2.id]
      end
    end
  end

  context "when neither is given" do
    it "returns information about all courses" do
      result = described_class[]
      expect(result).to contain_exactly(
        {
          id: course_1.id,
          name: course_1.name,
          term: course_1.term,
          year: course_1.year,
          num_sections: course_1.num_sections,
          starts_at: be_within(1e-6).of(course_1.starts_at),
          ends_at: be_within(1e-6).of(course_1.ends_at),
          active?: course_1.active?,
          is_concept_coach: false,
          is_college: true,
          time_zone: course_1.time_zone.name,
          default_open_time: course_1.default_open_time,
          default_due_time: course_1.default_due_time,
          offering: course_1.offering,
          catalog_offering_id: course_1.offering.id,
          school_name: course_1.school_name,
          salesforce_book_name: course_1.offering.salesforce_book_name,
          appearance_code: course_1.offering.appearance_code
        },
        {
          id: course_2.id,
          name: course_2.name,
          term: course_2.term,
          year: course_2.year,
          num_sections: course_2.num_sections,
          starts_at: be_within(1e-6).of(course_2.starts_at),
          ends_at: be_within(1e-6).of(course_2.ends_at),
          active?: course_2.active?,
          is_concept_coach: false,
          is_college: true,
          time_zone: course_2.time_zone.name,
          default_open_time: course_2.default_open_time,
          default_due_time: course_2.default_due_time,
          offering: course_2.offering,
          catalog_offering_id: course_2.offering.id,
          school_name: course_2.school_name,
          salesforce_book_name: course_2.offering.salesforce_book_name,
          appearance_code: course_2.offering.appearance_code
        }
      )
    end
  end
end
