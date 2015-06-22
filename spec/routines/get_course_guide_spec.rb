require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe GetCourseGuide, vcr: VCR_OPTS do

  before(:all) do
    DatabaseCleaner.start
    @course = Entity::Course.create!
    @period = CreatePeriod[course: @course]
    @student = Entity::User.create!
    @role = AddUserAsPeriodStudent.call(period: @period, user: @student).outputs.role
    @student.reload

    VCR.use_cassette("GetCourseGuide/setup_course_guide", VCR_OPTS) do
      capture_stdout { SetupCourseGuide[course: @course, period: @period, role: @role] }
    end
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  it 'gets the task steps for the role' do
    guide = described_class.call(course: @course, role: @role)
    expect(guide.outputs).to have(14).task_steps
  end

  it 'gets the book' do
    guide = described_class.call(course: @course, role: @role)
    book = Entity::Book.last
    expect(guide.outputs.books.last).to eq(book)
  end

  it 'visits the book TOC and Page Data' do
    guide = described_class.call(course: @course, role: @role)
    expect(guide.outputs.toc.title).to eq("Physics")
    expect(guide.outputs.page_data).to have(8).items
  end

  it 'returns the full course guide' do
    expect(described_class[course: @course, role: @role]).to include({
       'period' => {
          id: kind_of(Integer),
          name: '1st'
        },
        'stats' => {
          "title"=>"Physics",
          "page_ids"=>kind_of(Array),
          "children"=>array_including(
            {
              "id"=>kind_of(Integer),
              "title"=>"Force and Newton's Laws of Motion",
              "chapter_section"=>[4],
              "questions_answered_count"=>14,
              "current_level"=>kind_of(Float),
              "practice_count"=>0,
              "page_ids"=>kind_of(Array),
              "children"=>array_including(
                {
                  "id"=>kind_of(Integer),
                  "title"=>kind_of(String),
                  "chapter_section"=>kind_of(Array),
                  "questions_answered_count"=>kind_of(Integer),
                  "current_level"=>kind_of(Float),
                  "practice_count"=>0,
                  "page_ids"=>kind_of(Array)
                }
              ) # /array_including - nested children
            } # /hash - the children
          ) # /array_including - children
        } # /stats
      }) # /be_a_hash_including
  end
end
