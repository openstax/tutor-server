require 'rails_helper'

RSpec.describe UpdateTaskPlanEcosystem, type: :routine do

  before(:all) do
    generate_homework_test_exercise_content
    @old_ecosystem = @ecosystem
    @old_pages = @pages
    generate_homework_test_exercise_content
  end

  context 'reading task plan' do
    let(:page_ids) { @old_pages[0..2].map(&:id) }

    let(:reading_plan) do
      FactoryBot.build(
        :tasks_task_plan,
        type: 'reading',
        ecosystem: @old_ecosystem.to_model,
        settings: { page_ids: page_ids }
      )
    end

    it 'can be updated to a newer ecosystem' do
      expect(reading_plan.ecosystem).to eq @old_ecosystem.to_model
      expect(reading_plan.settings['page_ids']).to eq page_ids
      expect(reading_plan).to be_valid
      updated_reading_plan = described_class[
        task_plan: reading_plan, ecosystem: @ecosystem.to_model
      ]
      expect(updated_reading_plan.ecosystem).to eq @ecosystem.to_model
      expect(updated_reading_plan.settings['page_ids'].length).to eq page_ids.length
      expect(updated_reading_plan.settings['page_ids']).not_to eq page_ids
      expect(updated_reading_plan).to be_valid

      new_page_ids = updated_reading_plan.settings['page_ids']
      expect(@ecosystem.pages_by_ids(*new_page_ids).length).to eq new_page_ids.length
    end
  end

  context 'homework task plan' do
    let(:core_pools) { @old_ecosystem.homework_core_pools(pages: @old_pages) }
    let(:exercises)  { core_pools.flat_map(&:exercises)[0..5] }

    let(:homework_plan) do
      FactoryBot.build(
        :tasks_task_plan,
        type: 'homework',
        ecosystem: @old_ecosystem.to_model,
        settings: {
          exercises: exercises.map do |exercise|
            { id: exercise.id.to_s, points: [ 1 ] * exercise.to_model.num_questions }
          end,
          exercises_count_dynamic: 3
        }
      )
    end

    it 'can be updated to a newer ecosystem' do
      expect(homework_plan.ecosystem).to eq @old_ecosystem.to_model
      expect(homework_plan.settings['exercises'].map { |ex| ex['id'] }).to eq(
        exercises.map(&:id).map(&:to_s)
      )
      expect(homework_plan).to be_valid
      updated_homework_plan = described_class[
        task_plan: homework_plan, ecosystem: @ecosystem.to_model
      ]
      expect(updated_homework_plan.ecosystem).to eq @ecosystem.to_model
      expect(updated_homework_plan.settings['exercises'].length).to eq exercises.length
      expect(updated_homework_plan.settings['exercises'].map { |ex| ex['id'] }).not_to(
        eq exercises.map(&:id).map(&:to_s)
      )
      expect(updated_homework_plan).to be_valid

      new_exercise_ids = updated_homework_plan.settings['exercises'].map { |ex| ex['id'] }
      expect(@ecosystem.exercises_by_ids(*new_exercise_ids).length).to eq new_exercise_ids.length
    end
  end

  context 'extra task plan' do
    let(:page_ids)     { @old_pages[0..2].map(&:id) }
    let(:snap_lab_ids) { page_ids.map{ |page_id| "#{page_id}:fs-id#{SecureRandom.hex}" } }

    let(:extra_plan) do
      FactoryBot.build(
        :tasks_task_plan,
        type: 'extra',
        ecosystem: @old_ecosystem.to_model,
        settings: { snap_lab_ids: snap_lab_ids }
      )
    end

    it 'can be updated to a newer ecosystem' do
      expect(extra_plan.ecosystem).to eq @old_ecosystem.to_model
      expect(extra_plan.settings['snap_lab_ids']).to eq snap_lab_ids
      expect(extra_plan).to be_valid
      updated_extra_plan = described_class[
        task_plan: extra_plan, ecosystem: @ecosystem.to_model
      ]
      expect(updated_extra_plan.ecosystem).to eq @ecosystem.to_model
      expect(updated_extra_plan.settings['snap_lab_ids'].length).to eq snap_lab_ids.length
      expect(updated_extra_plan.settings['snap_lab_ids']).not_to eq snap_lab_ids
      expect(updated_extra_plan).to be_valid

      new_snap_lab_ids = updated_extra_plan.settings['snap_lab_ids']
      new_page_ids = new_snap_lab_ids.map do |page_id_snap_lab_id|
        page_id_snap_lab_id.split(':').first
      end
      expect(@ecosystem.pages_by_ids(*new_page_ids).length).to eq new_snap_lab_ids.length
    end
  end

  context 'external task plan' do
    let(:external_plan) do
      FactoryBot.build(
        :tasks_task_plan,
        type: 'external',
        ecosystem: @old_ecosystem.to_model
      )
    end

    it 'can be updated to a newer ecosystem' do
      expect(external_plan.ecosystem).to eq @old_ecosystem.to_model
      expect(external_plan).to be_valid
      updated_external_plan = described_class[
        task_plan: external_plan, ecosystem: @ecosystem.to_model
      ]
      expect(updated_external_plan.ecosystem).to eq @ecosystem.to_model
      expect(updated_external_plan).to be_valid
    end
  end
end
