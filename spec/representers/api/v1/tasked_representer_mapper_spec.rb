require 'rails_helper'

RSpec.describe Api::V1::TaskedRepresenterMapper, type: :routine do
  context '.models' do
    it 'returns all tasked models' do
      # Get all the Tasked.* classes
      expected_tasked_models = Set.new Dir[
        'app/subsystems/tasks/models/tasked*.rb'
      ].map{ |f| f.remove('app/subsystems/tasks/models/').remove('.rb').classify }

      # Get all the models in the mapper
      registered_tasked_models = Set.new(
        described_class::REPRESENTER_MAP.keys.map(&:demodulize).sort
      )

      expect(registered_tasked_models).to eq(expected_tasked_models)
    end
  end

  context '.representers' do
    it 'returns all tasked representers' do
      # Get all the Tasked.*Representer classes
      expected_tasked_representers = Set.new Dir[
        'app/representers/api/v1/tasks/tasked*_representer.rb'
      ].map{ |f| f.remove('app/representers/api/v1/tasks/')
                  .remove('.rb').classify }

      # Get all the representers in the mapper
      registered_tasked_representers = Set.new(
        described_class::REPRESENTER_MAP.values.map(&:demodulize).sort
      )

      expect(registered_tasked_representers).to eq(expected_tasked_representers)
    end
  end

  context '.representer_for' do
    it 'returns a tasked representer for a task step' do
      task_step = FactoryBot.create :tasks_task_step

      expect(described_class.representer_for(task_step)).to(
        eq(Api::V1::Tasks::TaskedReadingRepresenter)
      )
    end

    it 'returns a tasked representer for a tasked' do
      tasked_video = FactoryBot.create :tasks_tasked_video

      expect(described_class.representer_for(tasked_video)).to(
        eq(Api::V1::Tasks::TaskedVideoRepresenter)
      )
    end
  end
end
