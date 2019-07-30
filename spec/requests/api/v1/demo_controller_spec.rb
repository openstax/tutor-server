require 'rails_helper'

RSpec.describe Api::V1::DemoController, type: :request, api: true, version: :v1 do
  let(:teachers)     { [ FactoryBot.create(:user_profile) ] }
  let(:students)     { 6.times.map { FactoryBot.create :user_profile } }

  let(:book)             { FactoryBot.create :content_book }
  let(:ecosystem)        { FactoryBot.create :content_ecosystem, books: [ book ] }
  let(:catalog_offering) { FactoryBot.create :catalog_offering, ecosystem: ecosystem }

  let(:course)           { FactoryBot.create :course_profile_course, offering: catalog_offering }

  let(:task_plans)       { 2.times.map { FactoryBot.create :tasks_task_plan, owner: course } }

  let(:current_time)  { Time.current }

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
  let(:import_params) do
    {
      cnx_book_id: book.uuid,
      appearance_code: book.title.downcase.gsub(' ', '_'),
      reading_processing_instructions: []
    }
  end
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
  let(:assign_params) do
    {
      course: { name: course.name },
      task_plans: task_plans.map do |task_plan|
        {
          title: task_plan.title,
          type: task_plan.type,
          book_locations: [[1, 0], [1, 1], [1, 2]],
          assigned_to: [
            {
              period: { name: '1st' },
              opens_at: (current_time - 1.day).iso8601,
              due_at: (current_time + 1.day).iso8601
            }
          ]
        }
      end
    }
  end
  let(:work_params) do
    {
      course: { name: course.name },
      task_plans: task_plans.map do |task_plan|
        {
          title: task_plan.title,
          tasks: students.map do |student|
            {
              student: { username: student.username },
              progress: rand,
              score: rand
            }
          end
        }
      end
    }
  end

  context '#all' do
    let(:all_params) do
      {
        users: users_params,
        import: import_params,
        course: course_params,
        assign: assign_params,
        work: work_params
      }
    end

    it 'calls Demo::All with the given parameters' do
      expect(Demo::All).to receive(:perform_later).with(all_params)

      api_post 'demo/all', nil, params: all_params.to_json

      expect(response).to have_http_status(:accepted)
      expect(response.body_as_hash).to have_key :jobba_status_id
    end
  end

  context '#users' do
    it 'calls Demo::Users with the given parameters' do
      expect(Demo::Users).to receive(:call).with(users: users_params).and_return(
        Lev::Routine::Result.new(
          Lev::Outputs.new(users: teachers + students, teachers: teachers, students: students),
          Lev::Errors.new
        )
      )

      api_post 'demo/users', nil, params: users_params.to_json

      expect(response).to have_http_status(:ok)

      teachers_array = response.body_as_hash[:teachers]
      expect(teachers_array.size).to eq teachers.size
      teachers_attributes = teachers.map do |teacher|
        Api::V1::Demo::UserRepresenter.new(teacher).to_hash.deep_symbolize_keys
      end
      teachers_array.each { |teacher_hash| expect(teacher_hash).to be_in teachers_attributes }

      students_array = response.body_as_hash[:students]
      expect(students_array.size).to eq students.size
      students_attributes = students.map do |student|
        Api::V1::Demo::UserRepresenter.new(student).to_hash.deep_symbolize_keys
      end
      students_array.each { |student_hash| expect(student_hash).to be_in students_attributes }
    end
  end

  context '#import' do
    it 'calls Demo::Import with the given parameters' do
      expect(Demo::Import).to receive(:perform_later).with(import: import_params)

      api_post 'demo/import', nil, params: import_params.to_json

      expect(response).to have_http_status(:accepted)
      expect(response.body_as_hash).to have_key :jobba_status_id
    end
  end

  context '#course' do
    it 'calls Demo::Course with the given parameters' do
      expect(Demo::Course).to receive(:call).with(course: course_params).and_return(
        Lev::Routine::Result.new Lev::Outputs.new(course: course), Lev::Errors.new
      )

      api_post 'demo/course', nil, params: course_params.to_json

      expect(response).to have_http_status(:ok)
      course_hash = response.body_as_hash[:course]
      expect(course_hash[:name]).to eq course.name
    end
  end

  context '#assign' do
    it 'calls Demo::Assign with the given parameters' do
      expect(Demo::Assign).to receive(:call).with(assign: assign_params).and_return(
        Lev::Routine::Result.new Lev::Outputs.new(task_plans: task_plans), Lev::Errors.new
      )

      api_post 'demo/assign', nil, params: assign_params.to_json

      expect(response).to have_http_status(:ok)
      task_plans_array = response.body_as_hash[:task_plans]
      expect(task_plans_array.size).to eq task_plans.size
      task_plans_attributes = task_plans.map do |task_plan|
        Api::V1::Demo::Assign::TaskPlan::Representer.new(task_plan).to_hash.deep_symbolize_keys
      end
      task_plans_array.each do |task_plan_hash|
        expect(task_plan_hash).to be_in task_plans_attributes
      end
    end
  end

  context '#work' do
    it 'calls Demo::Work with the given parameters' do
      expect(Demo::Work).to receive(:call).with(work: work_params).and_return(
        Lev::Routine::Result.new Lev::Outputs.new, Lev::Errors.new
      )

      api_post 'demo/work', nil, params: work_params.to_json

      expect(response).to have_http_status(:no_content)
    end
  end
end
