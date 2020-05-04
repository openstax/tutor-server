require 'rails_helper'

RSpec.describe UpdateTaskPlanEcosystem, type: :routine do
  before(:all) do
    generate_homework_test_exercise_content
    @old_ecosystem = @ecosystem
    @old_pages = @pages

    generate_homework_test_exercise_content

    @old_course = FactoryBot.create :course_profile_course
    AddEcosystemToCourse.call ecosystem: @old_ecosystem, course: @old_course

    @course = FactoryBot.create :course_profile_course
    AddEcosystemToCourse.call ecosystem: @ecosystem, course: @course
  end

  before do
    @old_ecosystem.reload
    @old_pages.reload

    @ecosystem.reload
    @pages.reload

    @old_course.reload
    @course.reload
  end

  context 'reading task plan' do
    let(:page_ids) { @old_pages[0..2].map(&:id) }

    let(:original_reading_plan) do
      FactoryBot.create(
        :tasks_task_plan,
        type: 'reading',
        ecosystem: @old_ecosystem,
        course: @old_course,
        settings: { page_ids: page_ids }
      )
    end

    it 'can be updated to a newer ecosystem' do
      expect(original_reading_plan).to be_valid

      cloned_reading_plan = FactoryBot.build(
        :tasks_task_plan,
        type: 'reading',
        ecosystem: @old_ecosystem,
        course: @course,
        settings: { page_ids: page_ids }
      )
      cloned_reading_plan.course.course_ecosystems.where(ecosystem: @old_ecosystem).delete_all
      cloned_reading_plan.course.course_ecosystems.reload
      expect(cloned_reading_plan).not_to be_valid

      updated_reading_plan = described_class[task_plan: cloned_reading_plan, ecosystem: @ecosystem]
      expect(updated_reading_plan.ecosystem).to eq @ecosystem
      expect(updated_reading_plan.settings['page_ids'].length).to eq page_ids.length
      expect(updated_reading_plan.settings['page_ids']).not_to eq page_ids
      expect(updated_reading_plan).to be_valid

      new_page_ids = updated_reading_plan.settings['page_ids']
      expect(@ecosystem.pages.where(id: new_page_ids).count).to eq new_page_ids.length
    end
  end

  context 'homework task plan' do
    let(:exercise_ids)  { @old_pages.flat_map(&:homework_core_exercise_ids)[0..5].map(&:to_s) }

    let(:original_homework_plan) do
      FactoryBot.create(
        :tasks_task_plan,
        type: 'homework',
        ecosystem: @old_ecosystem,
        course: @old_course,
        settings: { exercise_ids: exercise_ids, exercises_count_dynamic: 3 }
      )
    end

    it 'can be updated to a newer ecosystem' do
      expect(original_homework_plan).to be_valid

      cloned_homework_plan = FactoryBot.build(
        :tasks_task_plan,
        type: 'homework',
        ecosystem: @old_ecosystem,
        course: @course,
        settings: { exercise_ids: exercise_ids, exercises_count_dynamic: 3 }
      )
      cloned_homework_plan.course.course_ecosystems.where(ecosystem: @old_ecosystem).delete_all
      cloned_homework_plan.course.course_ecosystems.reload
      expect(cloned_homework_plan).not_to be_valid

      updated_homework_plan = described_class[
        task_plan: cloned_homework_plan, ecosystem: @ecosystem
      ]
      expect(updated_homework_plan.ecosystem).to eq @ecosystem
      expect(updated_homework_plan.settings['exercise_ids'].length).to eq exercise_ids.length
      expect(updated_homework_plan.settings['exercise_ids']).not_to eq exercise_ids
      expect(updated_homework_plan).to be_valid

      new_exercise_ids = updated_homework_plan.settings['exercise_ids']
      expect(@ecosystem.exercises.where(id: new_exercise_ids).count).to eq new_exercise_ids.length
    end
  end

  context 'extra task plan' do
    let(:page_ids)     { @old_pages[0..2].map(&:id) }
    let(:snap_lab_ids) { page_ids.map{ |page_id| "#{page_id}:fs-id#{SecureRandom.hex}" } }

    let(:original_extra_plan) do
      FactoryBot.create(
        :tasks_task_plan,
        type: 'extra',
        ecosystem: @old_ecosystem,
        course: @old_course,
        settings: { snap_lab_ids: snap_lab_ids }
      )
    end

    it 'can be updated to a newer ecosystem' do
      expect(original_extra_plan).to be_valid

      cloned_extra_plan = FactoryBot.build(
        :tasks_task_plan,
        type: 'extra',
        ecosystem: @old_ecosystem,
        course: @course,
        settings: { snap_lab_ids: snap_lab_ids }
      )
      cloned_extra_plan.course.course_ecosystems.where(ecosystem: @old_ecosystem).delete_all
      cloned_extra_plan.course.course_ecosystems.reload
      expect(cloned_extra_plan).not_to be_valid

      updated_extra_plan = described_class[task_plan: cloned_extra_plan, ecosystem: @ecosystem]
      expect(updated_extra_plan.ecosystem).to eq @ecosystem
      expect(updated_extra_plan.settings['snap_lab_ids'].length).to eq snap_lab_ids.length
      expect(updated_extra_plan.settings['snap_lab_ids']).not_to eq snap_lab_ids
      expect(updated_extra_plan).to be_valid

      new_snap_lab_ids = updated_extra_plan.settings['snap_lab_ids']
      new_page_ids = new_snap_lab_ids.map do |page_id_snap_lab_id|
        page_id_snap_lab_id.split(':').first
      end
      expect(@ecosystem.pages.where(id: new_page_ids).count).to eq new_snap_lab_ids.length
    end
  end

  context 'external task plan' do
    let(:original_external_plan) do
      FactoryBot.create(
        :tasks_task_plan,
        type: 'external',
        ecosystem: @old_ecosystem,
        course: @old_course
      )
    end

    it 'can be updated to a newer ecosystem' do
      expect(original_external_plan).to be_valid

      cloned_external_plan = FactoryBot.build(
        :tasks_task_plan,
        type: 'external',
        ecosystem: @old_ecosystem,
        course: @course
      )
      cloned_external_plan.course.course_ecosystems.where(ecosystem: @old_ecosystem).delete_all
      cloned_external_plan.course.course_ecosystems.reload
      expect(cloned_external_plan).not_to be_valid

      updated_external_plan = described_class[
        task_plan: cloned_external_plan, ecosystem: @ecosystem
      ]
      expect(updated_external_plan.ecosystem).to eq @ecosystem
      expect(updated_external_plan).to be_valid
    end
  end
end
