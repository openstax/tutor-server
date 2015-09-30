require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe GetStudentGuide, type: :routine do

  before(:all) do
    DatabaseCleaner.start
    @course = Entity::Course.create!

    @period = CreatePeriod[course: @course]
    @second_period = CreatePeriod[course: @course]

    teacher_profile = FactoryGirl.create(:user_profile)
    teacher_strategy = User::Strategies::Direct::User.new(teacher_profile)
    @teacher = User::User.new(strategy: teacher_strategy)

    student_profile = FactoryGirl.create(:user_profile)
    student_strategy = User::Strategies::Direct::User.new(student_profile)
    @student = User::User.new(strategy: student_strategy)

    student_profile_2 = FactoryGirl.create(:user_profile)
    student_strategy_2 = User::Strategies::Direct::User.new(student_profile_2)
    @second_student = User::User.new(strategy: student_strategy_2)

    @role = AddUserAsPeriodStudent[period: @period, user: @student]
    @second_role = AddUserAsPeriodStudent[period: @second_period, user: @second_student]
    @teacher_role = AddUserAsCourseTeacher[course: @course, user: @teacher]

    VCR.use_cassette("GetCourseGuide/setup_course_guide", VCR_OPTS) do
      capture_stdout do
        CreateStudentHistory[course: @course, roles: [@role, @second_role]]
      end
    end
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  it 'gets the completed task step counts for the role' do
    result = described_class[role: @role]
    total_count = result['children'].map{ |cc| cc['questions_answered_count'] }.reduce(:+)
    expect(total_count).to eq 9

    result = described_class[role: @second_role]
    total_count = result['children'].map{ |cc| cc['questions_answered_count'] }.reduce(:+)
    expect(total_count).to eq 10
  end

  it 'returns the period course guide for a student' do
    result = described_class[role: @role]

    expect(result).to match a_hash_including(
      "title"=>"Physics (Demo)",
      "page_ids"=>[kind_of(Integer)]*3,
      "children"=> array_including(kind_of(Hash))
    )
  end

  it "returns each book's stats for the course period" do
    book = described_class[role: @role]['children'].first

    expect([book]).to include(a_hash_including(
      "title"=>"Acceleration",
      "book_location"=>[3],
      "questions_answered_count"=>2,
      "clue" => {
        "value" => kind_of(Float),
        "value_interpretation" => kind_of(String),
        "confidence_interval" => kind_of(Array),
        "confidence_interval_interpretation" => kind_of(String),
        "sample_size" => kind_of(Integer),
        "sample_size_interpretation" => kind_of(String),
        "unique_learner_count" => kind_of(Integer)
      },
      "practice_count"=>0,
      "page_ids"=>[kind_of(Integer)],
      "children"=> array_including(kind_of(Hash))
    ))
  end

  it "returns each book part's stats for the course period" do
    parts = described_class[role: @role]['children'].first['children']

    expect(parts).to match a_hash_including(
      "title"=>"Acceleration",
      "book_location"=>[3, 1],
      "questions_answered_count"=>2,
      "clue" => {
        "value" => kind_of(Float),
        "value_interpretation" => kind_of(String),
        "confidence_interval" => kind_of(Array),
        "confidence_interval_interpretation" => kind_of(String),
        "sample_size" => kind_of(Integer),
        "sample_size_interpretation" => kind_of(String),
        "unique_learner_count" => kind_of(Integer)
      },
      "practice_count"=>0,
      "page_ids"=>[kind_of(Integer)]
    )
  end

end
