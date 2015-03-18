require 'rails_helper'

describe CalculateIReadingStats do

  #
  let(:cnx_page_hash) { {'id' => '092bbf0d-0729-42ce-87a6-fd96fd87a083', 'title' => 'Force'} }

  let!(:assistant) { FactoryGirl.create :assistant,
                                        code_class_name: 'IReadingAssistant' }
  let!(:book_part) { FactoryGirl.create :content_book_part }

  let(:course)      { Domain::CreateCourse.call.outputs.course }

  let!(:cnx_page) { OpenStax::Cnx::V1::Page.new(hash: cnx_page_hash) }
  let!(:page)     { Content::ImportPage.call(cnx_page: cnx_page, book_part: book_part).outputs.page }

  let(:task_plan) { FactoryGirl.create :task_plan, owner: course,
                                        settings: { page_ids: [page.id] } }

  let(:taskees) { 3.times.collect{ FactoryGirl.create :user } }

  it "is all zero for an unworked task_plan" do
    IReadingAssistant.distribute_tasks(task_plan: task_plan, taskees: taskees)

    stats = CalculateIReadingStats.call(plan: task_plan).outputs.stats

    expect(stats.course.total_count).to eq(3)
    expect(stats.course.complete_count).to eq(0)
    expect(stats.course.partially_complete_count).to eq(0)

    page = stats.course.current_pages[0]
    expect(page.student_count).to eq(3)
    expect(page.incorrect_count).to eq(0)
    expect(page.correct_count).to eq(0)
  end

  it "records partial/complete status" do
    IReadingAssistant.distribute_tasks(task_plan: task_plan, taskees: taskees)
    first_task = task_plan.tasks.first
    step = first_task.task_steps.where(tasked_type:"TaskedReading").first
    MarkTaskStepCompleted.call(task_step: step)

    stats = CalculateIReadingStats.call(plan: task_plan).outputs.stats
    expect(stats.course.complete_count).to eq(0)
    expect(stats.course.partially_complete_count).to eq(1)

    first_task.task_steps.each{ |ts| MarkTaskStepCompleted.call(task_step: ts) }
    stats = CalculateIReadingStats.call(plan: task_plan.reload).outputs.stats

    expect(stats.course.complete_count).to eq(1)
    expect(stats.course.partially_complete_count).to eq(1)

    last_plan=task_plan.tasks.last
    MarkTaskStepCompleted.call(task_step: last_plan.task_steps.first)
    stats = CalculateIReadingStats.call(plan: task_plan.reload).outputs.stats
    expect(stats.course.complete_count).to eq(1)
    expect(stats.course.partially_complete_count).to eq(2)
  end


end
