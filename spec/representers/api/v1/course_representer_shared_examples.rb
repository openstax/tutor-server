require 'rails_helper'

module Api::V1
  RSpec.shared_examples 'api_v1_course_representer' do
    let(:ecosystem) { FactoryBot.create :content_ecosystem }
    let(:catalog_offering) do
      FactoryBot.create :catalog_offering, salesforce_book_name: 'book',
                                            appearance_code: 'appearance',
                                            description: 'desc',
                                            ecosystem: ecosystem
    end
    let(:original_course)  { FactoryBot.create :course_profile_course }
    let(:course) do
      FactoryBot.create :course_profile_course, name: 'Test course',
                                                appearance_code: 'appearance override',
                                                offering: catalog_offering,
                                                is_preview: true,
                                                is_concept_coach: true,
                                                is_college: false,
                                                cloned_from: original_course
    end
    let(:period) { FactoryBot.create :course_membership_period, course: course }
    let(:user) do
      FactoryBot.create(:course_membership_teacher, course: course).role.profile.tap do |profile|
        AddUserAsPeriodStudent[user: profile, period: period]
        CreateOrResetTeacherStudent[user: profile, period: period]
      end
    end

    subject(:represented) do
      described_class.new(CollectCourseInfo[courses: course, user: user].first).as_json
    end

    it 'shows the course id' do
      expect(represented['id']).to eq course.id.to_s
    end

    it 'shows the course name' do
      expect(represented['name']).to eq 'Test course'
    end

    it 'shows the course timezone' do
      expect(represented['timezone']).to eq 'US/Central'
    end

    it 'shows the offering salesforce_book_name' do
      expect(represented['salesforce_book_name']).to eq 'book'
    end

    it 'shows the course appearance_code' do
      expect(represented['appearance_code']).to eq 'appearance override'
    end

    it 'shows the offering appearance_code if the course appearance_code is blank' do
      course.update_attribute(:appearance_code, nil)
      expect(represented['appearance_code']).to eq 'appearance'
    end

    it 'shows whether or not the course is a preview course' do
      expect(represented['is_preview']).to eq true
    end

    it 'shows whether or not the course is a concept coach course' do
      expect(represented['is_concept_coach']).to eq true
    end

    it 'shows whether or not it is a college course, defaulting to true' do
      expect(represented['is_college']).to eq false

      course.update_attribute :is_college, nil
      expect(
        described_class.new(CollectCourseInfo[courses: course, user: user].first
      ).as_json['is_college']).to eq true

      course.update_attribute :is_college, true
      expect(
        described_class.new(CollectCourseInfo[courses: course, user: user].first
      ).as_json['is_college']).to eq true

      course.update_attribute :is_college, false
      expect(
        described_class.new(CollectCourseInfo[courses: course, user: user].first
      ).as_json['is_college']).to eq false
    end

    it "shows the id of the source course's catalog offering" do
      expect(represented['offering_id']).to eq catalog_offering.id.to_s
    end

    it 'shows the id of the course it was cloned from' do
      expect(represented['cloned_from_id']).to eq original_course.id.to_s
    end

    it 'shows the number of sections in the course' do
      period_1 = FactoryBot.create :course_membership_period, course: course
      period_2 = FactoryBot.create :course_membership_period, course: course
      period_3 = FactoryBot.create :course_membership_period, course: course
      period_4 = FactoryBot.create :course_membership_period, course: course

      expect(represented['num_sections']).to eq course.periods.count
    end

    it "shows the user's own roles" do
      expect(represented['roles']).to match_array [
        a_hash_including('type' => 'teacher'),
        a_hash_including('type' => 'student'),
        a_hash_including('type' => 'teacher_student')
      ]
    end

    it "shows the user's teacher record" do
      expect(represented['teacher_record']).to match a_hash_including('profile_id' => user.id.to_s)
    end

    it "shows the user's student record" do
      expect(represented['student_record']).to match(
        a_hash_including('latest_enrollment_at' => kind_of(String))
      )
    end

    it "shows the user's teacher_student records" do
      expect(represented['teacher_student_records']).to match(
        [ a_hash_including('period_id' => period.id.to_s) ]
      )
    end

    it 'shows does_cost' do
      expect(represented['does_cost']).to eq false
    end

    it 'shows the last_lms_scores_push_job_id' do
      course.last_lms_scores_push_job_id = "howdy"
      expect(represented['last_lms_scores_push_job_id']).to eq "howdy"
    end

    it 'shows uses_pre_wrm_scores' do
      expect(represented['uses_pre_wrm_scores']).to eq course.pre_wrm_scores?
    end
  end
end
