require 'rails_helper'

RSpec.describe Tasks::Models::TaskStep, type: :model do
  subject(:task_step) { FactoryGirl.create :tasks_task_step }

  it { is_expected.to belong_to(:task) }
  it { is_expected.to belong_to(:tasked) }

  it { is_expected.to validate_presence_of(:task) }
  it { is_expected.to validate_presence_of(:tasked) }
  it { is_expected.to validate_presence_of(:group_type) }

  describe '#complete' do
    let(:time) { Time.current }

    before { Timecop.freeze(time) { task_step.complete } }

    it 'completes a first and last completion datetime to track lateness' do
      expect(task_step.first_completed_at).to eq(time)
      expect(task_step.last_completed_at).to eq(time)
    end
  end

  it "requires tasked to be unique" do
    expect(task_step).to be_valid

    expect(FactoryGirl.build(:tasks_task_step, tasked: task_step.tasked)).not_to be_valid
  end

  it "invalidates task's cache when updated" do
    task_step.tasked = FactoryGirl.build :tasks_tasked_exercise, task_step: task_step
    expect { task_step.save! }.to change{ task_step.task.cache_key }
  end

  context "group types" do
    it "is created with 'default' group type" do
      expect(task_step.default_group?).to be_truthy
    end

    it "supports the 'core' group type" do
      task_step.core_group!
      expect(task_step.core_group?).to be_truthy
    end

    it "supports the 'spaced practice' group type" do
      task_step.spaced_practice_group!
      expect(task_step.spaced_practice_group?).to be_truthy
    end

    it "supports the 'personalized' group type" do
      task_step.personalized_group!
      expect(task_step.personalized_group?).to be_truthy
    end
  end

  it "converts its group type to a name" do
    name_by_type = {
      "default_group"         => "default",
      "core_group"            => "core",
      "spaced_practice_group" => "spaced practice",
      "personalized_group"    => "personalized",
      "recovery_group"        => "recovery"
    }

    Tasks::Models::TaskStep.group_types.keys.each do |group_type|
      allow(task_step).to receive(:group_type).and_return(group_type)
      expect(task_step.group_name).to eq(name_by_type[group_type])
    end
  end

  context "related content" do
    it "can get related content" do
      expect(task_step.related_content).to eq([])
    end

    it "can set related content" do
      target_related_content = [{'title' => 'blah', 'chapter_section' => 'blah'}]
      task_step.related_content = target_related_content
      task_step.save!
      task_step.reload
      expect(task_step.related_content).to eq(target_related_content)
    end

    it "can add new related content" do
      expect(task_step.related_content).to eq([])

      content = {'title' => 'blah', 'chapter_section' => 'blah'}
      expect{
        task_step.add_related_content content
        task_step.save!
        task_step.reload
      }.to change{task_step.related_content}.by [content]
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

    it "can add new labels" do
      expect(task_step.labels).to eq([])

      labels = ['a', 'b']
      expect{
        task_step.add_labels labels
        task_step.save!
        task_step.reload
      }.to change{task_step.labels}.by labels
    end
  end
end
