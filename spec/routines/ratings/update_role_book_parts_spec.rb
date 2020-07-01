require 'rails_helper'

RSpec.describe Ratings::UpdateRoleBookParts, type: :routine do
  let(:student)                    { FactoryBot.create :course_membership_student }
  let(:role)                       { student.role }

  let(:period)                     { student.period }
  let(:course)                     { period.course }

  let(:ecosystem)                  { course.ecosystem }
  let(:page)                       { FactoryBot.create :content_page, ecosystem: ecosystem }

  let!(:role_book_part)            do
    FactoryBot.create :ratings_role_book_part,
                      role: role,
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

  let(:task_plan)                 do
    FactoryBot.create(
      :tasks_task_plan,
      type: 'homework',
      ecosystem: ecosystem,
      course: course,
      target: period,
      assistant: FactoryBot.create(
        :tasks_assistant, code_class_name: 'Tasks::Assistants::HomeworkAssistant'
      ),
      settings: {
        exercises: exercises.map do |exercise|
          { id: exercise.id.to_s, points: [ 1.0 ] * exercise.number_of_questions }
        end,
        exercises_count_dynamic: 0
      }
    ).tap { |task_plan| DistributeTasks.call task_plan: task_plan }
  end
  let(:task)                      { task_plan.tasks.first }
  let(:is_page)                   { true }

  let(:expected_sigma)            {  0.05999 }
  let(:expected_phi)              {  0.8722  }
  let(:expected_mu)               { -0.2069  }

  let(:responses)                 { [ true, false, false ] }

  context 'feedback available' do
    before { task_plan.grading_template.update_column :auto_grading_feedback_on, :answer }

    it 'updates the role_book_part with the expected values' do
      expect do
        Preview::WorkTask.call task: task, is_correct: ->(_, index) { responses[index] }
      end.to  change { role_book_part.reload.num_responses }.from(0).to(3)
         .and change { exercise_group_book_parts.first.reload.num_responses }.from(0).to(1)
         .and change { exercise_group_book_parts.second.reload.num_responses }.from(0).to(1)
         .and change { exercise_group_book_parts.third.reload.num_responses }.from(0).to(1)
         .and change { exercise_group_book_parts.first.glicko_sigma }
         .and change { exercise_group_book_parts.second.glicko_sigma }
         .and change { exercise_group_book_parts.third.glicko_sigma }
         .and change { exercise_group_book_parts.first.glicko_phi }
         .and change { exercise_group_book_parts.second.glicko_phi }
         .and change { exercise_group_book_parts.third.glicko_phi }
         .and change { exercise_group_book_parts.first.glicko_mu }
         .and change { exercise_group_book_parts.second.glicko_mu }
         .and change { exercise_group_book_parts.third.glicko_mu }

      expect(role_book_part.glicko_sigma).to be_within(0.00001).of(expected_sigma)
      expect(role_book_part.glicko_phi).to be_within(0.0001).of(expected_phi)
      expect(role_book_part.glicko_mu).to be_within(0.0001).of(expected_mu)
      expect(role_book_part.clue.deep_symbolize_keys).to match(
        minimum: 0.0,
        most_likely: be_within(1e-6).of(0.380825),
        maximum: 1.0,
        is_real: true
      )
    end
  end

  context 'feedback not available' do
    before { task_plan.grading_template.update_column :auto_grading_feedback_on, :publish }

    it 'does nothing' do
      expect do
        Preview::WorkTask.call task: task, is_correct: ->(_, index) { responses[index] }
      end.to  not_change { role_book_part.reload.num_responses }
         .and not_change { exercise_group_book_parts.first.reload.num_responses }
         .and not_change { exercise_group_book_parts.second.reload.num_responses }
         .and not_change { exercise_group_book_parts.third.reload.num_responses }
         .and not_change { exercise_group_book_parts.first.glicko_sigma }
         .and not_change { exercise_group_book_parts.second.glicko_sigma }
         .and not_change { exercise_group_book_parts.third.glicko_sigma }
         .and not_change { exercise_group_book_parts.first.glicko_phi }
         .and not_change { exercise_group_book_parts.second.glicko_phi }
         .and not_change { exercise_group_book_parts.third.glicko_phi }
         .and not_change { exercise_group_book_parts.first.glicko_mu }
         .and not_change { exercise_group_book_parts.second.glicko_mu }
         .and not_change { exercise_group_book_parts.third.glicko_mu }
    end
  end
end
