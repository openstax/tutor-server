require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe GetStudentGuide, type: :routine, speed: :slow do
  before(:all) do
    @course = FactoryBot.create :course_profile_course

    @period = FactoryBot.create :course_membership_period, course: @course
    @second_period = FactoryBot.create :course_membership_period, course: @course

    @teacher = FactoryBot.create(:user_profile)
    @student = FactoryBot.create(:user_profile)
    @second_student = FactoryBot.create(:user_profile)

    @teacher_role = AddUserAsCourseTeacher[course: @course, user: @teacher]
  end

  before do
    @course.reload

    @period.reload
    @second_period.reload

    @teacher.reload
    @student.reload
    @second_student.reload

    @teacher_role.reload
  end

  subject(:guide)       { described_class[role: @role].deep_symbolize_keys }

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
      before(:all) do
        DatabaseCleaner.start

        @role = routine_class[period: @period.reload, user: @student.reload]
        @second_role = routine_class[period: @second_period.reload, user: @second_student.reload]
      end

      after(:all)  { DatabaseCleaner.clean }

      before do
        @role.reload
        @second_role.reload
      end

      context 'without work' do
        before(:all) do
          DatabaseCleaner.start

          book = FactoryBot.create :content_book, title: 'Physics (Demo)'
          AddEcosystemToCourse[course: @course.reload, ecosystem: book.ecosystem]
        end

        after(:all) { DatabaseCleaner.clean }

        it 'does not blow up' do
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

          VCR.use_cassette('GetCourseGuide/setup_course_guide', VCR_OPTS) do
            CreateStudentHistory[
              course: @course.reload, roles: [@role.reload, @second_role.reload]
            ]
          end
        end

        after(:all) { DatabaseCleaner.clean }

        it 'gets the completed task step counts for the role' do
          total_count = chapters.map { |cc| cc[:questions_answered_count] }.sum
          expect(total_count).to eq 5

          guide2 = described_class[role: @second_role]
          total_count = guide2[:children].map { |cc| cc[:questions_answered_count] }.sum
          expect(total_count).to eq 5
        end

        it 'returns the period course guide for a student' do
          expect(guide).to match(
            period_id: @period.id,
            title: 'Physics (Demo)',
            page_ids: [kind_of(Integer)],
            children: [kind_of(Hash)]
          )
        end

        it 'includes chapter stats for the student only' do
          expect(worked_chapters).to eq chapters

          chapter_2 = chapters.first
          expect(chapter_2).to match(
            title: "Force and Newton's Laws of Motion",
            book_location: [],
            student_count: 1,
            questions_answered_count: 5,
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
              title: "Newton's First Law of Motion: Inertia",
              book_location: [],
              student_count: 1,
              questions_answered_count: 5,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: kind_of(Time),
              last_worked_at: kind_of(Time)
            }
          ]
        end
      end

      context 'with the bio book' do
        before(:all) do
          DatabaseCleaner.start

          VCR.use_cassette('Content_ImportBook/with_the_bio_book', VCR_OPTS) do
            OpenStax::Cnx::V1.with_archive_url('https://archive.cnx.org/contents') do
              OpenStax::Exercises::V1.use_fake_client do
                CreateStudentHistory[
                  course: @course.reload,
                  roles: [@role.reload, @second_role.reload],
                  book_id: '6c322e32-9fb0-4c4d-a1d7-20c95c5c7af2'
                ]
              end
            end
          end
        end

        after(:all)  { DatabaseCleaner.clean }

        before { Tasks::Models::Task.update_all due_at_ntz: Time.current - 1.day }

        it 'displays unworked chapters after the due date and ignores units' do
          expect(chapters).not_to eq worked_chapters

          chapter_1_pages = chapters.first[:children]
          expect(chapter_1_pages).to match [
            {
              title: 'The Science of Biology',
              book_location: [1, 1],
              student_count: 1,
              questions_answered_count: 0,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: nil,
              last_worked_at: nil
            },
            {
              title: 'Themes and Concepts of Biology',
              book_location: [1, 2],
              student_count: 1,
              questions_answered_count: 0,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: nil,
              last_worked_at: nil
            }
          ]

          chapter_2_pages = chapters.second[:children]
          expect(chapter_2_pages).to match [
            {
              title: 'Atoms, Isotopes, Ions, and Molecules: The Building Blocks',
              book_location: [2, 1],
              student_count: 1,
              questions_answered_count: 0,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: nil,
              last_worked_at: nil
            },
            {
              title: 'Water',
              book_location: [2, 2],
              student_count: 1,
              questions_answered_count: 0,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: nil,
              last_worked_at: nil
            },
            {
              title: 'Carbon',
              book_location: [2, 3],
              student_count: 1,
              questions_answered_count: 0,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: nil,
              last_worked_at: nil
            }
          ]

          expect(chapters.third).to eq worked_chapters.first
          chapter_3_pages = chapters.third[:children]
          expect(chapter_3_pages).to match [
            {
              title: 'Synthesis of Biological Macromolecules',
              book_location: [3, 1],
              student_count: 1,
              questions_answered_count: 1,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: kind_of(Time),
              last_worked_at: kind_of(Time)
            },
            {
              title: 'Carbohydrates',
              book_location: [3, 2],
              student_count: 1,
              questions_answered_count: 0,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: nil,
              last_worked_at: nil
            },
            {
              title: 'Lipids',
              book_location: [3, 3],
              student_count: 1,
              questions_answered_count: 0,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: nil,
              last_worked_at: nil
            },
            {
              title: 'Proteins',
              book_location: [3, 4],
              student_count: 1,
              questions_answered_count: 0,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: nil,
              last_worked_at: nil
            },
            {
              title: 'Nucleic Acids',
              book_location: [3, 5],
              student_count: 1,
              questions_answered_count: 0,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: nil,
              last_worked_at: nil
            }
          ]

          expect(chapters.fourth).to eq worked_chapters.second
          chapter_4_pages = chapters.fourth[:children]
          expect(chapter_4_pages).to match [
            {
              title: 'Studying Cells',
              book_location: [4, 1],
              student_count: 1,
              questions_answered_count: 0,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: nil,
              last_worked_at: nil
            },
            {
              title: 'Prokaryotic Cells',
              book_location: [4, 2],
              student_count: 1,
              questions_answered_count: 5,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: kind_of(Time),
              last_worked_at: kind_of(Time)
            },
            {
              title: 'Eukaryotic Cells',
              book_location: [4, 3],
              student_count: 1,
              questions_answered_count: 0,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: nil,
              last_worked_at: nil
            },
            {
              title: 'The Endomembrane System and Proteins',
              book_location: [4, 4],
              student_count: 1,
              questions_answered_count: 0,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: nil,
              last_worked_at: nil
            },
            {
              title: 'Cytoskeleton',
              book_location: [4, 5],
              student_count: 1,
              questions_answered_count: 0,
              clue: clue_matcher,
              page_ids: [kind_of(Integer)],
              first_worked_at: nil,
              last_worked_at: nil
            },
            {
              title: 'Connections between Cells and Cellular Activities',
              book_location: [4, 6],
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
