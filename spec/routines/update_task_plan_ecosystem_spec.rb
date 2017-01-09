require 'rails_helper'

RSpec.describe UpdateTaskPlanEcosystem, type: :routine do

  before(:all) do
    generate_test_exercise_content
    @old_ecosystem = @ecosystem
    @old_pages = @pages
    generate_test_exercise_content
  end

  context 'reading task plan' do
    let(:page_ids) { @old_pages[0..2].map(&:id) }

    let(:reading_plan) do
      FactoryGirl.build(
        :tasks_task_plan,
        type: 'reading',
        ecosystem: @old_ecosystem.to_model,
        settings: { page_ids: page_ids }
      )
    end

    it 'can be updated to a newer ecosystem' do
      expect(reading_plan.ecosystem).to eq @old_ecosystem.to_model
      expect(reading_plan).to be_valid
      updated_reading_plan = described_class[
        task_plan: reading_plan, ecosystem: @ecosystem.to_model
      ]
      expect(updated_reading_plan.ecosystem).to eq @ecosystem.to_model
      expect(updated_reading_plan).to be_valid
    end
  end

  context 'homework task plan' do
    let(:core_pools)    { @old_ecosystem.homework_core_pools(pages: @old_pages) }
    let(:exercise_ids)  { core_pools.flat_map(&:exercises)[0..5].map{|e| e.id.to_s} }

    let(:homework_plan) do
      FactoryGirl.build(
        :tasks_task_plan,
        type: 'homework',
        ecosystem: @old_ecosystem.to_model,
        settings: { exercise_ids: exercise_ids, exercises_count_dynamic: 3 }
      )
    end

    it 'can be updated to a newer ecosystem' do
      expect(homework_plan.ecosystem).to eq @old_ecosystem.to_model
      expect(homework_plan).to be_valid
      updated_homework_plan = described_class[
        task_plan: homework_plan, ecosystem: @ecosystem.to_model
      ]
      expect(updated_homework_plan.ecosystem).to eq @ecosystem.to_model
      expect(updated_homework_plan).to be_valid
    end
  end

  context 'external task plan' do
    let(:external_plan) do
      FactoryGirl.build(
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
