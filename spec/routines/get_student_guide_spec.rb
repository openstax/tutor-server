require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe GetStudentGuide, type: :routine do

  before(:all) do
    @course = FactoryGirl.create :entity_course

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

    # Automatic cleanup is only done for top-level describe/context blocks
    # We need the cleanup here so this context will not interfere with the other context block
    before(:all) do
      DatabaseCleaner.start

      book = FactoryGirl.create :content_book, title: 'Physics (Demo)'
      ecosystem = Content::Ecosystem.new(strategy: book.ecosystem.wrap)
      AddEcosystemToCourse[course: @course, ecosystem: ecosystem]
    end

    after(:all) { DatabaseCleaner.clean }

    it 'does not blow up' do
      guide = described_class[role: @role]

      expect(guide).to match(
        {
          "period_id" => @period.id,
          "title" => 'Physics (Demo)',
          "page_ids" => [],
          "children" => []
        }
      )
    end

  end

  context 'with work' do

    # Automatic cleanup is only done for top-level describe/context blocks
    # We need the cleanup here so this context will not interfere with the other context block
    before(:all) do
      DatabaseCleaner.start

      VCR.use_cassette("GetCourseGuide/setup_course_guide", VCR_OPTS) do
        capture_stdout do
          CreateStudentHistory[course: @course.reload, roles: [@role, @second_role]]
        end
      end
    end

    after(:all) { DatabaseCleaner.clean }

    it 'gets the completed task step counts for the role' do
      result = described_class[role: @role]
      total_count = result['children'].map{ |cc| cc['questions_answered_count'] }.reduce(0, :+)
      expect(total_count).to eq 9

      result = described_class[role: @second_role]
      total_count = result['children'].map{ |cc| cc['questions_answered_count'] }.reduce(0, :+)
      expect(total_count).to eq 10
    end

    it 'returns the period course guide for a student' do
      guide = described_class[role: @role]

      expect(guide).to match(
        "period_id" => @period.id,
        "title" => 'Physics (Demo)',
        "page_ids" => [kind_of(Integer)]*6,
        "children" => [kind_of(Hash)]*2
      )
    end

    it "includes chapter stats for the student only" do
      guide = described_class[role: @role]

      chapter_1 = guide['children'].first
      expect(chapter_1).to match(
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

      chapter_2 = guide['children'].second
      expect(chapter_2).to match(
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
    end

    it "includes page stats for the student only" do
      guide = described_class[role: @role]

      chapter_1_pages = guide['children'].first['children']
      expect(chapter_1_pages).to match [
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
          "title" => "Representing Acceleration with Equations and Graphs",
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

      chapter_2_pages = guide['children'].second['children']
      expect(chapter_2_pages).to match [
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
          "title" => "Newton's First Law of Motion: Inertia",
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
          "title" => "Newton's Second Law of Motion",
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
          "title" => "Newton's Third Law of Motion",
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

end
