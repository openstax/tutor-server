require 'rails_helper'

RSpec.describe Research::Models::Manipulation, type: :model do
  let(:cohort)    { FactoryBot.create :research_cohort }
  let(:study)     { cohort.study }
  let(:code)      { "manipulation.record!" }
  let(:brain)     { FactoryBot.create(:research_modified_tasked, study: study, code: code) }
  let(:task_step) { FactoryBot.build(:tasks_tasked_exercise, skip_task: true).task_step }

  it 'remembers if it should record' do
    manipulation = Research::Models::Manipulation.new study: study
    expect(manipulation.should_record?).to be false
    expect(manipulation.save).to be false
    expect(manipulation.errors.full_messages.first).to include 'cannot save'
    manipulation.record!
    expect(manipulation.should_record?).to be true
  end

  context 'raising exception' do
    let(:manipulation) { Research::Models::Manipulation.new }

    it 'when ignore! or record! are not called' do
      expect do
        manipulation.explode_if_unmarked
      end.to raise_error(described_class::RecordingPreferenceNotSpecified)
    end

    it 'wnen ignore! is called' do
      manipulation.ignore!
      expect { manipulation.explode_if_unmarked }.not_to raise_error
    end

    it 'when record! is called' do
      manipulation.record!
      expect { manipulation.explode_if_unmarked }.not_to raise_error
    end

  end

end
