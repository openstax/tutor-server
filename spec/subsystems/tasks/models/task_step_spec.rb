require 'rails_helper'

RSpec.describe Tasks::Models::TaskStep, type: :model do

  subject(:task_step) { FactoryBot.create :tasks_task_step }

  it { is_expected.to belong_to(:task) }
  it { is_expected.to belong_to(:tasked) }

  it { is_expected.to validate_presence_of(:group_type) }

  it do
    is_expected.to(
      validate_numericality_of(:fragment_index).only_integer
                                               .is_greater_than_or_equal_to(0)
                                               .allow_nil
    )
  end

  context '#complete' do
    let(:time) { Time.current }

    before { Timecop.freeze(time) { task_step.complete! } }

    it 'completes a first and last completion datetime to track lateness' do
      expect(task_step.first_completed_at).to eq(time)
      expect(task_step.last_completed_at).to eq(time)
    end
  end

  it "requires tasked to be unique" do
    expect(task_step).to be_valid

    expect(FactoryBot.build(:tasks_task_step, tasked: task_step.tasked)).not_to be_valid
  end

  it "invalidates task's cache when updated" do
    task_step.tasked = FactoryBot.build :tasks_tasked_exercise, task_step: task_step
    expect { task_step.save! }.to change { task_step.task.cache_version }
  end

  it 'includes response_validation in spy_with_response_validation' do
    task_step.tasked = FactoryBot.build :tasks_tasked_exercise,
                                        task_step: task_step,
                                        response_validation: { valid: false }
    expect(task_step.spy_with_response_validation).to eq(response_validation: { 'valid' => false })
  end

  context "group types" do
    it "supports the 'fixed_group' group type" do
      task_step.fixed_group!
      expect(task_step.fixed_group?).to be_truthy
    end

    it "supports the 'spaced_practice_group' group type" do
      task_step.spaced_practice_group!
      expect(task_step.spaced_practice_group?).to be_truthy
    end

    it "supports the 'personalized_group' group type" do
      task_step.personalized_group!
      expect(task_step.personalized_group?).to be_truthy
    end
  end

  it "converts its group type to a name" do
    name_by_type = {
      "unknown_group"         => "unknown",
      "fixed_group"           => "fixed",
      "spaced_practice_group" => "spaced practice",
      "personalized_group"    => "personalized",
      "recovery_group"        => "recovery"
    }

    Tasks::Models::TaskStep.group_types.keys.each do |group_type|
      allow(task_step).to receive(:group_type).and_return(group_type)
      expect(task_step.group_name).to eq(name_by_type[group_type])
    end
  end

  context "labels" do
    it "can get labels" do
      expect(task_step.labels).to eq([])
    end

    it "can set labels" do
      target_labels = ['label1', 'label2']
      task_step.labels = target_labels
      task_step.save!
      task_step.reload
      expect(task_step.labels).to eq(target_labels)
    end
  end

  context "related content" do
    it "can get related content" do
      expect(task_step.related_content).to eq([ task_step.page.related_content ])
      task_step.page = nil
      expect(task_step.related_content).to eq([])
    end
  end

  context 'exercise #can_be_updated?' do
    context 'after the step is completed and feedback is available' do
      before do
        task_step.tasked = FactoryBot.create :tasks_tasked_exercise, task_step: task_step
        # Make sure we have 2 attempts
        task_step.tasked.answer_ids += task_step.tasked.answer_ids
        expect(task_step.tasked.answer_ids.size).to eq 4

        task_step.task.grading_template.update_attribute :auto_grading_feedback_on, :answer

        Preview::AnswerExercise.call task_step: task_step, is_correct: false
        expect(task_step.reload.tasked.attempt_number).to eq 1
      end

      context 'single attempt' do
        it 'returns false' do
          expect(task_step.can_be_updated?).to eq false
        end
      end

      context 'multiple attempts' do
        before do
          task_step.task.grading_template.update_attribute(
            :allow_auto_graded_multiple_attempts, true
          )
        end

        it 'returns true until the maximum number of attempts is exceeded' do
          expect(task_step.can_be_updated?).to eq true

          Preview::AnswerExercise.call(
            task_step: task_step, free_response: task_step.tasked.free_response, is_correct: true
          )
          expect(task_step.tasked.attempt_number).to eq 2

          expect(task_step.can_be_updated?).to eq false
        end
      end
    end
  end
end
