require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe GetTeacherGuide, type: :routine, speed: :slow do
  before(:all) do
    @course = FactoryBot.create :course_profile_course

    @period = FactoryBot.create :course_membership_period, course: @course
    @second_period = FactoryBot.create :course_membership_period, course: @course

    @teacher = FactoryBot.create(:user_profile)
    @student = FactoryBot.create(:user_profile)
    @second_student = FactoryBot.create(:user_profile)

    @role = AddUserAsPeriodStudent[period: @period, user: @student]
    @second_role = AddUserAsPeriodStudent[period: @second_period, user: @second_student]
    @teacher_role = AddUserAsCourseTeacher[course: @course, user: @teacher]
  end

  before do
    @course.reload

    @period.reload
    @second_period.reload

    @teacher.reload
    @student.reload
    @second_student.reload

    @role.reload
    @second_role.reload
    @teacher_role.reload
  end

  subject(:guide)                { described_class[role: @teacher_role] }

  let(:period_1_chapters)        { guide.first['children'] }
  let(:period_1_worked_chapters) do
    period_1_chapters.select { |ch| ch['questions_answered_count'] > 0 }
  end
  let(:period_2_chapters)        { guide.second['children'] }
  let(:period_2_worked_chapters) do
    period_2_chapters.select { |ch| ch['questions_answered_count'] > 0 }
  end

  let(:clue_matcher) do
    a_hash_including(
      minimum: kind_of(Numeric),
      most_likely: kind_of(Numeric),
      maximum: kind_of(Numeric),
      is_real: be_in([true, false])
    )
  end

  context 'without work' do
    before(:all) do
      DatabaseCleaner.start

      book = FactoryBot.create :content_book, title: 'Physics (Demo)'
      AddEcosystemToCourse[course: @course.reload, ecosystem: book.ecosystem]
    end

    after(:all) { DatabaseCleaner.clean }

    context 'without periods' do
      before(:all) do
        DatabaseCleaner.start

        @period.reload.destroy
        @second_period.reload.destroy
      end

      after(:all)  { DatabaseCleaner.clean }

      it 'returns an empty array' do
        expect(guide).to eq []
      end
    end

    context 'with periods' do
      it 'returns an empty guide per period' do
        expect(guide).to match [
          {
            period_id: @period.id,
            title: 'Physics (Demo)',
            page_ids: [],
            children: []
          },
          {
            period_id: @second_period.id,
            title: 'Physics (Demo)',
            page_ids: [],
            children: []
          }
        ]
      end
    end

  end

  context 'with work' do
    before(:all) do
      DatabaseCleaner.start

      VCR.use_cassette('GetCourseGuide/setup_course_guide', VCR_OPTS) do
        CreateStudentHistory[course: @course.reload, roles: [@role.reload, @second_role.reload]]
      end
    end

    after(:all)  { DatabaseCleaner.clean }

    it 'returns all course guide periods for teachers' do
      expect(guide).to match [
        {
          period_id: @period.id,
          title: 'Physics (Demo)',
          page_ids: [kind_of(Integer)]*6,
          children: [kind_of(Hash)]*2
        },
        {
          period_id: @second_period.id,
          title: 'Physics (Demo)',
          page_ids: [kind_of(Integer)]*6,
          children: [kind_of(Hash)]*2
        }
      ]

      expect(period_1_worked_chapters).to eq period_1_chapters
      expect(period_2_worked_chapters).to eq period_2_chapters
    end

    it 'includes chapter stats for each period' do
      period_1_chapter_1 = period_1_chapters.first
      expect(period_1_chapter_1).to match(
        title: 'Acceleration',
        book_location: [],
        student_count: 1,
        questions_answered_count: 2,
        clue: clue_matcher,
        page_ids: [kind_of(Integer)]*2,
        children: [kind_of(Hash)]*2
      )

      period_1_chapter_2 = period_1_chapters.second
      expect(period_1_chapter_2).to match(
        title: "Force and Newton's Laws of Motion",
        book_location: [],
        student_count: 1,
        questions_answered_count: 7,
        clue: clue_matcher,
        page_ids: [kind_of(Integer)]*4,
        children: [kind_of(Hash)]*4
      )

      period_2_chapter_1 = period_2_chapters.first
      expect(period_2_chapter_1).to match(
        title: 'Acceleration',
        book_location: [],
        student_count: 1,
        questions_answered_count: 5,
        clue: clue_matcher,
        page_ids: [kind_of(Integer)]*2,
        children: [kind_of(Hash)]*2
      )

      period_2_chapter_2 = period_2_chapters.second
      expect(period_2_chapter_2).to match(
        title: "Force and Newton's Laws of Motion",
        book_location: [],
        student_count: 1,
        questions_answered_count: 5,
        clue: clue_matcher,
        page_ids: [kind_of(Integer)]*4,
        children: [kind_of(Hash)]*4
      )
    end

    it 'includes page stats for each period and each chapter' do
      period_1_chapter_1_pages = period_1_chapters.first['children']
      expect(period_1_chapter_1_pages).to match [
        {
          title: 'Acceleration',
          book_location: [],
          student_count: 1,
          questions_answered_count: 2,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Representing Acceleration with Equations and Graphs',
          book_location: [],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        }
      ]

      period_1_chapter_2_pages = period_1_chapters.second['children']
      expect(period_1_chapter_2_pages).to match [
        {
          title: 'Force',
          book_location: [],
          student_count: 1,
          questions_answered_count: 2,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: "Newton's First Law of Motion: Inertia",
          book_location: [],
          student_count: 1,
          questions_answered_count: 5,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: "Newton's Second Law of Motion",
          book_location: [],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: "Newton's Third Law of Motion",
          book_location: [],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        }
      ]

      period_2_chapter_1_pages = period_2_chapters.first['children']
      expect(period_2_chapter_1_pages).to match [
        {
          title: 'Acceleration',
          book_location: [],
          student_count: 1,
          questions_answered_count: 5,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Representing Acceleration with Equations and Graphs',
          book_location: [],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        }
      ]

      period_2_chapter_2_pages = period_2_chapters.second['children']
      expect(period_2_chapter_2_pages).to match [
        {
          title: 'Force',
          book_location: [],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: "Newton's First Law of Motion: Inertia",
          book_location: [],
          student_count: 1,
          questions_answered_count: 5,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: "Newton's Second Law of Motion",
          book_location: [],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: "Newton's Third Law of Motion",
          book_location: [],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
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

    it 'displays unworked chapters and ignores units' do
      expect(period_1_worked_chapters).not_to eq period_1_chapters
      expect(period_2_worked_chapters).not_to eq period_2_chapters

      period_1_chapter_1_pages = period_1_chapters.first['children']
      expect(period_1_chapter_1_pages).to match [
        {
          title: 'The Science of Biology',
          book_location: [1, 1],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Themes and Concepts of Biology',
          book_location: [1, 2],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        }
      ]

      period_1_chapter_2_pages = period_1_chapters.second['children']
      expect(period_1_chapter_2_pages).to match [
        {
          title: 'Atoms, Isotopes, Ions, and Molecules: The Building Blocks',
          book_location: [2, 1],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Water',
          book_location: [2, 2],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Carbon',
          book_location: [2, 3],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        }
      ]

      expect(period_1_chapters.third).to eq period_1_worked_chapters.first
      period_1_chapter_3_pages = period_1_chapters.third['children']
      expect(period_1_chapter_3_pages).to match [
        {
          title: 'Synthesis of Biological Macromolecules',
          book_location: [3, 1],
          student_count: 1,
          questions_answered_count: 2,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Carbohydrates',
          book_location: [3, 2],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Lipids',
          book_location: [3, 3],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Proteins',
          book_location: [3, 4],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Nucleic Acids',
          book_location: [3, 5],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        }
      ]

      expect(period_1_chapters.fourth).to eq period_1_worked_chapters.second
      period_1_chapter_4_pages = period_1_chapters.fourth['children']
      expect(period_1_chapter_4_pages).to match [
        {
          title: 'Studying Cells',
          book_location: [4, 1],
          student_count: 1,
          questions_answered_count: 2,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Prokaryotic Cells',
          book_location: [4, 2],
          student_count: 1,
          questions_answered_count: 5,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Eukaryotic Cells',
          book_location: [4, 3],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'The Endomembrane System and Proteins',
          book_location: [4, 4],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Cytoskeleton',
          book_location: [4, 5],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Connections between Cells and Cellular Activities',
          book_location: [4, 6],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        }
      ]

      period_2_chapter_1_pages = period_2_chapters.first['children']
      expect(period_2_chapter_1_pages).to match [
        {
          title: 'The Science of Biology',
          book_location: [1, 1],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Themes and Concepts of Biology',
          book_location: [1, 2],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        }
      ]

      period_2_chapter_2_pages = period_2_chapters.second['children']
      expect(period_2_chapter_2_pages).to match [
        {
          title: 'Atoms, Isotopes, Ions, and Molecules: The Building Blocks',
          book_location: [2, 1],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Water',
          book_location: [2, 2],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Carbon',
          book_location: [2, 3],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        }
      ]

      expect(period_2_chapters.third).to eq period_2_worked_chapters.first
      period_2_chapter_3_pages = period_2_chapters.third['children']
      expect(period_2_chapter_3_pages).to match [
        {
          title: 'Synthesis of Biological Macromolecules',
          book_location: [3, 1],
          student_count: 1,
          questions_answered_count: 5,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Carbohydrates',
          book_location: [3, 2],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Lipids',
          book_location: [3, 3],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Proteins',
          book_location: [3, 4],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Nucleic Acids',
          book_location: [3, 5],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        }
      ]

      expect(period_2_chapters.fourth).to eq period_2_worked_chapters.second
      period_2_chapter_4_pages = period_2_chapters.fourth['children']
      expect(period_2_chapter_4_pages).to match [
        {
          title: 'Studying Cells',
          book_location: [4, 1],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Prokaryotic Cells',
          book_location: [4, 2],
          student_count: 1,
          questions_answered_count: 5,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Eukaryotic Cells',
          book_location: [4, 3],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'The Endomembrane System and Proteins',
          book_location: [4, 4],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Cytoskeleton',
          book_location: [4, 5],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        },
        {
          title: 'Connections between Cells and Cellular Activities',
          book_location: [4, 6],
          student_count: 1,
          questions_answered_count: 0,
          clue: clue_matcher,
          page_ids: [kind_of(Integer)]
        }
      ]
    end
  end
end
