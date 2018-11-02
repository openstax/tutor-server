require "rails_helper"

RSpec.describe 'Task steps without free response field', type: :request, api: true, version: :v1 do

  before(:all) do
    @course = FactoryBot.create :course_profile_course
    @course.ecosystem.books << FactoryBot.create(:content_book, :standard_contents_1 )
    period = FactoryBot.create :course_membership_period, course: @course
    user = FactoryBot.create(:user)
    user_role = AddUserAsPeriodStudent[user: user, period: period]
    @study = FactoryBot.create :research_study
    FactoryBot.create :research_cohort, name: 'A', study: @study

    Research::AddCourseToStudy[course: @course, study: @study]

    task_plan = FactoryBot.create :tasks_task_plan,
      owner: @course, ecosystem: @course.ecosystem,
      settings: { page_ids:  @course.ecosystem.books.last.pages.pluck(:id) }

    @task = FactoryBot.create :tasks_task, task_plan: task_plan,
                             step_types: [:tasks_tasked_exercise]
    FactoryBot.create :tasks_tasking, role: user_role, task: @task

    @token = FactoryBot.create :doorkeeper_access_token,
                       application: FactoryBot.create(:doorkeeper_application),
                       resource_owner_id: user.id
  end

  before(:each) {
    @study.deactivate!
  }

  it "can hide free-response formats when displaying a task" do
    @course.ecosystem.books.last.pages.pluck(:book_location).map{|bl|bl.join('.')}

    brain = FactoryBot.create :research_modified_task_for_display,
                              study: @study,
                              name: 'chapter 1-3 display no free-response',
                              code: <<~EOC

unless task.reading? || task.homework?
 manipulation.ignore!
 return {}
end

chapter_sections = Content::Models::Page.where(
  id: task.task_plan.settings['page_ids']
).pluck(:book_location).map{|cs|cs.join('.')}.uniq

manipulated_sections = %w{
  1.1 1.2 1.3 1.4 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 3.1 3.2 3.3 3.4 3.5
}.select.with_index{|_, i| 'A' == cohort.name ? i.even? : i.odd? }

task_step_ids = []

if (manipulated_sections & chapter_sections).any?
  task.task_steps.each do |ts|
    if ts.exercise?
      task_step_ids << ts.id
      ts.tasked.parser.questions_for_students.each{|q| q['formats'] -= ['free-response'] }
    end
  end
end

if task_step_ids.any?
  manipulation.context[:task_step_ids] = task_step_ids
  manipulation.record!
else
  manipulation.ignore!
end

EOC
    @study.activate!
    expect {
      api_get "/api/tasks/#{@task.id}", @token
    }.to change{ Research::Models::Manipulation.count }.by 1
    formats = response.body_as_hash[:steps].flat_map{|ts| ts.dig(:content, :questions, 0, :formats) }
    expect(formats).to_not include(:free_response)
    expect(brain.manipulations.last.target).to eq @task
  end

  it "can override requiring free-response when marking completed" do
    FactoryBot.create :research_modified_tasked_for_update,
                      study: @study,
                      name: 'chapter 1-3 save without free-response',
                      code: <<~EOC

task = tasked.task_step.task
unless task.reading? || task.homework?
 manipulation.ignore!
 return {}
end

chapter_sections = Content::Models::Page.where(
  id: task.task_plan.settings['page_ids']
).pluck(:book_location).map{|cs|cs.join('.')}.uniq

manipulated_sections = %w{
  1.1 1.2 1.3 1.4 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 3.1 3.2 3.3 3.4 3.5
}.select.with_index{|_, i| 'A' == cohort.name ? i.even? : i.odd? }

if (manipulated_sections & chapter_sections).any?
  tasked.parser.questions_for_students.each{|q|
    q['formats'] -= ['free-response']
  }
  manipulation.record!
else
  manipulation.ignore!
end

EOC
    @study.activate!

    expect {
      api_put "/api/steps/#{@task.task_steps.first.id}", @token,
              raw_post_data: { answer_id: @task.task_steps.first.tasked.question_answer_ids[0][0] }
    }.to change{ Research::Models::Manipulation.count }.by 1

    expect(response.body_as_hash[:errors]).to be_nil
  end

end
