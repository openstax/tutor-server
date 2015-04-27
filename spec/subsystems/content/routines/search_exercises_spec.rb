require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Routines::SearchExercises, :type => :routine, :vcr => VCR_OPTS do

  let!(:book_part) { FactoryGirl.create :content_book_part }

  let!(:cnx_page_hash) { { 'id' => '092bbf0d-0729-42ce-87a6-fd96fd87a083@11',
                           'title' => 'Force' } }

  let!(:cnx_page) { OpenStax::Cnx::V1::Page.new(hash: cnx_page_hash) }

  it 'can search imported exercises' do
    Content::Routines::ImportPage.call(cnx_page: cnx_page, book_part: book_part)

    url = Content::Models::Exercise.first.url
    exercises = Content::Routines::SearchExercises.call(url: url).outputs.items
    expect(exercises.length).to eq 1
    expect(exercises.first.url).to eq url

    lo = 'k12phys-ch04-s01-lo01'
    exercises = Content::Routines::SearchExercises.call(tag: lo).outputs.items
    expect(exercises.length).to eq 16
    exercises.each do |exercise|
      tags = exercise.exercise_tags.collect{|et| et.tag.value}
      expect(tags).to include(lo)
      wrapper = OpenStax::Exercises::V1::Exercise.new(exercise.content)
      expect(wrapper.tags).to include(lo)
      expect(wrapper.los).to include(lo)
    end

    embed_tag = 'k12phys-ch04-ex021'
    exercises = Content::Routines::SearchExercises.call(tag: embed_tag).outputs
                                                                       .items
    expect(exercises.length).to eq 1
    expect(exercises.first.exercise_tags.collect{|et| et.tag.value}).to(
      include embed_tag
    )
  end

end
