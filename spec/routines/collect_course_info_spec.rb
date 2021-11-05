require 'rails_helper'

RSpec.describe CollectCourseInfo, type: :routine do
  let(:course_1)  { FactoryBot.create(:course_profile_course) }
  let(:course_2)  { FactoryBot.create(:course_profile_course) }

  let!(:period_1) { FactoryBot.create :course_membership_period, course: course_1 }
  let!(:period_2) { FactoryBot.create :course_membership_period, course: course_1 }
  let!(:period_3) { FactoryBot.create :course_membership_period, course: course_2 }

  let(:user_1)    { FactoryBot.create :user_profile }
  let(:user_2)    { FactoryBot.create :user_profile }

  let!(:role)     { AddUserAsPeriodStudent[user: user_2, period: period_3] }

  let(:result)    { described_class[args] }

  context 'when a course is given' do
    let(:args)    { { user: user_1, courses: course_1.reload } }

    it 'returns information about the course' do
      expect(result.map(&:to_h)).to match [
        {
          id: course_1.id,
          uuid: course_1.uuid,
          name: course_1.name,
          term: course_1.term,
          year: course_1.year,
          code: course_1.code,
          num_sections: course_1.num_sections,
          starts_at: be_within(1e-6).of(course_1.starts_at),
          ends_at: be_within(1e-6).of(course_1.ends_at),
          active?: course_1.active?,
          timezone: course_1.timezone,
          offering: course_1.offering,
          catalog_offering_id: course_1.offering.id,
          is_concept_coach: false,
          is_college: course_1.is_college,
          is_preview: course_1.is_preview,
          is_access_switchable: course_1.is_access_switchable,
          does_cost: course_1.does_cost,
          is_lms_enabling_allowed: course_1.is_lms_enabling_allowed,
          is_lms_enabled: course_1.is_lms_enabled,
          pre_wrm_scores?: course_1.pre_wrm_scores?,
          past_due_unattempted_ungraded_wrq_are_zero:
            course_1.past_due_unattempted_ungraded_wrq_are_zero,
          last_lms_scores_push_job_id: course_1.last_lms_scores_push_job_id,
          related_teacher_profile_ids: course_1.related_teacher_profile_ids,
          school_name: course_1.school_name,
          salesforce_book_name: course_1.offering.salesforce_book_name,
          appearance_code: course_1.offering.appearance_code,
          cloned_from_id: course_1.cloned_from_id,
          homework_weight: course_1.homework_weight,
          reading_weight: course_1.reading_weight,
          ecosystem: course_1.ecosystem,
          should_reuse_preview?: course_1.should_reuse_preview?,
          periods: [],
          roles: [],
          teachers: [],
          teacher_record: nil,
          students: [],
          student_record: nil,
          teacher_student_records: [],
          teacher_profiles: course_1.teacher_profiles,
          spy_info: { research_studies: [] }
        }
      ]
    end
  end

  context 'when multiple courses are given' do
    let(:ecosystem_1) { FactoryBot.create :content_ecosystem }
    let(:ecosystem_2) { FactoryBot.create :content_ecosystem }

    let(:args)        { { user: user_1, courses: [course_1, course_2] } }

    before do
      AddEcosystemToCourse[ecosystem: ecosystem_1, course: course_1]
      AddEcosystemToCourse[ecosystem: ecosystem_2, course: course_2]
    end

    it 'returns information about all given courses' do
      expect(result.map(&:to_h)).to match_array [
        {
          id: course_1.id,
          uuid: course_1.uuid,
          name: course_1.name,
          term: course_1.term,
          year: course_1.year,
          code: course_1.code,
          num_sections: course_1.num_sections,
          starts_at: be_within(1e-6).of(course_1.starts_at),
          ends_at: be_within(1e-6).of(course_1.ends_at),
          active?: course_1.active?,
          timezone: course_1.timezone,
          offering: course_1.offering,
          catalog_offering_id: course_1.offering.id,
          is_concept_coach: false,
          is_college: course_1.is_college,
          is_preview: course_1.is_preview,
          is_access_switchable: course_1.is_access_switchable,
          does_cost: course_1.does_cost,
          is_lms_enabling_allowed: course_1.is_lms_enabling_allowed,
          is_lms_enabled: course_1.is_lms_enabled,
          pre_wrm_scores?: course_1.pre_wrm_scores?,
          past_due_unattempted_ungraded_wrq_are_zero:
            course_1.past_due_unattempted_ungraded_wrq_are_zero,
          related_teacher_profile_ids: course_1.related_teacher_profile_ids,
          last_lms_scores_push_job_id: course_1.last_lms_scores_push_job_id,
          school_name: course_1.school_name,
          salesforce_book_name: course_1.offering.salesforce_book_name,
          appearance_code: course_1.offering.appearance_code,
          cloned_from_id: course_1.cloned_from_id,
          homework_weight: course_1.homework_weight,
          reading_weight: course_1.reading_weight,
          ecosystem: course_1.ecosystem,
          should_reuse_preview?: course_1.should_reuse_preview?,
          periods: [],
          roles: [],
          teachers: [],
          teacher_record: nil,
          students: [],
          student_record: nil,
          teacher_student_records: [],
          teacher_profiles: course_1.teacher_profiles,
          spy_info: { research_studies: [] }
        },
        {
          id: course_2.id,
          uuid: course_2.uuid,
          name: course_2.name,
          term: course_2.term,
          year: course_2.year,
          code: course_2.code,
          num_sections: course_2.num_sections,
          starts_at: be_within(1e-6).of(course_2.starts_at),
          ends_at: be_within(1e-6).of(course_2.ends_at),
          active?: course_2.active?,
          timezone: course_2.timezone,
          offering: course_2.offering,
          catalog_offering_id: course_2.offering.id,
          is_concept_coach: false,
          is_college: course_2.is_college,
          is_preview: course_2.is_preview,
          is_access_switchable: course_2.is_access_switchable,
          does_cost: course_2.does_cost,
          is_lms_enabling_allowed: course_2.is_lms_enabling_allowed,
          is_lms_enabled: course_2.is_lms_enabled,
          pre_wrm_scores?: course_2.pre_wrm_scores?,
          past_due_unattempted_ungraded_wrq_are_zero:
            course_2.past_due_unattempted_ungraded_wrq_are_zero,
          last_lms_scores_push_job_id: course_2.last_lms_scores_push_job_id,
          related_teacher_profile_ids: course_1.related_teacher_profile_ids,
          school_name: course_2.school_name,
          salesforce_book_name: course_2.offering.salesforce_book_name,
          appearance_code: course_2.offering.appearance_code,
          cloned_from_id: course_2.cloned_from_id,
          homework_weight: course_2.homework_weight,
          reading_weight: course_2.reading_weight,
          ecosystem: course_2.ecosystem,
          should_reuse_preview?: course_1.should_reuse_preview?,
          periods: [],
          roles: [],
          teachers: [],
          teacher_record: nil,
          students: [],
          student_record: nil,
          teacher_student_records: [],
          teacher_profiles: course_1.teacher_profiles,
          spy_info: { research_studies: [] }
        }
      ]
    end
  end

  context 'when no course is given' do
    let(:args)    { { user: user_1 } }

    context 'when the user is a teacher' do
      let!(:teacher_role)         { AddUserAsCourseTeacher[user: user_1, course: course_1] }
      let!(:teacher_student_role) { CreateOrResetTeacherStudent[user: user_1, period: period_1] }
      let(:teacher)               { teacher_role.teacher }
      let(:teacher_student)       { teacher_student_role.teacher_student }

      before { period_2.destroy! }

      it "returns information about the user's active courses and all periods" do
        expect(result.map(&:to_h)).to match [
          {
            id: course_1.id,
            uuid: course_1.uuid,
            name: course_1.name,
            term: course_1.term,
            year: course_1.year,
            code: course_1.code,
            num_sections: course_1.num_sections,
            starts_at: be_within(1e-6).of(course_1.starts_at),
            ends_at: be_within(1e-6).of(course_1.ends_at),
            active?: course_1.active?,
            timezone: course_1.timezone,
            offering: course_1.offering,
            catalog_offering_id: course_1.offering.id,
            is_concept_coach: false,
            is_college: course_1.is_college,
            is_preview: course_1.is_preview,
            is_access_switchable: course_1.is_access_switchable,
            does_cost: course_1.does_cost,
            is_lms_enabling_allowed: course_1.is_lms_enabling_allowed,
            is_lms_enabled: course_1.is_lms_enabled,
            pre_wrm_scores?: course_1.pre_wrm_scores?,
            past_due_unattempted_ungraded_wrq_are_zero:
              course_1.past_due_unattempted_ungraded_wrq_are_zero,
            last_lms_scores_push_job_id: course_1.last_lms_scores_push_job_id,
            school_name: course_1.school_name,
            salesforce_book_name: course_1.offering.salesforce_book_name,
            appearance_code: course_1.offering.appearance_code,
            cloned_from_id: course_1.cloned_from_id,
            homework_weight: course_1.homework_weight,
            reading_weight: course_1.reading_weight,
            related_teacher_profile_ids: course_1.related_teacher_profile_ids,
            ecosystem: course_1.ecosystem,
            should_reuse_preview?: course_1.should_reuse_preview?,
            periods: a_collection_containing_exactly(period_1, period_2),
            roles: a_collection_containing_exactly(teacher_role, teacher_student_role),
            teachers: [ teacher ],
            teacher_record: teacher,
            students: [],
            student_record: nil,
            teacher_student_records: [ teacher_student ],
            teacher_profiles: course_1.teacher_profiles,
            spy_info: { research_studies: [] }
          }
        ]
      end
    end

    context 'when the user is a student' do
      let(:student_role) { AddUserAsPeriodStudent[user: user_1, period: period_1] }
      let!(:student)     { student_role.student }

      it "returns information about the user's active courses" do
        expect(result.map(&:to_h)).to match [
          {
            id: course_1.id,
            uuid: course_1.uuid,
            name: course_1.name,
            term: course_1.term,
            year: course_1.year,
            code: course_1.code,
            num_sections: course_1.num_sections,
            starts_at: be_within(1e-6).of(course_1.starts_at),
            ends_at: be_within(1e-6).of(course_1.ends_at),
            active?: course_1.active?,
            timezone: course_1.timezone,
            offering: course_1.offering,
            catalog_offering_id: course_1.offering.id,
            is_concept_coach: false,
            is_college: course_1.is_college,
            is_preview: course_1.is_preview,
            is_access_switchable: course_1.is_access_switchable,
            does_cost: course_1.does_cost,
            is_lms_enabling_allowed: course_1.is_lms_enabling_allowed,
            is_lms_enabled: course_1.is_lms_enabled,
            pre_wrm_scores?: course_1.pre_wrm_scores?,
            past_due_unattempted_ungraded_wrq_are_zero:
              course_1.past_due_unattempted_ungraded_wrq_are_zero,
            last_lms_scores_push_job_id: course_1.last_lms_scores_push_job_id,
            school_name: course_1.school_name,
            salesforce_book_name: course_1.offering.salesforce_book_name,
            appearance_code: course_1.offering.appearance_code,
            cloned_from_id: course_1.cloned_from_id,
            homework_weight: course_1.homework_weight,
            reading_weight: course_1.reading_weight,
            related_teacher_profile_ids: course_1.related_teacher_profile_ids,
            ecosystem: course_1.ecosystem,
            should_reuse_preview?: course_1.should_reuse_preview?,
            periods: [ student.period ],
            roles: [ student_role ],
            teachers: [],
            teacher_record: nil,
            students: [ student ],
            student_record: student,
            teacher_student_records: [],
            teacher_profiles: course_1.teacher_profiles,
            spy_info: { research_studies: [] }
          }
        ]
      end

      it "returns only the user's current period" do
        expect(result.first.periods).to eq [ period_1 ]
      end

      it 'returns student info for the user' do
        expect(result.length).to eq 1
        expect(result.first.student_record.id).to eq student.id
      end
    end

    context 'when the user is a teacher and teacher_student' do
      before do
        @teacher = AddUserAsCourseTeacher[user: user_1, course: course_1].teacher
        @teacher_student = CreateOrResetTeacherStudent[
          user: user_1, period: period_1
        ].teacher_student
      end

      it 'returns teacher and student info for the user' do
        expect(result.first.teacher_record.id).to eq @teacher.id
        expect(result.first.teacher_student_records.map(&:id)).to eq [ @teacher_student.id ]
      end
    end
  end
end
