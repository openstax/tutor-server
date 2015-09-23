require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe GetTeacherGuide, type: :routine do

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

  it 'returns all course guide periods for teachers' do
    result = described_class[role: @teacher_role]

    expect(result).to include({
      period_id: @period.id,
      title: 'Physics (Demo)',
      page_ids: [kind_of(Integer)]*3,
      children: array_including(kind_of(Hash))
    },
    {
      period_id: @second_period.id,
      title: 'Physics (Demo)',
      page_ids: [kind_of(Integer)]*2,
      children: array_including(kind_of(Hash))
    })
  end

  it 'includes the chapter stats for the periods' do
    period_1_chapter_1 = described_class[role: @teacher_role].first['children'].first

    expect([period_1_chapter_1]).to match a_hash_including(
      "title"=>"Acceleration",
      "book_location"=>[3],
      "questions_answered_count"=>2,
      "clue" => {
        "value" => kind_of(Float),
        "value_interpretation" => kind_of(String),
        "confidence_interval" => kind_of(Array),
        "confidence_interval_interpretation" => kind_of(String),
        "sample_size" => kind_of(Integer),
        "sample_size_interpretation" => kind_of(String)
      },
      "practice_count"=>0,
      "page_ids"=>[kind_of(Integer)],
      "children" => array_including(kind_of(Hash))
    )

    period_2_chapter_1 = described_class[role: @teacher_role].second['children'].first

    expect([period_2_chapter_1]).to match a_hash_including(
      "title"=>"Acceleration",
      "book_location"=>[3],
      "questions_answered_count"=>5,
      "clue" => {
        "value" => kind_of(Float),
        "value_interpretation" => kind_of(String),
        "confidence_interval" => kind_of(Array),
        "confidence_interval_interpretation" => kind_of(String),
        "sample_size" => kind_of(Integer),
        "sample_size_interpretation" => kind_of(String)
      },
      "practice_count"=>0,
      "page_ids"=>[kind_of(Integer)],
      "children" => array_including(kind_of(Hash))
    )
  end

  it 'includes the page stats for the periods' do
    period_1_pages = described_class[role: @teacher_role].first['children'].first['children']

    expect(period_1_pages).to include(
      a_hash_including("title"=>"Acceleration",
                       "book_location"=>[3, 1],
                       "questions_answered_count"=>2,
                       "clue" => {
                         "value" => kind_of(Float),
                         "value_interpretation" => kind_of(String),
                         "confidence_interval" => kind_of(Array),
                         "confidence_interval_interpretation" => kind_of(String),
                         "sample_size" => kind_of(Integer),
                         "sample_size_interpretation" => kind_of(String)
                       },
                       "practice_count"=>0,
                       "page_ids"=>[kind_of(Integer)])
    )

    period_2_pages = described_class[role: @teacher_role].second['children'].first['children']

    expect(period_2_pages).to include(
      a_hash_including("title"=>"Acceleration",
                       "book_location"=>[3, 1],
                       "questions_answered_count"=>5,
                       "clue" => {
                         "value" => kind_of(Float),
                         "value_interpretation" => kind_of(String),
                         "confidence_interval" => kind_of(Array),
                         "confidence_interval_interpretation" => kind_of(String),
                         "sample_size" => kind_of(Integer),
                         "sample_size_interpretation" => kind_of(String)
                       },
                       "practice_count"=>0,
                       "page_ids"=>[kind_of(Integer)])
    )
  end

end
