require 'rails_helper'

RSpec.shared_examples 'a routine that creates practice tasks' do |result_proc|

  let(:student)       { FactoryGirl.create :course_membership_student }
  let(:course)        { student.course }
  let(:role)          { student.role }

  let(:page)          { FactoryGirl.create :content_page }

  let(:ecosystem)     { Content::Ecosystem.new strategy: page.ecosystem.wrap }

  (1..5).each do |n|
    let!("exercise_#{n}".to_sym) do
      FactoryGirl.create(:content_exercise, page: page).tap do |exercise|
        new_exercise_ids = page.practice_widget_pool.content_exercise_ids + [exercise.id]
        page.practice_widget_pool.update_attribute :content_exercise_ids, new_exercise_ids
      end
    end
  end

  let(:result)        { instance_exec &result_proc }
  let(:practice_task) { result.outputs.task }
  let(:errors)        { result.errors }

  before              { AddEcosystemToCourse[course: course, ecosystem: ecosystem] }

  it 'errors when the course has ended' do
    current_time = Time.current
    course.starts_at = current_time.last_month
    course.ends_at = current_time.yesterday
    course.save!

    expect(errors.first.code).to eq :course_ended
  end

  it 'clears incomplete steps from previous practice widgets' do
    expect(errors).to be_empty
    Preview::AnswerExercise[task_step: practice_task.task_steps.first, is_correct: false]
    result_2 = instance_exec &result_proc
    expect(result_2.errors).to be_empty
    practice_task_2 = result_2.outputs.task
    expect(practice_task_2).to be_persisted
    expect(practice_task.task_steps.reload.size).to eq 1
  end

  it 'creates tasks with 5 exercise steps and feedback immediately available' do
    expect(errors).to be_empty
    expect(practice_task).to be_persisted
    expect(practice_task.task_steps.size).to eq 5
    practice_task.task_steps.each{ |task_step| expect(task_step.exercise?).to eq true }
    expect(practice_task.feedback_available?).to be_truthy
  end

end
