require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Fragment::ExerciseChoice, type: :external, vcr: VCR_OPTS do
  let!(:cnx_page_id)    { 'd60a912c-83cf-443a-a6c2-3dd95545e7d4@1' }
  let!(:cnx_page)       {
    OpenStax::Cnx::V1.with_archive_url(url: 'https://archive.cnx.org/contents/') do
      OpenStax::Cnx::V1::Page.new(id: cnx_page_id)
    end
  }
  let!(:exercise_choice_fragments) {
    cnx_page.fragments.select do |f|
      f.is_a? OpenStax::Cnx::V1::Fragment::ExerciseChoice
    end
  }
  let!(:expected_titles)                    { [ 'Practice Problems' ] }
  let!(:expected_exercise_fragment_counts)  { [ 2 ] }

  it "provides info about the exercise fragment" do
    exercise_choice_fragments.each do |fragment|
      expect(fragment.node).not_to be_nil
      expect(fragment.title).not_to be_nil
      expect(fragment.exercise_fragments).not_to be_blank
      fragment.exercise_fragments.each do |ex|
        expect(ex).to be_a OpenStax::Cnx::V1::Fragment::Exercise
      end
    end
  end

  it "can retrieve the fragment's title" do
    expect(exercise_choice_fragments.collect{|f| f.title}).to eq expected_titles
  end

  it "can retrieve the fragment's subfragments" do
    expect(exercise_choice_fragments.collect{|f| f.exercise_fragments.count}).to(
      eq expected_exercise_fragment_counts
    )
  end
end
