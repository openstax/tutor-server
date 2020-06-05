require 'rails_helper'

RSpec.describe Api::V1::TaskPlan::TaskingPlanRepresenter, type: :representer do
  let(:tasking_plan) do
    instance_spy(Tasks::Models::TaskingPlan).tap do |dbl|
      ## bug work-around, see:
      ##   https://github.com/rspec/rspec-rails/issues/1309#issuecomment-118971828
      allow(dbl).to receive(:as_json).and_return(dbl)
    end
  end

  let(:representation) do ## NOTE: This is lazily-evaluated on purpose!
    described_class.new(tasking_plan).as_json
  end

  let(:year_str)      { '2015' }
  let(:month_str)     { '01' }
  let(:day_str)       { '04' }

  let(:date_str)      { "#{year_str}-#{month_str}-#{day_str}" }
  let(:date_time_str) { "#{date_str}T14:32:34" }

  context 'target_id' do
    it 'can be read' do
      allow(tasking_plan).to receive(:target_id).and_return(12)
      expect(representation).to include('target_id' => 12.to_s)
    end

    it 'cannot be written (attempts are silently ignored)' do
      described_class.new(tasking_plan).from_json({ target_id: 42 }.to_json)
      expect(tasking_plan).to have_received(:target_id=).with('42')
    end
  end

  context 'target_type' do
    it "can be read ('CourseMembership::Models::Period' => 'period')" do
      allow(tasking_plan).to receive(:target_type).and_return('CourseMembership::Models::Period')
      expect(representation).to include('target_type' => 'period')
    end

    it "can be read ('CourseProfile::Models::Course' => 'course')" do
      allow(tasking_plan).to receive(:target_type).and_return('CourseProfile::Models::Course')
      expect(representation).to include('target_type' => 'course')
    end

    it "can be written ('period' => 'CourseMembership::Models::Period')" do
      rep = described_class.new(tasking_plan).from_json({'target_type' => 'period'}.to_json)
      expect(tasking_plan).to have_received(:target_type=).with('CourseMembership::Models::Period')
    end

    it "can be written ('course' => 'CourseProfile::Models::Course')" do
      described_class.new(tasking_plan).from_json({'target_type' => 'course'}.to_json)
      expect(tasking_plan).to have_received(:target_type=).with('CourseProfile::Models::Course')
    end
  end

  context 'opens_at, due_at and closes_at' do
    %w(opens_at due_at closes_at).each do |field|
      context field do
        it 'can be read (date coerced to String)' do
          datetime = Time.zone.now
          allow(tasking_plan).to receive(field).and_return(datetime)
          expect(representation).to include(field => DateTimeUtilities::to_api_s(datetime))
        end

        it 'can be written' do
          consume(input: { field => date_time_str }, to: tasking_plan)
          expect(tasking_plan).to have_received("#{field}=").with(date_time_str)
        end
      end
    end
  end

  context 'completed_wrq_step_count' do
    it 'can be read' do
      allow(tasking_plan).to receive(:completed_wrq_step_count).and_return(21)
      expect(representation).to include('completed_wrq_step_count' => 21)
    end

    it 'cannot be written (attempts are silently ignored)' do
      described_class.new(tasking_plan).from_json({ completed_wrq_step_count: 42 }.to_json)
      expect(tasking_plan).not_to have_received(:completed_wrq_step_count=)
    end
  end

  context 'ungraded_wrq_step_count' do
    it 'can be read' do
      allow(tasking_plan).to receive(:ungraded_wrq_step_count).and_return(21)
      expect(representation).to include('ungraded_wrq_step_count' => 21)
    end

    it 'cannot be written (attempts are silently ignored)' do
      described_class.new(tasking_plan).from_json({ ungraded_wrq_step_count: 42 }.to_json)
      expect(tasking_plan).not_to have_received(:ungraded_wrq_step_count=)
    end
  end

  # A helper for reading input (json or hash) into a TaskingPlan.
  def consume(input:, to: tasking_plan)
    described_class.new(to).from_json(
      case input
      when String
        input
      when Hash
        input.to_json
      else
        raise StandardError
      end
    )
  end
end
