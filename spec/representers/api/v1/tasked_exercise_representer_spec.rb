require 'rails_helper'

RSpec.describe Api::V1::TaskedExerciseRepresenter, :type => :representer do

  let(:exercise_content) { OpenStax::Exercises::V1.fake_client.new_exercise_hash }
  let(:tasked_exercise) {
    FactoryGirl.create(:tasks_tasked_exercise, content: exercise_content.to_json)
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


  context "when complete" do
    before do
      tasked_exercise.free_response = 'Four score and seven years ago ...'
      tasked_exercise.answer_id = tasked_exercise.answer_ids.first
      tasked_exercise.save!
      tasked_exercise.task_step.complete
      tasked_exercise.task_step.save!
    end

    it "has additional fields" do
      expect(representation).to include(
        "id"                => tasked_exercise.id,
        "type"              => "exercise",
        "is_completed"      => true,
        "content_url"       => tasked_exercise.url,
        "correct_answer_id" =>tasked_exercise.correct_answer_id,
        "answer_id"         =>tasked_exercise.answer_ids.first,
        "free_response"     =>"Four score and seven years ago ...",
        "has_recovery"      => false,
        "is_correct"        => true
      )
    end

  end

end
