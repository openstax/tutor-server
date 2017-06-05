require 'rails_helper'

RSpec.describe Api::V1::Tasks::TaskedExerciseRepresenter, type: :representer do
  let(:task_step) do
    instance_double(Tasks::Models::TaskStep).tap do |step|
      allow(step).to receive(:id).and_return(15)
      allow(step).to receive(:tasks_task_id).and_return(42)
      allow(step).to receive(:group_name).and_return('Some group')
      allow(step).to receive(:completed?).and_return(false)
      allow(step).to receive(:feedback_available?).and_return(false)
      allow(step).to receive(:can_be_recovered?).and_return(true)
      allow(step).to receive(:related_content).and_return([])
      allow(step).to receive(:labels).and_return([])
      allow(step).to receive(:spy).and_return({})
    end
  end

  let(:tasked_exercise) do
    instance_double(Tasks::Models::TaskedExercise).tap do |exercise|
      ## Avoid rspec double class when figuring out :type
      allow(exercise).to receive(:class).and_return(Tasks::Models::TaskedExercise)

      allow(exercise).to receive(:task_step).and_return(task_step)
      allow(exercise).to receive(:can_be_recovered?).and_return(false)

      ## TaskedExercise-specific properties
      allow(exercise).to receive(:url).and_return('Some url')
      allow(exercise).to receive(:title).and_return('Some title')
      allow(exercise).to receive(:context).and_return('Some context')
      allow(exercise).to receive(:content_hash_for_students).and_return('Some content')
      allow(exercise).to receive(:solution).and_return('Some solution')
      allow(exercise).to receive(:feedback).and_return('Some feedback')
      allow(exercise).to receive(:correct_answer_id).and_return('456')
      allow(exercise).to receive(:is_correct?).and_return(false)
      allow(exercise).to receive(:free_response).and_return(nil)
      allow(exercise).to receive(:answer_id).and_return(nil)
      allow(exercise).to receive(:last_completed_at).and_return(Time.current)
      allow(exercise).to receive(:first_completed_at).and_return(Time.current - 1.week)
      allow(exercise).to receive(:question_id).and_return("questionID")
      allow(exercise).to receive(:is_in_multipart).and_return(false)
    end
  end

  let(:representation) do ## NOTE: This is lazily-evaluated on purpose!
    Api::V1::Tasks::TaskedExerciseRepresenter.new(tasked_exercise).as_json
  end

  shared_examples "a good exercise representation should" do
    it "'type' == 'exercise'" do
      expect(representation).to include("type" => "exercise")
    end

    it "correctly references the TaskStep and Task ids" do
      expect(representation).to include(
        "id"      => 15.to_s,
        "task_id" => 42.to_s
      )
    end

    it "has the correct 'content_url'" do
      expect(representation).to include("content_url" => 'Some url')
    end

    it "has the correct 'title'" do
      expect(representation).to include("title" => 'Some title')
    end

    it "has the correct 'context'" do
      expect(representation).to include("context" => 'Some context')
    end

    it "has the correct 'content'" do
      expect(representation).to include("content" => 'Some content')
    end

    it "has the correct 'group'" do
      expect(representation).to include("group" => 'Some group')
    end

    it "has the correct 'has_recovery'" do
      expect(representation).to include("has_recovery" => false)
    end

    it "has 'related_content'" do
      allow(task_step).to receive(:related_content).and_return([])
      expect(representation).to include("related_content")
    end

    it "has 'labels'" do
      allow(task_step).to receive(:labels).and_return([])
      expect(representation).to include("labels")
    end

    it "has 'question_id'" do
      expect(representation).to include("question_id" => "questionID")
    end

    it "has 'is_in_multipart" do
      expect(representation).to include("is_in_multipart" => false)
    end

    it "has 'spy'" do
      expect(representation).to include("spy" => {})
    end

  end

  context "non-completed exercise" do

    before(:each) do
      allow(tasked_exercise).to receive(:free_response).and_return(nil)
      allow(tasked_exercise).to receive(:answer_id).and_return(nil)

      allow(task_step).to receive(:completed?).and_return(false)
      allow(task_step).to receive(:feedback_available?).and_return(false)
    end

    it_behaves_like "a good exercise representation should"

    it "'is_completed' == false" do
      expect(representation).to include("is_completed" => false)
    end

    it "'solution' is not included" do
      expect(representation).to_not include("solution")
    end

    it "'feedback_html' is not included" do
      expect(representation).to_not include("feedback_html")
    end

    it "'correct_answer_id' is not included" do
      expect(representation).to_not include("correct_answer_id")
    end

  end

  context "completed exercise" do

    before(:each) do
      allow(tasked_exercise).to receive(:free_response).and_return('Some response')
      allow(tasked_exercise).to receive(:answer_id).and_return('123')

      allow(task_step).to receive(:completed?).and_return(true)
    end

    it "'is_completed' == true" do
      expect(representation).to include("is_completed" => true)
    end

    context "feedback available" do

      before(:each) do
        allow(task_step).to receive(:feedback_available?).and_return(true)
      end

      it_behaves_like "a good exercise representation should"

      it "has correct 'has_recovery'" do
        expect(representation).to include("has_recovery" => false)
      end

      it "has correct 'solution'" do
        expect(representation).to include("solution" => 'Some solution')
      end

      it "has correct 'feedback_html'" do
        expect(representation).to include("feedback_html" => 'Some feedback')
      end

      it "has the correct 'is_correct'" do
        expect(representation).to include("is_correct" => false)
      end

      it "has the correct 'correct_answer_id'" do
        expect(representation).to include("correct_answer_id" => '456')
      end

    end

    context "feedback unavailable" do

      before(:each) do
        allow(task_step).to receive(:feedback_available?).and_return(false)
      end

      it_behaves_like "a good exercise representation should"

      it "'feedback_html' is not included" do
        expect(representation).to_not include("feedback_html")
      end

      it "'is_correct' is not included" do
        expect(representation).to_not include("is_correct")
      end

      it "'correct_answer_id' is not included" do
        expect(representation).to_not include("correct_answer_id")
      end

    end

  end

  context "without related content" do

    before(:each) do
      allow(task_step).to receive(:related_content).and_return([])
    end

    it_behaves_like "a good exercise representation should"

    it "has the correct 'related_content'" do
      expect(representation).to include("related_content" => [])
    end

  end

  context "with related content" do

    before(:each) do
      allow(task_step).to receive(:related_content).and_return([{title: "Some title",
                                                                 book_location: "4.2"}])
    end

    it_behaves_like "a good exercise representation should"

    it "has the correct 'related_content'" do
      expect(representation).to include(
        "related_content" => a_collection_including(
          a_hash_including({"title" => "Some title", "chapter_section" => "4.2"})
        )
      )
    end

  end
end
