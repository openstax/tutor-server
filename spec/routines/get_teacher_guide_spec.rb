require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe GetTeacherGuide, type: :routine do

  before(:all) do
    @course = FactoryGirl.create :course_profile_course

    @period = FactoryGirl.create :course_membership_period, course: @course
    @second_period = FactoryGirl.create :course_membership_period, course: @course

    @teacher = FactoryGirl.create(:user)
    @student = FactoryGirl.create(:user)
    @second_student = FactoryGirl.create(:user)

    @role = AddUserAsPeriodStudent[period: @period, user: @student]
    @second_role = AddUserAsPeriodStudent[period: @second_period, user: @second_student]
    @teacher_role = AddUserAsCourseTeacher[course: @course, user: @teacher]
  end

  context 'without work' do

    before(:all) do
      create_new_course_and_roles

      book = FactoryGirl.create :content_book, title: 'Physics (Demo)'
      ecosystem = Content::Ecosystem.new(strategy: book.ecosystem.wrap)
      AddEcosystemToCourse[course: @course, ecosystem: ecosystem]
    end

    it 'does not blow up' do
      guide = described_class[role: @teacher_role]

      expect(guide).to match [
        {
          "period_id" => @period.id,
          "title" => 'Physics (Demo)',
          "page_ids" => [],
          "children" => []
        },
        {
          "period_id" => @second_period.id,
          "title" => 'Physics (Demo)',
          "page_ids" => [],
          "children" => []
        }
      ]
    end

  end

  context 'with work' do

    before(:all) do
      create_new_course_and_roles

      VCR.use_cassette("GetCourseGuide/setup_course_guide", VCR_OPTS) do
        capture_stdout do
          CreateStudentHistory[course: @course, roles: [@role, @second_role]]
        end
      end
    end

    it 'returns all course guide periods for teachers' do
      guide = described_class[role: @teacher_role]

      expect(guide).to match [
        {
          "period_id" => @period.id,
          "title" => 'Physics (Demo)',
          "page_ids" => [kind_of(Integer)]*6,
          "children" => [kind_of(Hash)]*2
        },
        {
          "period_id" => @second_period.id,
          "title" => 'Physics (Demo)',
          "page_ids" => [kind_of(Integer)]*6,
          "children" => [kind_of(Hash)]*2
        }
      ]
    end

    it 'includes chapter stats for each period' do
      guide = described_class[role: @teacher_role]

      period_1_chapter_1 = guide.first['children'].first
      expect(period_1_chapter_1).to match(
        "title" => "Acceleration",
        "book_location" => [3],
        "questions_answered_count" => 2,
        "clue" => {
          "value" => kind_of(Float),
          "value_interpretation" => kind_of(String),
          "confidence_interval" => kind_of(Array),
          "confidence_interval_interpretation" => kind_of(String),
          "sample_size" => kind_of(Integer),
          "sample_size_interpretation" => kind_of(String),
          "unique_learner_count" => kind_of(Integer)
        },
        "practice_count" => 0,
        "page_ids" => [kind_of(Integer)]*2,
        "children" => [kind_of(Hash)]*2
      )

      period_1_chapter_2 = guide.first['children'].second
      expect(period_1_chapter_2).to match(
        "title" => "Force and Newton's Laws of Motion",
        "book_location" => [4],
        "questions_answered_count" => 7,
        "clue" => {
          "value" => kind_of(Float),
          "value_interpretation" => kind_of(String),
          "confidence_interval" => kind_of(Array),
          "confidence_interval_interpretation" => kind_of(String),
          "sample_size" => kind_of(Integer),
          "sample_size_interpretation" => kind_of(String),
          "unique_learner_count" => kind_of(Integer)
        },
        "practice_count" => 0,
        "page_ids" => [kind_of(Integer)]*4,
        "children" => [kind_of(Hash)]*4
      )

      period_2_chapter_1 = guide.second['children'].first
      expect(period_2_chapter_1).to match(
        "title" => "Acceleration",
        "book_location" => [3],
        "questions_answered_count" => 5,
        "clue" => {
          "value" => kind_of(Float),
          "value_interpretation" => kind_of(String),
          "confidence_interval" => kind_of(Array),
          "confidence_interval_interpretation" => kind_of(String),
          "sample_size" => kind_of(Integer),
          "sample_size_interpretation" => kind_of(String),
          "unique_learner_count" => kind_of(Integer)
        },
        "practice_count" => 0,
        "page_ids" => [kind_of(Integer)]*2,
        "children" => [kind_of(Hash)]*2
      )

      period_2_chapter_2 = guide.second['children'].second
      expect(period_2_chapter_2).to match(
        "title" => "Force and Newton's Laws of Motion",
        "book_location" => [4],
        "questions_answered_count" => 5,
        "clue" => {
          "value" => kind_of(Float),
          "value_interpretation" => kind_of(String),
          "confidence_interval" => kind_of(Array),
          "confidence_interval_interpretation" => kind_of(String),
          "sample_size" => kind_of(Integer),
          "sample_size_interpretation" => kind_of(String),
          "unique_learner_count" => kind_of(Integer)
        },
        "practice_count" => 0,
        "page_ids" => [kind_of(Integer)]*4,
        "children" => [kind_of(Hash)]*4
      )
    end

    it 'includes page stats for each period and each chapter' do
      guide = described_class[role: @teacher_role]

      period_1_chapter_1_pages = guide.first['children'].first['children']
      expect(period_1_chapter_1_pages).to match [
        {
          "title" => "Acceleration",
          "book_location" => [3, 1],
          "questions_answered_count" => 2,
          "clue" => {
            "value" => kind_of(Float),
            "value_interpretation" => kind_of(String),
            "confidence_interval" => kind_of(Array),
            "confidence_interval_interpretation" => kind_of(String),
            "sample_size" => kind_of(Integer),
            "sample_size_interpretation" => kind_of(String),
            "unique_learner_count" => kind_of(Integer)
          },
          "practice_count" => 0,
          "page_ids" => [kind_of(Integer)]
        },
        {
          "title"=>"Representing Acceleration with Equations and Graphs",
          "book_location" => [3, 2],
          "questions_answered_count" => 0,
          "clue" => {
            "value" => kind_of(Float),
            "value_interpretation" => kind_of(String),
            "confidence_interval" => kind_of(Array),
            "confidence_interval_interpretation" => kind_of(String),
            "sample_size" => kind_of(Integer),
            "sample_size_interpretation" => kind_of(String),
            "unique_learner_count" => kind_of(Integer)
          },
          "practice_count" => 0,
          "page_ids" => [kind_of(Integer)]
        }
      ]

      period_1_chapter_2_pages = guide.first['children'].second['children']
      expect(period_1_chapter_2_pages).to match [
        {
          "title" => "Force",
          "book_location" => [4, 1],
          "questions_answered_count" => 2,
          "clue" => {
            "value" => kind_of(Float),
            "value_interpretation" => kind_of(String),
            "confidence_interval" => kind_of(Array),
            "confidence_interval_interpretation" => kind_of(String),
            "sample_size" => kind_of(Integer),
            "sample_size_interpretation" => kind_of(String),
            "unique_learner_count" => kind_of(Integer)
          },
          "practice_count" => 0,
          "page_ids" => [kind_of(Integer)]
        },
        {
          "title"=>"Newton's First Law of Motion: Inertia",
          "book_location" => [4, 2],
          "questions_answered_count" => 5,
          "clue" => {
            "value" => kind_of(Float),
            "value_interpretation" => kind_of(String),
            "confidence_interval" => kind_of(Array),
            "confidence_interval_interpretation" => kind_of(String),
            "sample_size" => kind_of(Integer),
            "sample_size_interpretation" => kind_of(String),
            "unique_learner_count" => kind_of(Integer)
          },
          "practice_count" => 0,
          "page_ids" => [kind_of(Integer)]
        },
        {
          "title"=>"Newton's Second Law of Motion",
          "book_location" => [4, 3],
          "questions_answered_count" => 0,
          "clue" => {
            "value" => kind_of(Float),
            "value_interpretation" => kind_of(String),
            "confidence_interval" => kind_of(Array),
            "confidence_interval_interpretation" => kind_of(String),
            "sample_size" => kind_of(Integer),
            "sample_size_interpretation" => kind_of(String),
            "unique_learner_count" => kind_of(Integer)
          },
          "practice_count" => 0,
          "page_ids" => [kind_of(Integer)]
        },
        {
          "title"=>"Newton's Third Law of Motion",
          "book_location" => [4, 4],
          "questions_answered_count" => 0,
          "clue" => {
            "value" => kind_of(Float),
            "value_interpretation" => kind_of(String),
            "confidence_interval" => kind_of(Array),
            "confidence_interval_interpretation" => kind_of(String),
            "sample_size" => kind_of(Integer),
            "sample_size_interpretation" => kind_of(String),
            "unique_learner_count" => kind_of(Integer)
          },
          "practice_count" => 0,
          "page_ids" => [kind_of(Integer)]
        }
      ]

      period_2_chapter_1_pages = guide.second['children'].first['children']
      expect(period_2_chapter_1_pages).to match [
        {
          "title" => "Acceleration",
          "book_location" => [3, 1],
          "questions_answered_count" => 5,
          "clue" => {
            "value" => kind_of(Float),
            "value_interpretation" => kind_of(String),
            "confidence_interval" => kind_of(Array),
            "confidence_interval_interpretation" => kind_of(String),
            "sample_size" => kind_of(Integer),
            "sample_size_interpretation" => kind_of(String),
            "unique_learner_count" => kind_of(Integer)
          },
          "practice_count" => 0,
          "page_ids" => [kind_of(Integer)]
        },
        {
          "title"=>"Representing Acceleration with Equations and Graphs",
          "book_location" => [3, 2],
          "questions_answered_count" => 0,
          "clue" => {
            "value" => kind_of(Float),
            "value_interpretation" => kind_of(String),
            "confidence_interval" => kind_of(Array),
            "confidence_interval_interpretation" => kind_of(String),
            "sample_size" => kind_of(Integer),
            "sample_size_interpretation" => kind_of(String),
            "unique_learner_count" => kind_of(Integer)
          },
          "practice_count" => 0,
          "page_ids" => [kind_of(Integer)]
        }
      ]

      period_2_chapter_2_pages = guide.second['children'].second['children']
      expect(period_2_chapter_2_pages).to match [
        {
          "title" => "Force",
          "book_location" => [4, 1],
          "questions_answered_count" => 0,
          "clue" => {
            "value" => kind_of(Float),
            "value_interpretation" => kind_of(String),
            "confidence_interval" => kind_of(Array),
            "confidence_interval_interpretation" => kind_of(String),
            "sample_size" => kind_of(Integer),
            "sample_size_interpretation" => kind_of(String),
            "unique_learner_count" => kind_of(Integer)
          },
          "practice_count" => 0,
          "page_ids" => [kind_of(Integer)]
        },
        {
          "title"=>"Newton's First Law of Motion: Inertia",
          "book_location" => [4, 2],
          "questions_answered_count" => 5,
          "clue" => {
            "value" => kind_of(Float),
            "value_interpretation" => kind_of(String),
            "confidence_interval" => kind_of(Array),
            "confidence_interval_interpretation" => kind_of(String),
            "sample_size" => kind_of(Integer),
            "sample_size_interpretation" => kind_of(String),
            "unique_learner_count" => kind_of(Integer)
          },
          "practice_count" => 0,
          "page_ids" => [kind_of(Integer)]
        },
        {
          "title"=>"Newton's Second Law of Motion",
          "book_location" => [4, 3],
          "questions_answered_count" => 0,
          "clue" => {
            "value" => kind_of(Float),
            "value_interpretation" => kind_of(String),
            "confidence_interval" => kind_of(Array),
            "confidence_interval_interpretation" => kind_of(String),
            "sample_size" => kind_of(Integer),
            "sample_size_interpretation" => kind_of(String),
            "unique_learner_count" => kind_of(Integer)
          },
          "practice_count" => 0,
          "page_ids" => [kind_of(Integer)]
        },
        {
          "title"=>"Newton's Third Law of Motion",
          "book_location" => [4, 4],
          "questions_answered_count" => 0,
          "clue" => {
            "value" => kind_of(Float),
            "value_interpretation" => kind_of(String),
            "confidence_interval" => kind_of(Array),
            "confidence_interval_interpretation" => kind_of(String),
            "sample_size" => kind_of(Integer),
            "sample_size_interpretation" => kind_of(String),
            "unique_learner_count" => kind_of(Integer)
          },
          "practice_count" => 0,
          "page_ids" => [kind_of(Integer)]
        }
      ]
    end

  end

  protected

  def create_new_course_and_roles
    @course = FactoryGirl.create :entity_course

    @period = CreatePeriod[course: @course]
    @second_period = CreatePeriod[course: @course]

    @teacher = FactoryGirl.create(:user)
    @student = FactoryGirl.create(:user)
    @second_student = FactoryGirl.create(:user)

    @role = AddUserAsPeriodStudent[period: @period, user: @student]
    @second_role = AddUserAsPeriodStudent[period: @second_period, user: @second_student]
    @teacher_role = AddUserAsCourseTeacher[course: @course, user: @teacher]
  end

end
