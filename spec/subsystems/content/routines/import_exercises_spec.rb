require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Routines::ImportExercises, type: :routine, speed: :slow, vcr: VCR_OPTS do

  let!(:page)      { FactoryGirl.create(:content_page) }
  let!(:ecosystem) { page.book.ecosystem }

  it 'imports all exercises with a single tag' do
    result = nil
    expect {
      result = Content::Routines::ImportExercises.call(ecosystem: ecosystem, page: page,
                                                       query_hash: {tag: 'k12phys-ch04-s01-lo02'})
    }.to change{ Content::Models::Exercise.count }.by(16)

    exercises = ecosystem.exercises.order(:created_at).to_a
    exercises[-16..-1].each do |exercise|
      expect(exercise.exercise_tags.map{|et| et.tag.value}).to(
        include 'k12phys-ch04-s01-lo02'
      )
    end
  end

  it 'imports all exercises with a set of tags' do
    tags = ['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02']
    expect { Content::Routines::ImportExercises.call(ecosystem: ecosystem, page: page,
                                                     query_hash: {tag: tags}) }
      .to change{ Content::Models::Exercise.count }.by(33)

    exercises = ecosystem.exercises.order(:created_at).to_a
    exercises[-33..-1].each do |exercise|
      expect(exercise.exercise_tags.map{|et| et.tag.value} & tags).not_to(
        be_empty
      )
    end
  end

  it 'assigns all available tags to the imported exercises' do
    result = nil
    tags = ['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02']
    expect {
      result = Content::Routines::ImportExercises.call(ecosystem: ecosystem, page: page,
                                                       query_hash: {tag: tags})
    }.to change{ Content::Models::Tag.count }.by(59)

    exercises = ecosystem.exercises.order(:created_at).to_a
    exercises[-33..-1].each do |exercise|
      wrapper = OpenStax::Exercises::V1::Exercise.new(content: exercise.content)

      exercise.exercise_tags.map{|et| et.tag.value}.each do |tag|
        expect(wrapper.tags).to include tag
      end

      exercise.exercise_tags.joins(:tag).where(tag: {
        tag_type: Content::Models::Tag.tag_types[:lo]
      }).map{|et| et.tag.value}.each do |lo|
        expect(wrapper.los).to include lo
      end
    end
  end

  it 'does not import exercises whose numbers appear in excluded_exercise_numbers' do
    tags = ['k12phys-ch04-s01-lo01', 'k12phys-ch04-s01-lo02']
    excluded_exercise_numbers = Set[175, 250, 310]
    expect { Content::Routines::ImportExercises.call(
      ecosystem: ecosystem, page: page, query_hash: {tag: tags},
      excluded_exercise_numbers: excluded_exercise_numbers
    ) }.to change{ Content::Models::Exercise.count }.by(30)

    exercises = ecosystem.exercises.order(:created_at).to_a
    exercises[-30..-1].each do |exercise|
      expect(excluded_exercise_numbers).not_to include exercise.number
    end
  end

end
