require 'rails_helper'

RSpec.describe Api::V1::DemoController, type: :request, api: true, version: :v1 do
  let(:teachers)     { [ FactoryBot.create(:user_profile) ] }
  let(:students)     { 6.times.map { FactoryBot.create :user_profile } }

  let(:book)             { FactoryBot.create :content_book }
  let(:ecosystem)        { FactoryBot.create :content_ecosystem, books: [ book ] }
  let(:catalog_offering) { FactoryBot.create :catalog_offering, ecosystem: ecosystem }

  let(:course)           { FactoryBot.create :course_profile_course, offering: catalog_offering }

  context '#users' do
    let(:users_params) do
      {
        teachers: teachers.map do |teacher|
          { username: teacher.username, full_name: teacher.full_name }
        end,
        students: students.map do |student|
          { username: student.username, full_name: student.full_name }
        end
      }
    end

    it 'calls Demo::Users with the given parameters' do
      expect(Demo::Users).to receive(:call).with(users: users_params).and_return(
        Lev::Routine::Result.new Lev::Outputs.new, Lev::Errors.new
      )

      api_post 'demo/users', nil, params: users_params.to_json

      expect(response).to have_http_status(:no_content)
    end
  end

  context '#import' do
    let(:import_params) do
      {
        cnx_book_id: book.uuid,
        appearance_code: book.title.downcase.gsub(' ', '_'),
        reading_processing_instructions: []
      }
    end

    it 'calls Demo::Import with the given parameters' do
      expect(Demo::Import).to receive(:call).with(import: import_params).and_return(
        Lev::Routine::Result.new Lev::Outputs.new(catalog_offering: catalog_offering),
        Lev::Errors.new
      )

      api_post 'demo/import', nil, params: import_params.to_json

      expect(response).to have_http_status(:success)
      catalog_offering_hash = response.body_as_hash[:catalog_offering]
      expect(catalog_offering_hash[:title]).to eq catalog_offering.title
    end
  end

  context '#course' do
    let(:course_params) do
      {
        course: { name: course.name },
        catalog_offering: { title: catalog_offering.title },
        teachers: teachers.map { |teacher| { username: teacher.username } },
        periods: [
          { name: '1st', students: students.map { |student| { username: student.username } } }
        ]
      }
    end

    it 'calls Demo::Course with the given parameters' do
      expect(Demo::Course).to receive(:call).with(course: course_params).and_return(
        Lev::Routine::Result.new Lev::Outputs.new(course: course), Lev::Errors.new
      )

      api_post 'demo/course', nil, params: course_params.to_json

      expect(response).to have_http_status(:success)
      course_hash = response.body_as_hash[:course]
      expect(course_hash[:name]).to eq course.name
    end
  end

  context '#assign' do
    let(:current_time)  { Time.current }
    let(:assign_params) do
      {
        course: { name: course.name },
        task_plans: [
          {
            title: 'Read Chapter 1 Intro and Sections 1 and 2',
            type: 'reading',
            book_locations: [[1, 0], [1, 1], [1, 2]],
            assigned_to: [
              {
                period: { name: '1st' },
                opens_at: (current_time - 1.day).iso8601,
                due_at: (current_time + 1.day).iso8601
              }
            ]
          }
        ]
      }
    end

    it 'calls Demo::Assign with the given parameters' do
      expect(Demo::Assign).to receive(:call).with(assign: assign_params).and_return(
        Lev::Routine::Result.new Lev::Outputs.new(task_plans: []), Lev::Errors.new
      )

      api_post 'demo/assign', nil, params: assign_params.to_json

      expect(response).to have_http_status(:no_content)
    end
  end

  context '#work' do
    let(:work_params) do
      {
        course: { name: course.name },
        task_plans: [
          {
            title: 'Read Chapter 1 Intro and Sections 1 and 2',
            tasks: students.map do |student|
              {
                student: { username: student.username },
                progress: rand,
                score: rand
              }
            end
          }
        ]
      }
    end

    it 'calls Demo::Work with the given parameters' do
      expect(Demo::Work).to receive(:call).with(work: work_params).and_return(
        Lev::Routine::Result.new Lev::Outputs.new, Lev::Errors.new
      )

      api_post 'demo/work', nil, params: work_params.to_json

      expect(response).to have_http_status(:no_content)
    end
  end
end
