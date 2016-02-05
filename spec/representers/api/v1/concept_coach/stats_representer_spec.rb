require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::ConceptCoach::StatsRepresenter, type: :representer,
                                                        speed: :medium do

  before(:all) do
    DatabaseCleaner.start

    ecosystem = VCR.use_cassette('Api_V1_ConceptCoach_StatsRepresenter/with_book',
                                 VCR_OPTS) do
      FetchAndImportBookAndCreateEcosystem[
        book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
      ]
    end

    @book = ecosystem.books.first

    page_model_1 = Content::Models::Page.find_by(title: 'Acceleration')
    page_model_2 = Content::Models::Page.find_by(
      title: 'Representing Acceleration with Equations and Graphs'
    )
    page_model_3 = Content::Models::Page.find_by(title: 'Force')

    @page_1 = Content::Page.new(strategy: page_model_1.reload.wrap)
    @page_2 = Content::Page.new(strategy: page_model_2.reload.wrap)
    @page_3 = Content::Page.new(strategy: page_model_3.reload.wrap)

    period_model = FactoryGirl.create(:course_membership_period)
    @period = CourseMembership::Period.new(strategy: period_model.wrap)
    @course = @period.course
    @course.profile.update_attribute(:is_concept_coach, true)

    AddEcosystemToCourse[ecosystem: ecosystem, course: @course]

    @user_1 = FactoryGirl.create(:user)
    @user_2 = FactoryGirl.create(:user)

    AddUserAsPeriodStudent[user: @user_1, period: @period]
    AddUserAsPeriodStudent[user: @user_2, period: @period]

    @entity_tasks = [@page_1, @page_2, @page_3].flat_map do |page|
      [@user_1, @user_2].flat_map do |user|
        GetConceptCoach[user: user, cnx_book_id: page.chapter.book.uuid, cnx_page_id: page.uuid]
      end
    end
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  it "represents concept coach stats" do
    task_step = @entity_tasks.first.task.task_steps.select{ |ts| ts.tasked.exercise? }.first
    Hacks::AnswerExercise[task_step: task_step, is_correct: true]

    task_step = @entity_tasks.second.task.task_steps.select{ |ts| ts.tasked.exercise? }.first
    Hacks::AnswerExercise[task_step: task_step, is_correct: false]

    tasks = Tasks::Models::Task.where(entity_task_id: @entity_tasks.map(&:id))
    stats = Hashie::Mash.new(title: 'Test', stats: CalculateTaskStats[tasks: tasks])

    representation = described_class.new(stats).as_json
    expect(representation).to include(
      "title" => "Test",
      "type" => "concept_coach",
      "stats" => [
        {
          "period_id"                => @period.id.to_s,
          "name"                     => @period.name,
          "mean_grade_percent"       => {
            "based_on_attempted_problems" => 50,
            "based_on_assigned_problems" => 6
          },
          "total_count"              => 6,
          "complete_count"           => 0,
          "partially_complete_count" => 2,
          "current_pages"            => a_collection_containing_exactly(
            {
              "id"              => @page_1.id.to_s,
              "title"           => "Acceleration",
              "student_count"   => 2,
              "correct_count"   => 1,
              "incorrect_count" => 1,
              "chapter_section" => [3, 1],
              "is_trouble" => false
            },
            {
              "id"              => @page_2.id.to_s,
              "title"           => "Representing Acceleration with Equations and Graphs",
              "student_count"   => 0,
              "correct_count"   => 0,
              "incorrect_count" => 0,
              "chapter_section" => [3, 2],
              "is_trouble" => false
            },
            {
              "id"              => @page_3.id.to_s,
              "title"           => "Force",
              "student_count"   => 0,
              "correct_count"   => 0,
              "incorrect_count" => 0,
              "chapter_section" => [4, 1],
              "is_trouble" => false
            }
          ),
          "spaced_pages" => a_collection_containing_exactly(
            "id"     => @page_1.id.to_s,
            "title"  => "Acceleration",
            "student_count"   => 0,
            "correct_count"   => 0,
            "incorrect_count" => 0,
            "chapter_section" => [3, 1],
            "is_trouble" => false
          ),
          "is_trouble" => false
        }
      ]
    )
  end

end
