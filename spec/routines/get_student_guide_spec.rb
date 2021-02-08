require 'rails_helper'
require 'vcr_helper'

RSpec.describe GetStudentGuide, type: :routine, speed: :slow do
  let(:ecosystem) { generate_mini_ecosystem }
  let(:book) { ecosystem.books.first }
  let(:offering) { FactoryBot.create :catalog_offering, ecosystem: ecosystem }
  let(:course) {
    FactoryBot.create :course_profile_course, :with_grading_templates,
                      offering: offering, is_preview: true
  }
  let(:period) { FactoryBot.create :course_membership_period, course: course }
  let(:second_period) { FactoryBot.create :course_membership_period, course: course }

  let(:teacher) { FactoryBot.create(:user_profile) }
  let(:student) { FactoryBot.create(:user_profile) }
  let(:second_student) { FactoryBot.create(:user_profile) }

  let(:role) { AddUserAsPeriodStudent[period: period, user: student] }
  let(:second_role) { AddUserAsPeriodStudent[period: second_period, user: second_student] }
  let(:teacher_role) { AddUserAsCourseTeacher[course: course, user: teacher] }

  subject(:guide)       { described_class[role: role].deep_symbolize_keys }

  let(:chapters)        { guide[:children] }
  let(:worked_chapters) { chapters.select { |ch| ch[:questions_answered_count] > 0 } }

  let(:clue_matcher) do
    a_hash_including(
      minimum: kind_of(Numeric),
      most_likely: kind_of(Numeric),
      maximum: kind_of(Numeric),
      is_real: be_in([true, false])
    )
  end

  [
    [ :student, AddUserAsPeriodStudent ], [ :teacher_student, CreateOrResetTeacherStudent ]
  ].each do |role_type, routine_class|
    context "#{role_type} role" do

      context 'without work' do
        it 'does not blow up' do
          expect(guide).to match(
            {
              period_id: period.id,
              title: 'College Physics with Courseware',
              page_ids: [],
              children: []
            }
          )
        end
      end

      context 'with work' do
        before(:each) do
          CreateStudentHistory[
            course: course.reload, roles: [role.reload, second_role.reload]
          ]
        end

        it 'gets the completed task step counts for the role' do
          total_count = chapters.map { |cc| cc[:questions_answered_count] }.sum
          expect(total_count).to eq 7
          guide2 = described_class[role: second_role]
          total_count = guide2[:children].map { |cc| cc[:questions_answered_count] }.sum
          expect(total_count).to eq 7
        end

        it 'returns the period course guide for a student' do
          expect(guide).to match(
            period_id: period.id,
            title: 'College Physics with Courseware',
            page_ids: [kind_of(Integer)],
            children: [kind_of(Hash)]
          )
        end

        it 'includes chapter stats for the student only' do
          expect(worked_chapters).to eq chapters
          chapter_2 = chapters.first
          expect(chapter_2).to match(
            title: 'Dynamics: Force and Newton\'s Laws of Motion',
            book_location: [],
            student_count: 1,
            questions_answered_count: 7,
            clue: clue_matcher,
            page_ids: [kind_of(Integer)],
            first_worked_at: kind_of(Time),
            last_worked_at: kind_of(Time),
            children: [kind_of(Hash)]
          )
        end

        it 'includes page stats for the student only' do
          chapter_2_pages = chapters.first[:children]
          expect(chapter_2_pages).to match [
            {
              title: 'Newtons First Law of Motion: Inertia',
              book_location: [],
              student_count: 1,
              questions_answered_count: 7,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: kind_of(Time),
              last_worked_at: kind_of(Time)
            }
          ]
        end
      end
    end
  end
end
