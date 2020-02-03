require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe GetStudentGuide, type: :routine do
  before(:all) do
    @course = FactoryBot.create :course_profile_course

    @period = FactoryBot.create :course_membership_period, course: @course
    @second_period = FactoryBot.create :course_membership_period, course: @course

    @teacher = FactoryBot.create(:user_profile)
    @student = FactoryBot.create(:user_profile)
    @second_student = FactoryBot.create(:user_profile)

    @teacher_role = AddUserAsCourseTeacher[course: @course, user: @teacher]
  end

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
      before(:all) do
        DatabaseCleaner.start

        @role = routine_class[period: @period, user: @student]
        @second_role = routine_class[period: @second_period, user: @second_student]
      end

      after(:all)  { DatabaseCleaner.clean }

      context 'without work' do
        before(:all) do
          DatabaseCleaner.start

          @role.reload
          @second_role.reload
          @teacher_role.reload

          book = FactoryBot.create :content_book, title: 'Physics (Demo)'
          AddEcosystemToCourse[course: @course, ecosystem: book.ecosystem]
        end

        after(:all) { DatabaseCleaner.clean }

        it 'does not blow up' do
          guide = described_class[role: @role]

          expect(guide).to match(
            {
              period_id: @period.id,
              title: 'Physics (Demo)',
              page_ids: [],
              children: []
            }
          )
        end
      end

      context 'with work' do
        before(:all) do
          DatabaseCleaner.start

          @role.reload
          @second_role.reload
          @teacher_role.reload

          VCR.use_cassette('GetCourseGuide/setup_course_guide', VCR_OPTS) do
            capture_stdout { CreateStudentHistory[course: @course, roles: [@role, @second_role]] }
          end
        end

        after(:all) { DatabaseCleaner.clean }

        it 'gets the completed task step counts for the role' do
          result = described_class[role: @role]
          total_count = result['children'].map do |cc|
            cc['questions_answered_count']
          end.reduce(0, :+)
          expect(total_count).to eq 9

          result = described_class[role: @second_role]
          total_count = result['children'].map do |cc|
            cc['questions_answered_count']
          end.reduce(0, :+)
          expect(total_count).to eq 10
        end

        it 'returns the period course guide for a student' do
          guide = described_class[role: @role]

          expect(guide).to match(
            period_id: @period.id,
            title: 'Physics (Demo)',
            page_ids: [kind_of(Integer)]*6,
            children: [kind_of(Hash)]*2
          )
        end

        it 'includes chapter stats for the student only' do
          guide = described_class[role: @role]

          chapter_1 = guide['children'].first
          expect(chapter_1).to match(
            title: 'Acceleration',
            book_location: [],
            student_count: 1,
            questions_answered_count: 2,
            clue: clue_matcher,
            page_ids: [kind_of(Integer)]*2,
            first_worked_at: kind_of(String),
            last_worked_at: kind_of(String),
            children: [kind_of(Hash)]*2
          )

          chapter_2 = guide['children'].second
          expect(chapter_2).to match(
            title: "Force and Newton's Laws of Motion",
            book_location: [],
            student_count: 1,
            questions_answered_count: 7,
            clue: clue_matcher,
            page_ids: [kind_of(Integer)]*4,
            first_worked_at: kind_of(String),
            last_worked_at: kind_of(String),
            children: [kind_of(Hash)]*4
          )
        end

        it 'includes page stats for the student only' do
          guide = described_class[role: @role]

          chapter_1_pages = guide['children'].first['children']
          expect(chapter_1_pages).to match [
            {
              title: 'Acceleration',
              book_location: [],
              student_count: 1,
              questions_answered_count: 2,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: kind_of(String),
              last_worked_at: kind_of(String)
            },
            {
              title: 'Representing Acceleration with Equations and Graphs',
              book_location: [],
              student_count: 1,
              questions_answered_count: 0,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: nil,
              last_worked_at: nil
            }
          ]

          chapter_2_pages = guide['children'].second['children']
          expect(chapter_2_pages).to match [
            {
              title: 'Force',
              book_location: [],
              student_count: 1,
              questions_answered_count: 2,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: kind_of(String),
              last_worked_at: kind_of(String)
            },
            {
              title: "Newton's First Law of Motion: Inertia",
              book_location: [],
              student_count: 1,
              questions_answered_count: 5,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: kind_of(String),
              last_worked_at: kind_of(String)
            },
            {
              title: "Newton's Second Law of Motion",
              book_location: [],
              student_count: 1,
              questions_answered_count: 0,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: nil,
              last_worked_at: nil
            },
            {
              title: "Newton's Third Law of Motion",
              book_location: [],
              student_count: 1,
              questions_answered_count: 0,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: nil,
              last_worked_at: nil
            }
          ]
        end
      end
    end
  end
end
