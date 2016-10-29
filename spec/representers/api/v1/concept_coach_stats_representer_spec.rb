require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::ConceptCoachStatsRepresenter, type: :representer, speed: :medium do

  before(:all) do
    ecosystem = VCR.use_cassette('Api_V1_ConceptCoachStatsRepresenter/with_book', VCR_OPTS) do
      OpenStax::Cnx::V1.with_archive_url('https://archive.cnx.org/') do
        FetchAndImportBookAndCreateEcosystem[book_cnx_id: 'f10533ca-f803-490d-b935-88899941197f']
      end
    end

    @book = ecosystem.books.first

    page_model_1 = Content::Models::Page.find_by(title: 'Sample module 1')
    page_model_2 = Content::Models::Page.find_by(title: 'The Science of Biology')
    page_model_3 = Content::Models::Page.find_by(title: 'Sample module 2')

    @page_1 = Content::Page.new(strategy: page_model_1.reload.wrap)
    @page_2 = Content::Page.new(strategy: page_model_2.reload.wrap)
    @page_3 = Content::Page.new(strategy: page_model_3.reload.wrap)

    period_model = FactoryGirl.create(:course_membership_period)
    @period = CourseMembership::Period.new(strategy: period_model.wrap)
    @course = @period.course
    @course.update_attribute(:is_concept_coach, true)

    AddEcosystemToCourse[ecosystem: ecosystem, course: @course]

    @user_1 = FactoryGirl.create(:user)
    @user_2 = FactoryGirl.create(:user)

    AddUserAsPeriodStudent[user: @user_1, period: @period]
    AddUserAsPeriodStudent[user: @user_2, period: @period]

    @tasks = [@page_1, @page_2, @page_3].flat_map do |page|
      [@user_1, @user_2].flat_map do |user|
        GetConceptCoach[user: user, cnx_book_id: page.chapter.book.uuid, cnx_page_id: page.uuid]
      end
    end
  end

  it "represents concept coach stats" do
    task_step = @tasks.first.task_steps.select{ |ts| ts.tasked.exercise? }.first
    Demo::AnswerExercise[task_step: task_step, is_correct: true]

    task_step = @tasks.second.task_steps.select{ |ts| ts.tasked.exercise? }.first
    Demo::AnswerExercise[task_step: task_step, is_correct: false]

    task_relation = Tasks::Models::Task.where(id: @tasks.map(&:id))
    stats = Hashie::Mash.new(title: 'Test', stats: CalculateTaskStats[tasks: task_relation])

    representation = described_class.new(stats).as_json
    expect(representation).to include(
      "title" => "Test",
      "type" => "concept_coach",
      "stats" => [
        {
          "period_id"                => @period.id.to_s,
          "name"                     => @period.name,
          "mean_grade_percent"       => 50,
          "total_count"              => 6,
          "complete_count"           => 0,
          "partially_complete_count" => 2,
          "current_pages"            => a_collection_containing_exactly(
            {
              "id"              => @page_1.id.to_s,
              "title"           => "Sample module 1",
              "student_count"   => 2,
              "correct_count"   => 1,
              "incorrect_count" => 1,
              "chapter_section" => [1, 1],
              "is_trouble" => false
            },
            {
              "id"              => @page_2.id.to_s,
              "title"           => "The Science of Biology",
              "student_count"   => 0,
              "correct_count"   => 0,
              "incorrect_count" => 0,
              "chapter_section" => [1, 2],
              "is_trouble" => false
            },
            {
              "id"              => @page_3.id.to_s,
              "title"           => "Sample module 2",
              "student_count"   => 0,
              "correct_count"   => 0,
              "incorrect_count" => 0,
              "chapter_section" => [2, 1],
              "is_trouble" => false
            }
          ),
          "spaced_pages" => a_collection_containing_exactly(
            "id"     => @page_1.id.to_s,
            "title"  => "Sample module 1",
            "student_count"   => 0,
            "correct_count"   => 0,
            "incorrect_count" => 0,
            "chapter_section" => [1, 1],
            "is_trouble" => false
          ),
          "is_trouble" => false
        }
      ]
    )
  end

end
