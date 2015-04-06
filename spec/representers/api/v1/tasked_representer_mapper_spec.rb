require 'rails_helper'

RSpec.describe Api::V1::TaskedRepresenterMapper do
  let(:mapper) { Api::V1::TaskedRepresenterMapper }

  describe '.models' do
    it 'returns all tasked models' do
      # Get all the Tasked.* classes
      expected_tasked_models = Set.new Dir[
        'app/subsystems/tasks/models/tasked*.rb'
      ].collect{ |f| f.remove('app/subsystems/tasks/models/')
                      .remove('.rb').classify }

      # Get all the models in the mapper
      registered_tasked_models = Set.new(mapper.models.collect { |model|
          model.name.demodulize
        }.sort
      )

      expect(registered_tasked_models).to eq(expected_tasked_models)
    end
  end

  describe '.representers' do
    it 'returns all tasked representers' do
      # Get all the Tasked.*Representer classes
      expected_tasked_representers = Set.new Dir[
        'app/representers/api/v1/tasked*_representer.rb'
      ].collect{ |f| f.remove('app/representers/api/v1/')
                      .remove('.rb').classify }

      # Get all the representers in the mapper
      registered_tasked_representers = Set.new(
        mapper.representers.collect { |repr|
          repr.name.demodulize
        }.sort
      )

      expect(registered_tasked_representers).to eq(expected_tasked_representers)
    end
  end

  describe '.representer_for' do
    it 'returns a tasked representer for a task step' do
      task_step = FactoryGirl.create :tasks_task_step

      expect(mapper.representer_for(task_step)).to(
        eq(Api::V1::TaskedReadingRepresenter)
      )
    end

    it 'returns a tasked representer for a tasked' do
      tasked_video = FactoryGirl.create :tasks_tasked_video

      expect(mapper.representer_for(tasked_video)).to(
        eq(Api::V1::TaskedVideoRepresenter)
      )
    end
  end
end
