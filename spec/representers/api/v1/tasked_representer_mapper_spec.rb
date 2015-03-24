require 'rails_helper'

RSpec.describe Api::V1::TaskedRepresenterMapper do
  let(:mapper) { Api::V1::TaskedRepresenterMapper }

  before :all do
    # Load all the source code
    Rails.application.eager_load!
  end

  describe '.models' do
    it 'returns all tasked models' do
      # Get all the Tasked.* classes
      expected_tasked_models = ActiveRecord::Base.descendants.collect { |cls|
        cls.name.to_sym if /^Tasked.+$/ =~ cls.to_s
      }.compact.sort

      # Get all the models in the mapper
      registered_tasked_models = mapper.models.collect { |model|
        model.name.demodulize.to_sym
      }.sort

      expect(registered_tasked_models).to eq(expected_tasked_models)
    end
  end

  describe '.representers' do
    it 'returns all tasked representers' do
      # Get all the Tasked.*Representer classes
      expected_tasked_representers = Api::V1.constants.collect { |constant|
        constant if /^Tasked.*Representer$/ =~ constant.to_s
      }.compact.sort

      # Get all the representers in the mapper
      registered_tasked_representers = mapper.representers.collect { |repr|
        repr.name.demodulize.to_sym
      }.sort

      expect(registered_tasked_representers).to eq(expected_tasked_representers)
    end
  end

  describe '.representer_for' do
    it 'returns a tasked representer for a task step' do
      task_step = FactoryGirl.create :task_step

      expect(mapper.representer_for(task_step)).to(
        eq(Api::V1::TaskedReadingRepresenter)
      )
    end

    it 'returns a tasked representer for a tasked' do
      tasked_video = FactoryGirl.create :tasked_video

      expect(mapper.representer_for(tasked_video)).to(
        eq(Api::V1::TaskedVideoRepresenter)
      )
    end
  end
end
