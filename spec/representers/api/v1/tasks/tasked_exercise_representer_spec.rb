require 'rails_helper'

RSpec.describe Api::V1::Tasks::TaskedExerciseRepresenter, :type => :representer do

  let(:exercise_content) { OpenStax::Exercises::V1.fake_client.new_exercise_hash }
  let(:tasked_exercise) {
    FactoryGirl.create(:tasks_tasked_exercise, content: exercise_content.to_json)
  }
  let(:representation) { Api::V1::Tasks::TaskedExerciseRepresenter.new(tasked_exercise).as_json }

  it "represents a tasked exercise" do
    content = exercise_content.deep_stringify_keys
    content['questions'].each do |q|
      q['answers'].each do |a|
        a.delete('correctness')
        a.delete('feedback_html')
      end
    end

    expect(representation).to include(
      "id"           => tasked_exercise.task_step.id.to_s,
      "type"         => "exercise",
      "is_completed" => false,
      "content_url"  => tasked_exercise.url,
      "content"      => content
    )
  end


  context "when complete and" do

    let!(:answer_id)         { tasked_exercise.answer_ids.first }
    let!(:correct_answer_id) { tasked_exercise.correct_answer_id }

    before do
      tasked_exercise.free_response = 'Four score and seven years ago ...'
      tasked_exercise.answer_id = answer_id
      tasked_exercise.save!
      tasked_exercise.task_step.complete
      tasked_exercise.task_step.save!
    end

    context "feedback is available for the task" do

      before do
        tasked_exercise.task_step.task.feedback_at = Time.now
        tasked_exercise.task_step.task.save!
      end

      it "has additional fields" do
        expect(representation).to include(
          "id"                => tasked_exercise.task_step.id.to_s,
          "type"              => "exercise",
          "is_completed"      => true,
          "content_url"       => tasked_exercise.url,
          "correct_answer_id" => correct_answer_id.to_s,
          "answer_id"         => answer_id.to_s,
          "free_response"     => "Four score and seven years ago ...",
          "has_recovery"      => false,
          "is_correct"        => true
        )
      end

    end

    context "feedback is not available for the task" do

      it "has no additional fields" do
        expect(representation).to include(
          "id"                => tasked_exercise.task_step.id.to_s,
          "type"              => "exercise",
          "is_completed"      => true,
          "content_url"       => tasked_exercise.url,
          "answer_id"         => answer_id.to_s,
          "free_response"     => "Four score and seven years ago ..."
        )

        expect(representation).not_to include(
          "correct_answer_id" => correct_answer_id.to_s,
          "has_recovery"      => false,
          "is_correct"        => true
        )
      end

    end

  end

end
