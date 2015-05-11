require 'rails_helper'
require 'vcr_helper'
VCR_OPTS.merge!(record: :new_episodes)

RSpec.describe GetCourseStats, vcr: VCR_OPTS do

  before(:all) do
    @course = Entity::Course.create!
    @student = Entity::User.create!
    @role = AddUserAsCourseStudent.call(course: @course, user: @student).outputs.role
    capture_stdout { SetupCourseStats[course: @course, role: @role] }
  end

  after(:all) do
    #CleanupCourseStatsSetup[]
  end

  it 'gets the task steps for the role' do
    stats = described_class.call(course: @course, role: @role)
    expect(stats.outputs).to have(14).task_steps
  end

  it 'gets the book' do
    stats = described_class.call(course: @course, role: @role)
    book = Entity::Book.last
    expect(stats.outputs.books.last).to eq(book)
  end

  it 'visits the book TOC and Page Data' do
    stats = described_class.call(course: @course, role: @role)
    expect(stats.outputs.toc.first.title).to eq("Forces and Newton's Laws of Motion")
    expect(stats.outputs.page_data).to have(5).items
  end

  it 'returns the full course stats' do
    expect(described_class[course: @course, role: @role].to_hash).to include(
      hash_including(
        "title"=>"Forces and Newton's Laws of Motion",
        "page_ids"=>kind_of(Array),
        "children"=>array_including(
          hash_including(
            "id"=>kind_of(Integer),
            "title"=>"Forces and Newton's Laws of Motion",
            "chapter_section"=>"1",
            "questions_answered_count"=>14,
            "current_level"=>kind_of(Float),
            "practice_count"=>0,
            "page_ids"=>kind_of(Array),
            "children"=>array_including(
              hash_including(
                "id"=>kind_of(Integer),
                "title"=>kind_of(String),
                "chapter_section"=>kind_of(String),
                "questions_answered_count"=>kind_of(Integer),
                "current_level"=>kind_of(Float),
                "practice_count"=>0,
                "page_ids"=>kind_of(Array)
              )
            ) # /array_including - nested children
          ) # /hash_including - the children
        ) # /array_including - children
      ) # /hash_including - root
    ) # /include
  end
end
