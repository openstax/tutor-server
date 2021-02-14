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
          :book => {:archive_url_base=>"https://archive.cnx.org/contents/", :reading_processing_instructions=>[{:css=>".ost-reading-discard, .os-teacher, [data-type=\"glossary\"]", :except=>["snap-lab"], :fragments=>[]}, {:css=>".ost-feature:has-descendants(\".os-exercise\",2),\n.ost-feature:has-descendants(\".ost-exercise-choice\"),\n.ost-assessed-feature:has-descendants(\".os-exercise\",2),\n.ost-assessed-feature:has-descendants(\".ost-exercise-choice\")", :fragments=>["node", "optional_exercise"]}, {:css=>".ost-feature:has-descendants(\".os-exercise, .ost-exercise-choice\"),\n.ost-assessed-feature:has-descendants(\".os-exercise, .ost-exercise-choice\")", :fragments=>["node", "exercise"]}, {:css=>".ost-feature .ost-exercise-choice,\n.ost-assessed-feature .ost-exercise-choice,\n.ost-feature .os-exercise,\n.ost-assessed-feature .os-exercise", :fragments=>[]}, {:css=>".ost-exercise-choice", :fragments=>["exercise", "optional_exercise"]}, {:css=>".os-exercise", :fragments=>["exercise"]}, {:css=>".ost-video", :fragments=>["video"]}, {:css=>".os-interactive, .ost-interactive", :fragments=>["interactive"]}, {:css=>".worked-example", :fragments=>["reading"], :labels=>["worked-example"]}, {:css=>".ost-feature, .ost-assessed-feature", :fragments=>["reading"]}], :uuid=>"405335a3-7cff-4df2-a9ad-29062a4af261", :version=>"8.32"},
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
              username: 'spec_teacher_1',
              full_name: 'Spec Teacher 1 Full name',
              first_name: 'Spec Teacher 1 First name',
              last_name: 'Spec Teacher 1 Last name'
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
         :course => {:ends_at=>"<%= Time.current + 119.days %>", :is_college=>true, :is_test=>false, :name=>"Spec Course 1", :periods=>[{:enrollment_code=>"Spec Period 1 Enrollment Code", :name=>"Spec Period 1", :students=>[{:first_name=>"Spec Student 1 First name", :full_name=>"Spec Student 1 Full name", :last_name=>"Spec Student 1 Last name", :username=>"spec_student_1"}, {:first_name=>"Spec Student 2 First name", :full_name=>"Spec Student 2 Full name", :last_name=>"Spec Student 2 Last name", :username=>"spec_student_2"}, {:first_name=>"Spec Student 3 First name", :full_name=>"Spec Student 3 Full name", :last_name=>"Spec Student 3 Last name", :username=>"spec_student_3"}, {:first_name=>"Spec Student 4 First name", :full_name=>"Spec Student 4 Full name", :last_name=>"Spec Student 4 Last name", :username=>"spec_student_4"}, {:first_name=>"Spec Student 5 First name", :full_name=>"Spec Student 5 Full name", :last_name=>"Spec Student 5 Last name", :username=>"spec_student_5"}, {:first_name=>"Spec Student 6 First name", :full_name=>"Spec Student 6 Full name", :last_name=>"Spec Student 6 Last name", :username=>"spec_student_6"}, {:first_name=>"Spec Student 7 First name", :full_name=>"Spec Student 7 Full name", :last_name=>"Spec Student 7 Last name", :username=>"spec_student_7"}, {:first_name=>"Spec Student 8 First name", :full_name=>"Spec Student 8 Full name", :last_name=>"Spec Student 8 Last name", :username=>"spec_student_8"}, {:first_name=>"Spec Student 9 First name", :full_name=>"Spec Student 9 Full name", :last_name=>"Spec Student 9 Last name", :username=>"spec_student_9"}, {:first_name=>"Spec Student 10 First name", :full_name=>"Spec Student 10 Full name", :last_name=>"Spec Student 10 Last name", :username=>"spec_student_10"}]}], :starts_at=>"<%= Time.current - 62.days %>", :teachers=>[{:first_name=>"Spec Teacher 1 First name", :full_name=>"Spec Teacher 1 Full name", :last_name=>"Spec Teacher 1 Last name", :username=>"spec_teacher_1"}], :term=>"demo", :year=>2021}
        }
        expected_data[:course][:is_college] = course.is_college unless course.is_college.nil?

        expect(YAML.load(data).deep_symbolize_keys).to match expected_data
      when 'config/demo/spec/assign/Spec Course 1.yml.erb'
        expect(YAML.load(data).deep_symbolize_keys).to match(
         :course => {:name=>"Spec Course 1", :task_plans=>[{:assigned_to=>[{:closes_at=>"<%= Time.current + 37.days %>", :due_at=>"<%= Time.current + 37.days %>", :opens_at=>"<%= Time.current + 30.days %>", :period=>{:name=>"Spec Period 1"}}], :book_indices=>[[0, 0], [0, 1], [0, 2]], :is_published=>true, :title=>"Spec Reading 1", :type=>"reading"}, {:assigned_to=>[{:closes_at=>"<%= Time.current + 37.days %>", :due_at=>"<%= Time.current + 37.days %>", :opens_at=>"<%= Time.current + 30.days %>", :period=>{:name=>"Spec Period 1"}}], :book_indices=>[[0, 0], [0, 1], [0, 2]], :exercises_count_core=>5, :exercises_count_dynamic=>4, :is_published=>true, :title=>"Spec Homework 1", :type=>"homework"}, {:assigned_to=>[{:closes_at=>"<%= Time.current + 37.days %>", :due_at=>"<%= Time.current + 37.days %>", :opens_at=>"<%= Time.current + 30.days %>", :period=>{:name=>"Spec Period 1"}}], :external_url=>"https://example.com/Spec External 1", :is_published=>true, :title=>"Spec External 1", :type=>"external"}]},
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
