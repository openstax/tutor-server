require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe GetStudentGuide do

  before(:all) do
    DatabaseCleaner.start
    @course = Entity::Course.create!

    @period = CreatePeriod[course: @course]
    @second_period = CreatePeriod[course: @course]

    @teacher = Entity::User.create!
    @student = Entity::User.create!
    @second_student = Entity::User.create!

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
    expect(total_count).to eq 11

    result = described_class[role: @second_role]
    total_count = result['children'].map{ |cc| cc['questions_answered_count'] }.reduce(:+)
    expect(total_count).to eq 12
  end

  it 'returns the period course guide for a student' do
    result = described_class[role: @role]

    expect(result).to match a_hash_including(
      "title"=>"Physics",
      "page_ids"=>[kind_of(Integer)]*3,
      "children"=> array_including(kind_of(Hash))
    )
  end

  it "returns each book's stats for the course period" do
    book = described_class[role: @role]['children'].first

    expect([book]).to include(a_hash_including(
      "title"=>"Acceleration",
      "chapter_section"=>[3],
      "questions_answered_count"=>2,
      "current_level"=>kind_of(Float),
      "interpretation"=>kind_of(String),
      "practice_count"=>0,
      "page_ids"=>[kind_of(Integer)],
      "children"=> array_including(kind_of(Hash))
    ))
  end

  it "returns each book part's stats for the course period" do
    parts = described_class[role: @role]['children'].first['children']

    expect(parts).to match a_hash_including(
      "title"=>"Acceleration",
      "chapter_section"=>[3, 1],
      "questions_answered_count"=>2,
      "current_level"=>kind_of(Float),
      "interpretation"=>kind_of(String),
      "practice_count"=>0,
      "page_ids"=>[kind_of(Integer)]
    )
  end

end
