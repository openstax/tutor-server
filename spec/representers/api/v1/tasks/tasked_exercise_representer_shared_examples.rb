require 'rails_helper'

RSpec.shared_examples 'a tasked_exercise representer' do
  let(:task_step) do
    instance_double(Tasks::Models::TaskStep).tap do |step|
      allow(step).to receive(:id).and_return(15)
      allow(step).to receive(:group_name).and_return('Some group')
      allow(step).to receive(:is_core).and_return(true)
      allow(step).to receive(:completed?).and_return(false)
      allow(step).to receive(:can_be_updated?).and_return(true)
      allow(step).to receive(:labels).and_return([])
      allow(step).to receive(:related_content).and_return('RelatedContent')
      allow(step).to receive(:spy_with_response_validation).and_return(
        response_validation: { valid: false }
      )
    end
  end

  let(:tasked_exercise) do
    instance_double(Tasks::Models::TaskedExercise).tap do |exercise|
      ## Avoid rspec double class when figuring out :type
      allow(exercise).to receive(:class).and_return(Tasks::Models::TaskedExercise)
      allow(exercise).to receive(:task_step).and_return(task_step)

      ## TaskedExercise-specific properties
      allow(exercise).to receive(:id).and_return(1)
      allow(exercise).to receive(:content_exercise_id).and_return(1)
      allow(exercise).to receive(:exercise_uuid).and_return('Some uuid')
      allow(exercise).to receive(:title).and_return('Some title')
      allow(exercise).to receive(:context).and_return('Some Context')
      allow(exercise).to receive(:attempt_number).and_return(1)
      allow(exercise).to receive(:content_hash_for_students).and_return('Some content')
      allow(exercise).to receive(:question_formats_for_students).and_return('Some question formats')
      allow(exercise).to receive(:content_preview).and_return('Some content preview')
      allow(exercise).to receive(:uid).and_return('123@1')
      allow(exercise).to receive(:solution).and_return('Some solution')
      allow(exercise).to receive(:feedback).and_return('Some feedback')
      allow(exercise).to receive(:correct_answer_id).and_return('456')
      allow(exercise).to receive(:correct_answer_feedback).and_return('More feedback')
      allow(exercise).to receive(:free_response).and_return(nil)
      allow(exercise).to receive(:answer_id).and_return(nil)
      allow(exercise).to receive(:answer_id_order).and_return(['1', '2'])
      allow(exercise).to receive(:last_completed_at).and_return(Time.current)
      allow(exercise).to receive(:first_completed_at).and_return(Time.current - 1.week)
      allow(exercise).to receive(:feedback_available?).and_return(false)
      allow(exercise).to receive(:solution_available?).and_return(false)
      allow(exercise).to receive(:was_manually_graded?).and_return(false)
      allow(exercise).to receive(:attempts_remaining).and_return(1)
      allow(exercise).to receive(:question_id).and_return('questionID')
      allow(exercise).to receive(:is_in_multipart).and_return(false)
      allow(exercise).to receive(:response_validation).and_return({ valid: false })
      allow(exercise).to receive(:available_points).and_return(1.0)
      allow(exercise).to receive(:published_points_without_lateness).and_return(0.75)
      allow(exercise).to receive(:published_late_work_point_penalty).and_return(0.25)
      allow(exercise).to receive(:published_points).and_return(0.5)
      allow(exercise).to receive(:published_comments).and_return('Hi')
      allow(exercise).to receive(:drop_method).and_return(nil)
      allow(exercise).to receive(:cache_key).and_return('tasks/models/tasked_exercises/42')
      allow(exercise).to receive(:cache_version).and_return('test')
    end
  end

  let(:representation) do ## NOTE: This is lazily-evaluated on purpose!
    described_class.new(tasked_exercise).as_json
  end

  let(:complete_representation) do ## NOTE: This is lazily-evaluated on purpose!
    described_class.new(tasked_exercise).to_hash user_options: { include_content: true }
  end

  shared_examples 'a good exercise representation should' do
    it "'type' == 'exercise'" do
      expect(representation).to include('type' => 'exercise')
    end

    it 'correctly references the TaskStep and Task ids' do
      expect(representation).to include('id' => 15)
    end

    it "has the correct 'title'" do
      expect(representation).to include('title' => 'Some title')
    end

    it "has 'available_points'" do
      expect(representation).to include('available_points' => 1.0)
    end

    it "has the correct 'context'" do
      expect(complete_representation).to include('context' => 'Some Context')
    end

    it "has the correct 'content_preview'" do
      expect(representation).to include('preview' => 'Some content preview')
    end

    it "has the correct 'content'" do
      expect(complete_representation).to include('content' => 'Some content')
    end

    it "has the correct 'group'" do
      expect(representation).to include('group' => 'Some group')
    end

    it "has the correct 'is_core'" do
      expect(representation).to include('is_core' => true)
    end

    it "has the correct 'can_be_updated'" do
      expect(representation).to include('can_be_updated' => true)
    end

    it "has the correct 'attempts_remaining'" do
      expect(representation).to include('attempts_remaining' => 1)
    end

    it "has 'labels'" do
      allow(task_step).to receive(:labels).and_return([])
      expect(complete_representation).to include('labels')
    end

    it "has 'spy'" do
      expect(complete_representation).to include('spy' => { response_validation: { valid: false }})
    end
  end

  context 'non-completed exercise' do
    it_behaves_like 'a good exercise representation should'

    it "'is_completed' == false" do
      expect(representation).to include('is_completed' => false)
    end

    it "'solution' is not included" do
      expect(representation).to_not include('solution')
    end

    it "'feedback_html' is not included" do
      expect(representation).to_not include('feedback_html')
    end

    it "'correct_answer_id' is not included" do
      expect(complete_representation).to_not include('correct_answer_id')
    end

    it "'correct_answer_feedback_html' is not included" do
      expect(complete_representation).to_not include('correct_answer_feedback_html')
    end
  end

  context 'completed exercise' do
    before do
      allow(task_step).to receive(:completed?).and_return(true)

      allow(tasked_exercise).to receive(:free_response).and_return('Some response')
      allow(tasked_exercise).to receive(:answer_id).and_return('123')
      allow(tasked_exercise).to receive(:cache_key).and_return('tasks/models/tasked_exercises/43')
      allow(tasked_exercise).to receive(:cache_version).and_return('test')
    end

    it "'is_completed' == true" do
      expect(representation).to include('is_completed' => true)
    end

    context 'feedback available' do
      before { allow(tasked_exercise).to receive(:feedback_available?).and_return(true) }

      it_behaves_like 'a good exercise representation should'

      context 'solution not available' do
        it "has the correct 'is_feedback_available'" do
          expect(representation).to include('is_feedback_available' => true)
        end

        it "has the correct 'is_solution_available'" do
          expect(representation).to include('is_solution_available' => false)
        end

        it "has the correct 'was_manually_graded'" do
          expect(representation).to include('was_manually_graded' => false)
        end

        it "has correct 'feedback_html'" do
          expect(complete_representation).to include('feedback_html' => 'Some feedback')
        end

        it "has the correct 'published_points_without_lateness'" do
          expect(representation).to include('published_points_without_lateness' => 0.75)
        end

        it "has the correct 'published_late_work_point_penalty'" do
          expect(representation).to include('published_late_work_point_penalty' => 0.25)
        end

        it "has the correct 'published_points'" do
          expect(representation).to include('published_points' => 0.5)
        end

        it "'published_comments' is not included" do
          expect(representation).not_to include('published_comments')
        end

        it "'solution' is not included" do
          expect(complete_representation).not_to include('solution')
        end

        it "'correct_answer_id' is not included" do
          expect(complete_representation).not_to include('correct_answer_id')
        end

        it "'correct_answer_feedback_html' is not included" do
          expect(complete_representation).to_not include('correct_answer_feedback_html')
        end
      end

      context 'solution available' do
        before do
          allow(tasked_exercise).to receive(:attempts_remaining).and_return(0)
          allow(tasked_exercise).to receive(:solution_available?).and_return(true)
        end

        it "has the correct 'is_feedback_available'" do
          expect(representation).to include('is_feedback_available' => true)
        end

        it "has the correct 'is_solution_available'" do
          expect(representation).to include('is_solution_available' => true)
        end

        it "has the correct 'was_manually_graded'" do
          expect(representation).to include('was_manually_graded' => false)
        end

        it "has correct 'feedback_html'" do
          expect(complete_representation).to include('feedback_html' => 'Some feedback')
        end

        it "has the correct 'published_points_without_lateness'" do
          expect(representation).to include('published_points_without_lateness' => 0.75)
        end

        it "has the correct 'published_late_work_point_penalty'" do
          expect(representation).to include('published_late_work_point_penalty' => 0.25)
        end

        it "has the correct 'published_points'" do
          expect(representation).to include('published_points' => 0.5)
        end

        it "has the correct 'published_comments'" do
          expect(representation).to include('published_comments' => 'Hi')
        end

        it "has correct 'solution'" do
          expect(complete_representation).to include('solution' => 'Some solution')
        end

        it "has the correct 'correct_answer_id'" do
          expect(complete_representation).to include('correct_answer_id' => '456')
        end

        it "has the correct 'correct_answer_feedback_html'" do
          expect(complete_representation).to include(
            'correct_answer_feedback_html' => 'More feedback'
          )
        end
      end
    end

    context 'feedback unavailable' do
      it_behaves_like 'a good exercise representation should'

      it "has the correct 'is_feedback_available'" do
        expect(representation).to include('is_feedback_available' => false)
      end

      it "has the correct 'is_solution_available'" do
        expect(representation).to include('is_solution_available' => false)
      end

      it "has the correct 'was_manually_graded'" do
        expect(representation).to include('was_manually_graded' => false)
      end

      it "'feedback_html' is not included" do
        expect(representation).to_not include('feedback_html')
      end

      it "'published_points_without_lateness' is not included" do
        expect(representation).not_to include('published_points_without_lateness')
      end

      it "'published_late_work_point_penalty' is not included" do
        expect(representation).not_to include('published_late_work_point_penalty')
      end

      it "'published_points' is not included" do
        expect(representation).not_to include('published_points')
      end

      it "'published_comments' is not included" do
        expect(representation).not_to include('published_comments')
      end

      it "'solution' is not included" do
        expect(complete_representation).not_to include('solution')
      end

      it "'correct_answer_id' is not included" do
        expect(representation).not_to include('correct_answer_id')
      end

      it "'correct_answer_feedback_html' is not included" do
        expect(complete_representation).to_not include('correct_answer_feedback_html')
      end
    end
  end
end
