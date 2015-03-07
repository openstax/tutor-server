require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::ImportExercises, :type => :routine, :vcr => VCR_OPTS do

  context 'fake client' do
    before(:all) do
      OpenStax::Exercises::V1.use_fake_client

      OpenStax::Exercises::V1.fake_client.reset!

      OpenStax::Exercises::V1.fake_client.add_exercise(
        tags: ['k12phys-ch04-s01-lo01']
      )
      OpenStax::Exercises::V1.fake_client.add_exercise(
        tags: ['k12phys-ch04-s01-lo02']
      )
      OpenStax::Exercises::V1.fake_client.add_exercise(
        tags: ['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02']
      )
    end

    after(:all) do
      OpenStax::Exercises::V1.fake_client.reset!
    end

    it 'can import all exercises with a single tag' do
      result = nil
      expect {
        result = Content::ImportExercises.call(tag: 'k12phys-ch04-s01-lo02')
      }.to change{ Content::Exercise.count }.by(2)

      exercises = Content::Exercise.all.to_a
      expect(exercises[-2].exercise_topics.collect{|et| et.topic.name})
        .to eq ['k12phys-ch04-s01-lo02']
      expect(exercises[-1].exercise_topics.collect{|et| et.topic.name})
        .to eq ['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02']
    end

    it 'can import all exercises with a set of tags' do
      result = nil
      expect {
        result = Content::ImportExercises.call(tag: [
          'k12phys-ch04-s01-lo01',
          'k12phys-ch04-s01-lo02'
        ])
      }.to change{ Content::Exercise.count }.by(3)

      exercises = Content::Exercise.all.to_a
      expect(exercises[-3].exercise_topics.collect{|et| et.topic.name})
        .to eq ['k12phys-ch04-s01-lo01']
      expect(exercises[-2].exercise_topics.collect{|et| et.topic.name})
        .to eq ['k12phys-ch04-s01-lo02']
      expect(exercises[-1].exercise_topics.collect{|et| et.topic.name})
        .to eq ['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02']
    end
  end

  context 'real client' do
    before(:all) do
      OpenStax::Exercises::V1.configure do |config|
        config.server_url = 'http://exercises-dev1.openstax.org'
      end

      OpenStax::Exercises::V1.use_real_client
    end

    it 'can import all exercises with a single tag' do
      result = nil
      expect {
        result = Content::ImportExercises.call(tag: 'k12phys-ch04-s01-lo02')
      }.to change{ Content::Exercise.count }.by(15)

      exercises = Content::Exercise.all.to_a
      exercises[-15..-1].each do |exercise|
        expect(exercise.exercise_topics.collect{|et| et.topic.name})
        .to include 'k12phys-ch04-s01-lo02'
      end
    end

    it 'can import all exercises with a set of tags' do
      tags = ['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02']
      expect { Content::ImportExercises.call(tag: tags) }
        .to change{ Content::Exercise.count }.by(32)

      exercises = Content::Exercise.all.to_a
      exercises[-32..-1].each do |exercise|
        exercise.exercise_topics.each do |et|
          expect(tags).to include et.topic.name
        end
      end
    end
  end
end
