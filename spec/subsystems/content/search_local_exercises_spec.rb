require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::SearchLocalExercises, :type => :routine,
                                              :vcr => VCR_OPTS do

  let!(:book_part) { FactoryGirl.create :content_book_part }

  let!(:cnx_page_hash) { { 'id' => '092bbf0d-0729-42ce-87a6-fd96fd87a083@11',
                           'title' => 'Force' } }

  let!(:cnx_page) { OpenStax::Cnx::V1::Page.new(hash: cnx_page_hash) }

  it 'can search imported exercises' do
    Content::Routines::ImportPage.call(cnx_page: cnx_page,
                                       book_part: book_part)

    url = Content::Models::Exercise.first.url
    exercises = Content::SearchLocalExercises.call(url: url).outputs.items
    expect(exercises.length).to eq 1
    expect(exercises.first.url).to eq url

    lo = 'k12phys-ch04-s01-lo01'
    exercises = Content::SearchLocalExercises.call(tag: lo).outputs.items
    expect(exercises.length).to eq 16
    exercises.each do |exercise|
      expect(exercise.tags).to include(lo)
      expect(exercise.los).to include(lo)
    end

    embed_tag = 'k12phys-ch04-ex021'
    exercises = Content::SearchLocalExercises.call(tag: embed_tag).outputs
                                                                  .items
    expect(exercises.length).to eq 1
    expect(exercises.first.tags).to include embed_tag
    expect(exercises.first.los).not_to include embed_tag
  end

end
