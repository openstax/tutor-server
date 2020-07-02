require 'rails_helper'

RSpec.describe Ratings::UpdatePeriodBookParts, type: :routine do
  let(:period)                     { FactoryBot.create :course_membership_period }
  let!(:students)                  do
    3.times.map { FactoryBot.create :course_membership_student, period: period }
  end

  let(:course)                     { period.course }

  let(:ecosystem)                  { course.ecosystem }
  let(:page)                       { FactoryBot.create :content_page, ecosystem: ecosystem }

  let!(:period_book_part)          do
    FactoryBot.create :ratings_period_book_part,
                      period: period,
                      book_part_uuid: page.uuid,
                      glicko_mu: 0.0,
                      glicko_phi: 1.1513,
                      glicko_sigma: 0.06
  end

  let(:exercises)                  do
    3.times.map { FactoryBot.create :content_exercise, page: page }
  end
  let(:glicko_mus)                 { [ -0.5756, 0.2878, 1.1513 ] }
  let(:glicko_phis)                { [  0.1727, 0.5756, 1.7269 ] }
  let!(:exercise_group_book_parts) do
    exercises.each_with_index.map do |exercise, index|
      FactoryBot.create(
        :ratings_exercise_group_book_part,
        exercise_group_uuid: exercise.group_uuid,
        book_part_uuid: page.uuid,
        glicko_mu: glicko_mus[index],
        glicko_phi: glicko_phis[index]
      )
    end
  end

  let(:homework_assistant)        do
    FactoryBot.create :tasks_assistant, code_class_name: 'Tasks::Assistants::HomeworkAssistant'
  end
  let(:task_plans)                do
    3.times.map do |index|
      exercise = exercises[index]

      FactoryBot.create(
        :tasks_task_plan,
        type: 'homework',
        ecosystem: ecosystem,
        course: course,
        target: period,
        assistant: homework_assistant,
        settings: {
          exercises: [ { id: exercise.id.to_s, points: [ 1.0 ] * exercise.number_of_questions } ],
          exercises_count_dynamic: 0
        }
      ).tap { |task_plan| DistributeTasks.call task_plan: task_plan }
    end
  end
  let(:tasks)                     { task_plans.map { |task_plan| task_plan.tasks.sample } }
  let(:is_page)                   { true }

  let(:expected_sigma)            {  0.05999 }
  let(:expected_phi)              {  0.8742  }
  let(:expected_mu)               { -0.2084  }

  let(:responses)                 { [ true, false, false ] }

  it 'updates the period_book_part with the expected values' do
    tasks.each_with_index do |task, index|
      exercise_group_book_parts[index].update_attributes(
        glicko_mu: glicko_mus[index], glicko_phi: glicko_phis[index]
      )

      Preview::WorkTask.call task: task, is_correct: responses[index]
    end

    expect(period_book_part.reload.num_responses).to eq 3
    expect(period_book_part.glicko_sigma).to be_within(0.00001).of(expected_sigma)
    expect(period_book_part.glicko_phi).to be_within(0.0001).of(expected_phi)
    expect(period_book_part.glicko_mu).to be_within(0.0001).of(expected_mu)

    # UpdateRoleBookParts might skip or not the exercises depending on the feedback settings,
    # leading to some variation in the exercise ratings and CLUes
    expect(period_book_part.clue.deep_symbolize_keys).to match(
      minimum: 0.0,
      most_likely: be_within(0.02).of(0.40),
      maximum: 1.0,
      is_real: true
    )
  end

  it "requeues itself if run_at_due and the task's due_at changed" do
    task = tasks.first
    task.update_attribute :due_at, Time.current + 1.month

    expect do
      Delayed::Worker.with_delay_jobs(true) do
        described_class.call period: period, task: task, run_at_due: true
      end
    end.to change { Delayed::Job.count }.by(1)
  end
end
