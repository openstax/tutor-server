require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe GetCourseGuide, vcr: VCR_OPTS do

  before(:all) do
    DatabaseCleaner.start
    @course = Entity::Course.create!

    @period = CreatePeriod[course: @course]
    @second_period = CreatePeriod[course: @course]

    @teacher = Entity::User.create!
    @student = Entity::User.create!
    @second_student = Entity::User.create!

    @role = AddUserAsPeriodStudent[period: @period,
                                   user: @student]
    @second_role = AddUserAsPeriodStudent[period: @second_period,
                                          user: @second_student]
    @teacher_role = AddUserAsCourseTeacher[course: @course,
                                           user: @teacher]

    VCR.use_cassette("GetCourseGuide/setup_course_guide", VCR_OPTS) do
      capture_stdout { CreateStudentHistory[course: @course, roles: [@role, @second_role]] }
    end
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  it 'gets the completed task steps for the role' do
    guide = described_class.call(course: @course, role: @role)
    expect(guide.outputs).to have(16).task_steps

    guide = described_class.call(course: @course, role: @second_role)
    expect(guide.outputs).to have(16).task_steps
  end

  it 'gets the book' do
    guide = described_class.call(course: @course, role: @role)
    book = Entity::Book.last
    expect(guide.outputs.books.last).to eq(book)

    guide = described_class.call(course: @course, role: @second_role)
    expect(guide.outputs.books.last).to eq(book)
  end

  it 'visits the book TOC and Page Data' do
    guide = described_class.call(course: @course, role: @role)
    expect(guide.outputs.toc.title).to eq("Physics")
    expect(guide.outputs.page_data).to have(8).items

    guide = described_class.call(course: @course, role: @second_role)
    expect(guide.outputs.toc.title).to eq("Physics")
    expect(guide.outputs.page_data).to have(8).items
  end

  it 'returns the period course guide for a student' do
    expect(described_class[course: @course, role: @role]).to include(a_hash_including(
      "title"=>"Physics",
      "page_ids"=>[kind_of(Integer), kind_of(Integer)],
      "children"=> array_including(kind_of(Hash))
    ))
  end

  it "returns each book's stats for the course period" do
    book = described_class[course: @course, role: @role].first['children'].first

    expect([book]).to include(a_hash_including(
      "id"=>kind_of(Integer),
      "title"=>"Force and Newton's Laws of Motion",
      "chapter_section"=>[4],
      "questions_answered_count"=>16,
      "current_level"=>kind_of(Float),
      "practice_count"=>0,
      "page_ids"=>[kind_of(Integer), kind_of(Integer)],
      "children"=> array_including(kind_of(Hash))
    ))
  end

  it "returns each book part's stats for the course period" do
    parts = described_class[course: @course, role: @role].first['children'].first['children']

    expect(parts).to include(
      a_hash_including("id"=>kind_of(Integer),
                       "title"=>"Force",
                       "chapter_section"=>[4, 1],
                       "questions_answered_count"=>11,
                       "current_level"=>kind_of(Float),
                       "practice_count"=>0,
                       "page_ids"=>[kind_of(Integer)]),
      a_hash_including("id"=>kind_of(Integer),
                       "title"=>"Newton's First Law of Motion: Inertia",
                       "chapter_section"=>[4, 2],
                       "questions_answered_count"=>5,
                       "current_level"=>kind_of(Float),
                       "practice_count"=>0,
                       "page_ids"=>[kind_of(Integer)]))
  end

  it 'returns all course guide periods for teachers' do
    expect(described_class[course: @course, role: @teacher_role]).to include({
      period_id: @period.id,
      title: 'Physics',
      page_ids: [kind_of(Integer), kind_of(Integer)],
      children: array_including(kind_of(Hash))
    },
    {
      period_id: @second_period.id,
      title: 'Physics',
      page_ids: [kind_of(Integer), kind_of(Integer)],
      children: array_including(kind_of(Hash))
    })
  end

  it 'includes the book stats for the periods' do
    book = described_class[course: @course, role: @teacher_role].first['children'].first

    expect([book]).to include(a_hash_including(
      "id" => kind_of(Integer),
      "title" => "Force and Newton's Laws of Motion",
      "chapter_section" => [4],
      "questions_answered_count" => 32,
      "current_level" => kind_of(Float),
      "practice_count" => 0,
      "page_ids" => [kind_of(Integer), kind_of(Integer)],
      "children" => array_including(kind_of(Hash))
    ))
  end

  it 'includes the book part stats for the periods' do
    book_parts = described_class[course: @course, role: @teacher_role].first['children']
                                                                      .first['children']

    expect(book_parts).to include(
      a_hash_including("id" => kind_of(Integer),
                       "title" => "Force",
                       "chapter_section" => [4, 1],
                       "questions_answered_count" => 22,
                       "current_level" => kind_of(Float),
                       "practice_count" => 0,
                       "page_ids" => [kind_of(Integer)]),
      a_hash_including("id" => kind_of(Integer),
                       "title" => "Newton's First Law of Motion: Inertia",
                       "chapter_section" => [4, 2],
                       "questions_answered_count" => 10,
                       "current_level" => kind_of(Float),
                       "practice_count" => 0,
                       "page_ids" => [kind_of(Integer)])
    )
  end
end
