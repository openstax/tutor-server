require 'rails_helper'

RSpec.describe Api::V1::TaskedExerciseRepresenter, :type => :representer do

  let(:exercise_content) { OpenStax::Exercises::V1.fake_client.new_exercise_hash }
  let(:tasked_exercise) {
    FactoryGirl.create(:tasked_exercise, content: exercise_content.to_json)
  }
  let(:representation) { Api::V1::TaskedExerciseRepresenter.new(tasked_exercise).as_json }

  it "represents a tasked exercise" do
    content = exercise_content.deep_stringify_keys
    content['questions'].each do |q|
      q['answers'].each do |a|
        a.delete('correctness')
        a.delete('feedback_html')
      end
    end

    expect(representation).to include(
      "id"           => tasked_exercise.id,
      "type"         => "exercise",
      "is_completed" => false,
      "content_url"  => tasked_exercise.url,
      "content"      => content
    )
  end

end
