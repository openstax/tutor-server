require 'rails_helper'

RSpec.describe Demo::Export, type: :routine do
  let(:reading)   { FactoryBot.create :tasked_task_plan, type: :reading }
  let(:course)    { reading.course }
  let!(:homework) do
    reading_pages = Content::Models::Page.where(id: reading.core_page_ids)

    FactoryBot.create(
      :tasks_task_plan,
      type: :homework,
      course: course,
      assistant_code_class_name: 'Tasks::Assistants::HomeworkAssistant',
      target: course.periods.first,
      settings: {
        page_ids: reading_pages.map(&:id).map(&:to_s),
        exercises: reading_pages.first.exercises.first(5).map do |exercise|
          { id: exercise.id.to_s, points: [ 1 ] * exercise.number_of_questions }
        end,
        exercises_count_dynamic: 4
      }
    ).tap { |task_plan| DistributeTasks.call task_plan: task_plan }
  end
  let!(:external) do
    FactoryBot.create(
      :tasks_task_plan,
      type: :external,
      course: course,
      assistant_code_class_name: 'Tasks::Assistants::ExternalAssignmentAssistant',
      target: course.periods.first,
      settings: { external_url: Faker::Internet.url }
    ).tap { |task_plan| DistributeTasks.call task_plan: task_plan }
  end
  let(:ecosystem) { course.ecosystems.first }
  let!(:offering) do
    FactoryBot.create(:catalog_offering, ecosystem: ecosystem).tap do |offering|
      course.update_attribute :offering, offering
    end
  end
  let(:book)             { ecosystem.books.first }
  let!(:teacher)         { FactoryBot.create :course_membership_teacher, course: course }
  let!(:dropped_teacher) do
    FactoryBot.create :course_membership_teacher, course: course, deleted_at: Time.current
  end

  let(:result) { described_class.call name: :spec, courses: course }

  before { course.periods.first.students.sort_by(&:created_at).last.destroy }

  it 'creates anonymized demo configs with relativized dates from the given courses' do
    allow(OpenStax::Accounts.configuration).to receive(:enable_stubbing?).and_return(false)
    allow_any_instance_of(OpenStax::Accounts::Account).to(
      receive(:valid_openstax_uid?).and_return(true)
    )

    expect(OpenStax::Accounts::Api).not_to receive(:update_account)

    reading_processing_instructions = book.reading_processing_instructions
                                          .map(&:deep_symbolize_keys)
    expect(File).to receive(:write).exactly(5).times do |path, data|
      case path
      when "config/demo/spec/import/#{offering.title}.yml"
        expect(YAML.load(data).deep_symbolize_keys).to match(
          book: {
            archive_version: book.archive_version,
            reading_processing_instructions: reading_processing_instructions,
            uuid: book.uuid,
            version: book.version
          },
          catalog_offering: {
            title: offering.title,
            description: offering.description,
            appearance_code: offering.appearance_code,
            salesforce_book_name: offering.salesforce_book_name,
            default_course_name: offering.default_course_name
          }
        )
      when 'config/demo/spec/users/Spec Course 1.yml.erb'
        expect(YAML.load(data).deep_symbolize_keys).to eq(
          teachers: [
            {
              username: 'spec_teacher_1',
              full_name: 'Spec Teacher 1 Full name',
              first_name: 'Spec Teacher 1 First name',
              last_name: 'Spec Teacher 1 Last name'
            },
            {
              username: 'spec_teacher_2',
              full_name: 'Spec Teacher 2 Full name',
              first_name: 'Spec Teacher 2 First name',
              last_name: 'Spec Teacher 2 Last name'
            }
          ],
          students: 10.times.map do |index|
            {
              username: "spec_student_#{index + 1}",
              full_name: "Spec Student #{index + 1} Full name",
              first_name: "Spec Student #{index + 1} First name",
              last_name: "Spec Student #{index + 1} Last name"
            }
          end
        )
      when 'config/demo/spec/course/Spec Course 1.yml.erb'
        expected_data = {
          catalog_offering: {
            title: offering.title
          },
          course: {
            starts_at: /\A<%= Time\.current [+-] \d+\.days %>\z/,
            ends_at: /\A<%= Time\.current [+-] \d+\.days %>\z/,
            is_college: course.is_college,
            is_test: course.is_test,
            name: 'Spec Course 1',
            periods: [
              {
                enrollment_code: "Spec Period 1 Enrollment Code",
                name: "Spec Period 1",
                students: 9.times.map do |index|
                  {
                    first_name: "Spec Student #{index + 1} First name",
                    full_name: "Spec Student #{index + 1} Full name",
                    last_name: "Spec Student #{index + 1} Last name",
                    username: "spec_student_#{index + 1}",
                    is_dropped: false
                  }
                end + [
                  {
                    first_name: "Spec Student 10 First name",
                    full_name: "Spec Student 10 Full name",
                    last_name: "Spec Student 10 Last name",
                    username: "spec_student_10",
                    is_dropped: true
                  }
                ]
              }
            ],
            teachers: [
              {
                first_name: 'Spec Teacher 1 First name',
                full_name: 'Spec Teacher 1 Full name',
                last_name: 'Spec Teacher 1 Last name',
                username: 'spec_teacher_1',
                is_dropped: false
              },
              {
                first_name: 'Spec Teacher 2 First name',
                full_name: 'Spec Teacher 2 Full name',
                last_name: 'Spec Teacher 2 Last name',
                username: 'spec_teacher_2',
                is_dropped: true
              }
            ],
            term: course.term,
            year: course.year
          }
        }
        expected_data[:course].delete(:is_college) if course.is_college.nil?
        expect(YAML.load(data).deep_symbolize_keys).to match expected_data
      when 'config/demo/spec/assign/Spec Course 1.yml.erb'
        task_plan_common_data = {
          assigned_to: [
            {
              closes_at: /\A<%= Time\.current [+-] \d+\.days %>\z/,
              due_at: /\A<%= Time\.current [+-] \d+\.days %>\z/,
              opens_at: /\A<%= Time\.current [+-] \d+\.days %>\z/,
              period: { name: 'Spec Period 1' }
            }
          ],
          is_published: true
        }

        expected_data = {
          course: {
            name: 'Spec Course 1',
            task_plans: [
              task_plan_common_data.merge(
                title: 'Spec Reading 1',
                type: reading.type,
                book_indices: be_kind_of(Array)
              ),
              task_plan_common_data.merge(
                title: 'Spec Homework 1',
                type: homework.type,
                book_indices: be_kind_of(Array),
                exercises_count_core: homework.settings['exercises'].size,
                exercises_count_dynamic: homework.settings['exercises_count_dynamic']
              ),
              task_plan_common_data.merge(
                title: 'Spec External 1',
                type: external.type,
                external_url: 'https://example.com/Spec External 1'
              )
            ]
          }
        }

        expect(YAML.load(data).deep_symbolize_keys).to match(expected_data)
      when 'config/demo/spec/work/Spec Course 1.yml.erb'
        expect(YAML.load(data).deep_symbolize_keys).to match(
          course: {
            name: 'Spec Course 1',
            task_plans: a_collection_containing_exactly(
              *[ reading, homework ].map do |task_plan|
                {
                  title: "Spec #{task_plan.type.humanize} 1",
                  tasks: a_collection_containing_exactly(
                    *10.times.map do |index|
                      {
                        student: {
                          username: "spec_student_#{index + 1}",
                          full_name: "Spec Student #{index + 1} Full name",
                          first_name: "Spec Student #{index + 1} First name",
                          last_name: "Spec Student #{index + 1} Last name"
                        },
                        progress: 0.0
                      }
                    end
                  )
                }
              end,
              {
                title: 'Spec External 1',
                tasks: a_collection_containing_exactly(
                  *10.times.map do |index|
                    {
                      student: {
                        username: "spec_student_#{index + 1}",
                        full_name: "Spec Student #{index + 1} Full name",
                        first_name: "Spec Student #{index + 1} First name",
                        last_name: "Spec Student #{index + 1} Last name"
                      },
                      progress: 0.0
                    }
                  end
                )
              }
            )
          }
        )
      else
        raise "Unexpected file written: #{path}"
      end
    end

    expect(result.errors).to be_empty
  end
end
