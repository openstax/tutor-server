require 'rails_helper'

RSpec.describe Demo::Export, type: :routine do
  let(:reading)   { FactoryBot.create :tasked_task_plan, type: :reading }
  let(:course)    { reading.owner }
  let!(:homework) do
    reading_pages = Content::Models::Page.where(id: reading.settings['page_ids'])

    FactoryBot.create(
      :tasks_task_plan,
      type: :homework,
      owner: course,
      assistant_code_class_name: 'Tasks::Assistants::HomeworkAssistant',
      target: course.periods.first,
      settings: {
        page_ids: reading_pages.map(&:id).map(&:to_s),
        exercise_ids: reading_pages.first.exercises.first(5).map(&:id).map(&:to_s),
        exercises_count_dynamic: 4
      }
    ).tap { |task_plan| DistributeTasks.call task_plan: task_plan }
  end
  let!(:external) do
    FactoryBot.create(
      :tasks_task_plan,
      type: :external,
      owner: course,
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
  let(:book)      { ecosystem.books.first }
  let!(:teacher)  { FactoryBot.create :course_membership_teacher, course: course }

  let(:result)    { described_class.call name: :spec, courses: course }

  it 'creates anonymized demo configs with relativized dates from the given courses' do
    allow(OpenStax::Accounts.configuration).to receive(:enable_stubbing?).and_return(false)
    allow_any_instance_of(OpenStax::Accounts::Account).to(
      receive(:valid_openstax_uid?).and_return(true)
    )

    expect(OpenStax::Accounts::Api).not_to receive(:update_account)

    expect(File).to receive(:write).exactly(5).times do |path, data|
      case path
      when "config/demo/spec/import/#{offering.title}.yml"
        expect(YAML.load(data).deep_symbolize_keys).to eq(
          book: {
            archive_url_base: 'https://archive-staging-tutor.cnx.org/contents/',
            uuid: book.uuid,
            version: book.version.to_s,
            reading_processing_instructions: [
              {
                css: '.ost-reading-discard, .os-teacher, [data-type="glossary"]',
                fragments: [],
                except: ['snap-lab']
              },
              {
                fragments: ['node', 'optional_exercise'],
                css: <<~CSS.strip
                  .ost-feature:has-descendants(".os-exercise",2),
                  .ost-feature:has-descendants(".ost-exercise-choice"),
                  .ost-assessed-feature:has-descendants(".os-exercise",2),
                  .ost-assessed-feature:has-descendants(".ost-exercise-choice")
                CSS
              },
              {
                fragments: ['node', 'exercise'],
                css: <<~CSS.strip
                  .ost-feature:has-descendants(".os-exercise, .ost-exercise-choice"),
                  .ost-assessed-feature:has-descendants(".os-exercise, .ost-exercise-choice")
                CSS
              },
              {
                fragments: [],
                css: <<~CSS.strip
                  .ost-feature .ost-exercise-choice,
                  .ost-assessed-feature .ost-exercise-choice,
                  .ost-feature .os-exercise,
                  .ost-assessed-feature .os-exercise
                CSS
              },
              {
                css: '.ost-exercise-choice',
                fragments: ['exercise', 'optional_exercise']
              },
              {
                css: '.os-exercise',
                fragments: ['exercise']
              },
              {
                css: '.ost-video',
                fragments: ['video']
              },
              {
                css: '.os-interactive, .ost-interactive',
                fragments: ['interactive']
              },
              {
                css: '.worked-example',
                fragments: ['reading'],
                labels: ['worked-example']
              },
              {
                css: '.ost-feature, .ost-assessed-feature',
                fragments: ['reading']
              }
            ]
          },
          catalog_offering: {
            title: offering.title,
            description: offering.description,
            appearance_code: offering.appearance_code,
            salesforce_book_name: offering.salesforce_book_name,
            default_course_name: offering.default_course_name,
            webview_url_base: "#{offering.webview_url}/contents/",
            pdf_url_base: "#{offering.pdf_url}/exports/"
          }
        )
      when 'config/demo/spec/users/Spec Course 1.yml.erb'
        expect(YAML.load(data).deep_symbolize_keys).to eq(
          teachers: [
            {
              username: 'Spec_Teacher_1_Username',
              full_name: 'Spec Teacher 1 Full name',
              first_name: 'Spec Teacher 1 First name',
              last_name: 'Spec Teacher 1 Last name'
            }
          ],
          students: 10.times.map do |index|
            {
              username: "Spec_Student_#{index + 1}_Username",
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
            name: 'Spec Course 1',
            is_test: false,
            term: course.term,
            year: course.year,
            starts_at: /\A<%= Time\.current [+-] \d+\.days %>\z/,
            ends_at: /\A<%= Time\.current [+-] \d+\.days %>\z/,
            teachers: [
              {
                username: 'Spec_Teacher_1_Username',
                full_name: 'Spec Teacher 1 Full name',
                first_name: 'Spec Teacher 1 First name',
                last_name: 'Spec Teacher 1 Last name',
              }
            ],
            periods: [
              {
                name: 'Spec Period 1',
                enrollment_code: 'Spec Period 1 Enrollment Code',
                students: 10.times.map do |index|
                  {
                    username: "Spec_Student_#{index + 1}_Username",
                    full_name: "Spec Student #{index + 1} Full name",
                    first_name: "Spec Student #{index + 1} First name",
                    last_name: "Spec Student #{index + 1} Last name"
                  }
                end
              }
            ]
          }
        }
        expected_data[:course][:is_college] = course.is_college unless course.is_college.nil?

        expect(YAML.load(data).deep_symbolize_keys).to match expected_data
      when 'config/demo/spec/assign/Spec Course 1.yml.erb'
        expect(YAML.load(data).deep_symbolize_keys).to match(
          course: {
            name: 'Spec Course 1',
            task_plans: a_collection_containing_exactly(
              {
                title: 'Spec Reading 1',
                type: 'reading',
                book_locations: [
                  {
                    chapter: 1,
                    section: 1
                  }
                ],
                assigned_to: [
                  period: {
                    name: 'Spec Period 1'
                  },
                  opens_at: /\A<%= Time\.current [+-] \d+\.days %>\z/,
                  due_at: /\A<%= Time\.current [+-] \d+\.days %>\z/,
                  closes_at: /\A<%= Time\.current [+-] \d+\.days %>\z/
                ],
                is_published: true
              },
              {
                title: 'Spec Homework 1',
                type: 'homework',
                book_locations: [
                  {
                    chapter: 1,
                    section: 1
                  }
                ],
                exercises_count_core: 5,
                exercises_count_dynamic: 4,
                assigned_to: [
                  period: {
                    name: 'Spec Period 1'
                  },
                  opens_at: /\A<%= Time\.current [+-] \d+\.days %>\z/,
                  due_at: /\A<%= Time\.current [+-] \d+\.days %>\z/,
                  closes_at: /\A<%= Time\.current [+-] \d+\.days %>\z/
                ],
                is_published: true
              },
              {
                title: 'Spec External 1',
                type: 'external',
                external_url: 'https://example.com/Spec External 1',
                assigned_to: [
                  period: {
                    name: 'Spec Period 1'
                  },
                  opens_at: /\A<%= Time\.current [+-] \d+\.days %>\z/,
                  due_at: /\A<%= Time\.current [+-] \d+\.days %>\z/,
                  closes_at: /\A<%= Time\.current [+-] \d+\.days %>\z/
                ],
                is_published: true
              }
            )
          }
        )
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
                          username: "Spec_Student_#{index + 1}_Username",
                          full_name: "Spec Student #{index + 1} Full name",
                          first_name: "Spec Student #{index + 1} First name",
                          last_name: "Spec Student #{index + 1} Last name"
                        },
                        progress: 0.0,
                        score: 0.0
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
                        username: "Spec_Student_#{index + 1}_Username",
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
