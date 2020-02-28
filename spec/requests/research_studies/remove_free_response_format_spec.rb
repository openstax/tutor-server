require "rails_helper"

RSpec.describe 'Task steps without free response field', type: :request,
                                                         api: true,
                                                         version: :v1 do

  before(:all) do
    @course = FactoryBot.create :course_profile_course
    @course.ecosystem.books << FactoryBot.create(:content_book, :standard_contents_1 )
    page_ids = @course.ecosystem.books.last.pages.pluck(:id)
    period = FactoryBot.create :course_membership_period, course: @course
    user = FactoryBot.create(:user_profile)
    user_role = AddUserAsPeriodStudent[user: user, period: period]
    @study = FactoryBot.create :research_study
    FactoryBot.create :research_cohort, name: 'B', study: @study

    Research::AddCourseToStudy[course: @course, study: @study]

    task_plan = FactoryBot.create :tasks_task_plan,
      owner: @course, ecosystem: @course.ecosystem,
      settings: { page_ids:  page_ids }

    @task = FactoryBot.create :tasks_task, task_plan: task_plan,
                              step_types: [:tasks_tasked_exercise]

    @task.task_steps.each { |ts| ts.update_attributes(content_page_id: page_ids.first) }
    FactoryBot.create :tasks_tasking, role: user_role, task: @task

    @token = FactoryBot.create :doorkeeper_access_token, resource_owner_id: user.id
  end

  before(:each) { @study.deactivate! }

  it "can hide free-response formats when displaying a task" do

    brain = FactoryBot.create :research_modified_task,
                              study: @study,
                              name: 'no free-response for alternating sections',
                              code: <<~EOC
      unless task.reading? || task.homework?
       manipulation.ignore!
       return {}
      end

      choose_even = 'A' == cohort.name
      manipulated_task_step_ids = []

      task.task_steps.each do |ts|
        next unless ts.exercise?

        if choose_even && ts.page.book_location.last.even? ||
           !choose_even && ts.page.book_location.last.odd?

          manipulated_task_step_ids << ts.id
          ts.tasked.parser.questions_for_students.each do |q|
            q['formats'] -= ['free-response']
          end
        end
      end

      if manipulated_task_step_ids.any?
        manipulation.context[:task_step_ids] = manipulated_task_step_ids
        manipulation.record!
      else
        manipulation.ignore!
      end
    EOC

    @study.activate!

    expect do
      api_get "/api/tasks/#{@task.id}", @token
    end.to change { Research::Models::Manipulation.count }.by 1
    formats = response.body_as_hash[:steps].flat_map do |ts|
      ts.dig(:content, :questions, 0, :formats)
    end
    expect(formats).to_not include(:free_response)
    expect(brain.manipulations.last.target).to eq @task
  end

  it "can override requiring free-response when marking completed" do
    FactoryBot.create :research_modified_tasked,
                      study: @study,
                      name: 'no free-response for alternating sections',
                      code: <<~EOC
      unless tasked.task_step.exercise?
        manipulation.ignore!
        return
      end

      choose_even = 'A' == cohort.name

      if choose_even && tasked.task_step.page.book_location.last.even? ||
        !choose_even && tasked.task_step.page.book_location.last.odd?

        tasked.parser.questions_for_students.each do |q|
          q['formats'] -= ['free-response']
        end
        manipulation.record!
      else
        manipulation.ignore!
      end
    EOC

    @study.activate!

    expect do
      api_put "/api/steps/#{@task.task_steps.first.id}",
              @token,
              params: { answer_id: @task.task_steps.first.tasked.question_answer_ids[0][0] }.to_json
    end.to change { Research::Models::Manipulation.count }.by 1

    expect(response.body_as_hash[:errors]).to be_nil
  end

end
