require 'rails_helper'

RSpec.describe UpdateAssignedExerciseVersion, type: :routine do
  context 'given a number with an old version' do
    let(:ecosystem) { FactoryBot.create :content_ecosystem }
    let(:book)      { FactoryBot.create :content_book, ecosystem: ecosystem }
    let(:page)      { FactoryBot.create :content_page, book: book, ecosystem: ecosystem }
    let(:page2)     { FactoryBot.create :content_page, book: book, ecosystem: ecosystem }
    let(:course)    { FactoryBot.create :course_profile_course }
    let(:period)    { FactoryBot.create :course_membership_period, course: course }

    let!(:student_profile) do
      FactoryBot.create(:user_profile).tap do |user|
        AddUserAsPeriodStudent.call(user: user, period: period)
      end
    end
    let!(:teacher_profile) do
      FactoryBot.create(:user_profile).tap do |user|
        AddUserAsCourseTeacher.call(user: user, course: period)
      end
    end

    let!(:exercise_v1) do
      exercise = FactoryBot.build(
        :content_exercise, page: page, user_profile_id: teacher_profile.id, number: 1, version: 1, url: nil
      )
      exercise.save(validate: false)
      exercise
    end
    let!(:exercise_v2) do
      exercise = FactoryBot.build(
        :content_exercise, page: page, user_profile_id: teacher_profile.id, number: 1, version: 2, url: nil
      )
      exercise.save(validate: false)
      exercise
    end

    let(:homework_plan) do
      FactoryBot.build(
        :tasks_task_plan,
        assistant: FactoryBot.create(
          :tasks_assistant, code_class_name: 'Tasks::Assistants::HomeworkAssistant'
        ),
        course: course,
        type: 'homework',
        ecosystem: ecosystem,
        settings: {
          exercises: [{ id: exercise_v1.id.to_s, points: [1] }],
          page_ids: [exercise_v1.page.id.to_s],
          exercises_count_dynamic: 1
        }
      ).tap do |homework_plan|
        homework_plan.tasking_plans.first.target = period
        homework_plan.save!
        homework_plan.tasking_plans.each do |tp|
          tp.update_attribute(:opens_at_ntz, Time.current + 1.day)
        end
      end
    end
    let(:homework_tasking_plan) { homework_plan.tasking_plans.first }
    let(:exercise_ids) { [exercise_v1.id, exercise_v2.id] }
    let(:exercises)    { Content::Models::Exercise.where(id: exercise_ids) }

    before do
      AddEcosystemToCourse.call ecosystem: ecosystem, course: course
      DistributeTasks[task_plan: homework_plan]
    end

    it 'updates assignments that have not gone out to students with the new version' do
      result = described_class.call number: 1, profile: teacher_profile
      homework_plan.reload
      tasked = homework_plan.tasks.first.task_steps.first.tasked
      expect(result.outputs.updated_task_plan_ids).to eq([homework_plan.id])
      expect(homework_plan.settings['exercises'][0]['id']).to eq(exercise_v2.id.to_s)
      expect(tasked.content_exercise_id).to eq(exercise_v2.id)
    end

    it 'does not update assignments that have gone out to students' do
      homework_plan.tasking_plans.each do |tp|
        tp.update_attribute(:opens_at_ntz, Time.current - 1.day)
      end
      DistributeTasks[task_plan: homework_plan]

      result = described_class.call number: 1, profile: teacher_profile
      homework_plan.reload
      tasked = homework_plan.tasks.first.task_steps.first.tasked

      expect(result.outputs.updated_task_plan_ids).to eq([homework_plan.id])
      expect(homework_plan.settings['exercises'][0]['id']).to eq(exercise_v1.id.to_s)
      expect(tasked.content_exercise_id).to eq(exercise_v1.id)
    end

    it 'updates page ids if the new version changed pages' do
      exercise_v2.update_attribute(:content_page_id, page2.id)
      result = described_class.call number: 1, profile: teacher_profile
      expect(homework_plan.reload.settings['page_ids']).to include(page2.id.to_s)
    end
  end
end
