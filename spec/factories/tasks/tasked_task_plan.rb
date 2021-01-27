# To allow use in the development environment
if Rails.env.development?
  require_relative '../../vcr_helper'
  require_relative '../../support/fake_exercise_uuids'
end

FactoryBot.define do
  factory :tasked_task_plan, parent: :tasks_task_plan do
    type      { 'reading' }

    assistant do
      Tasks::Models::Assistant.find_by(
        code_class_name: 'Tasks::Assistants::IReadingAssistant'
      ) || FactoryBot.create(
        :tasks_assistant, code_class_name: 'Tasks::Assistants::IReadingAssistant'
      )
    end

    transient do
      page_hash do
        {
          id: '640e3e84-09a5-4033-b2a7-b7fe5ec29dc6',
          title: "<span class=\"os-number\">1.1</span><span class=\"os-divider\"> </span><span data-type=\"\" itemprop=\"\" class=\"os-text\">Newton's First Law of Motion: Inertia</span>"
        }
      end

      chapter_hash do
        {
          title: "<span class=\"os-number\">1</span><span class=\"os-divider\"> </span><span data-type=\"\" itemprop=\"\" class=\"os-text\">Dynamics: Force and Newton's Laws of Motion</span>",
          contents: [ page_hash ]
        }
      end

      unit_hash do
        { title: 'Not a real Unit', contents: [ chapter_hash ] }
      end

      book_hash do
        {
          id: '93e2b09d-261c-4007-a987-0b3062fe154b',
          version: '4.4',
          title: 'College Physics with Courseware',
          tree: {
            id: '93e2b09d-261c-4007-a987-0b3062fe154b@4.4',
            title: 'College Physics with Courseware',
            contents: [ unit_hash ]
          }
        }
      end

      cnx_book { OpenStax::Cnx::V1::Book.new hash: book_hash.deep_stringify_keys }

      reading_processing_instructions do
        FactoryBot.build(:content_book).reading_processing_instructions
      end

      number_of_students { 10 }
    end

    course    { FactoryBot.build :course_profile_course, offering: nil }

    ecosystem do
      FactoryBot.create(:content_ecosystem).tap do |ecosystem|
        VCR.use_cassette('TaskedTaskPlan/with_inertia', VCR_OPTS) do
          OpenStax::Cnx::V1.with_archive_url('https://openstax.org/apps/archive/20201222.172624/') do
            Content::ImportBook[
              cnx_book: cnx_book,
              ecosystem: ecosystem,
              reading_processing_instructions: reading_processing_instructions
            ]
          end
        end

        AddEcosystemToCourse[course: course, ecosystem: ecosystem]
      end
    end

    settings { { page_ids: [ ecosystem.pages.last.id.to_s ] } }

    after(:build) do |task_plan, evaluator|
      course = task_plan.course
      period = course.periods.first || FactoryBot.create(
        :course_membership_period, course: course
      )

      evaluator.number_of_students.times do
        AddUserAsPeriodStudent.call(user: create(:user_profile), period: period)
      end

      task_plan.tasking_plans = [build(:tasks_tasking_plan, task_plan: task_plan, target: period)]
    end

    after(:create) { |task_plan, evaluator| DistributeTasks.call(task_plan: task_plan) }
  end
end
