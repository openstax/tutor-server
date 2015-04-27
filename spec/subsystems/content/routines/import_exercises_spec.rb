require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Routines::ImportExercises, :type => :routine,
                                                   :vcr => VCR_OPTS do

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
        result = Content::Routines::ImportExercises.call(tag: 'k12phys-ch04-s01-lo02')
      }.to change{ Content::Models::Exercise.count }.by(2)


      exercises = Content::Models::Exercise.all.order(:id).to_a
      exercises[-2..-1].each do |exercise|
        expect(exercise.exercise_tags.collect{|et| et.tag.value}).to(
          include 'k12phys-ch04-s01-lo02'
        )
      end
    end

    it 'can import all exercises with a set of tags' do
      result = nil
      tags = [ 'k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02' ]
      expect {
        result = Content::Routines::ImportExercises.call(tag: tags)
      }.to change{ Content::Models::Exercise.count }.by(3)

      exercises = Content::Models::Exercise.all.order(:id).to_a
      exercises[-3..-1].each do |exercise|
        expect(exercise.exercise_tags.collect{|et| et.tag.value} & tags).not_to(
          be_empty
        )
      end
    end

    it 'assigns all available tags to the imported exercises' do
      result = nil
      tags = [ 'k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02' ]
      expect {
        result = Content::Routines::ImportExercises.call(tag: tags)
      }.to change{ Content::Models::Tag.count }.by(2)

      tags = Content::Models::Tag.all.to_a
      tags[-2..-1].each do |tag|
        expect(tag).to be_lo
      end

      exercises = Content::Models::Exercise.all.to_a
      expect(exercises[-3].exercise_tags.collect{|et| et.tag.value})
        .to eq ['k12phys-ch04-s01-lo01']
      expect(exercises[-2].exercise_tags.collect{|et| et.tag.value})
        .to eq ['k12phys-ch04-s01-lo02']
      expect(exercises[-1].exercise_tags.collect{|et| et.tag.value})
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
        result = Content::Routines::ImportExercises.call(tag: 'k12phys-ch04-s01-lo02')
      }.to change{ Content::Models::Exercise.count }.by(15)

      exercises = Content::Models::Exercise.all.order(:id).to_a
      exercises[-15..-1].each do |exercise|
        expect(exercise.exercise_tags.collect{|et| et.tag.value}).to(
          include 'k12phys-ch04-s01-lo02'
        )
      end
    end

    it 'can import all exercises with a set of tags' do
      tags = ['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02']
      expect { Content::Routines::ImportExercises.call(tag: tags) }
        .to change{ Content::Models::Exercise.count }.by(31)

      exercises = Content::Models::Exercise.all.order(:id).to_a
      exercises[-31..-1].each do |exercise|
        expect(exercise.exercise_tags.collect{|et| et.tag.value} & tags).not_to(
          be_empty
        )
      end
    end

    it 'assigns all available tags to the imported exercises' do
      result = nil
      tags = ['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02']
      expect {
        result = Content::Routines::ImportExercises.call(tag: tags)
      }.to change{ Content::Models::Tag.count }.by(49)

      exercises = Content::Models::Exercise.all.to_a
      exercises[-31..-1].each do |exercise|
        wrapper = OpenStax::Exercises::V1::Exercise.new(exercise.content)

        exercise.exercise_tags.collect{|et| et.tag.value}.each do |tag|
          expect(wrapper.tags).to include tag
        end

        exercise.exercise_tags.joins(:tag).where(tag: {
          tag_type: Content::Models::Tag.tag_types[:lo]
        }).collect{|et| et.tag.value}.each do |lo|
          expect(wrapper.los).to include lo
        end
      end
    end
  end
end
