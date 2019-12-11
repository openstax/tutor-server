require 'rails_helper'

RSpec.describe Api::V1::TaskPlan::ExtensionRepresenter, type: :representer do
  let(:extension) do
    instance_spy(Tasks::Models::Extension).tap do |dbl|
      ## bug work-around, see:
      ##   https://github.com/rspec/rspec-rails/issues/1309#issuecomment-118971828
      allow(dbl).to receive(:as_json).and_return(dbl)
    end
  end

  let(:representation) do ## NOTE: This is lazily-evaluated on purpose!
    Api::V1::TaskPlan::ExtensionRepresenter.new(extension).as_json
  end

  context 'role_id' do
    it 'can be read' do
      allow(extension).to receive(:entity_role_id).and_return(12)
      expect(representation).to include('role_id' => '12')
    end

    it 'can be written' do
      described_class.new(extension).from_json({ role_id: '42' }.to_json)
      expect(extension).to have_received(:entity_role_id=).with('42')
    end
  end

  [ :due_at, :closes_at ].each do |field|
    context field.to_s do
      it 'can be read (date coerced to String)' do
        datetime = Time.current
        allow(extension).to receive(field).and_return(datetime)
        expect(representation).to include(field.to_s => DateTimeUtilities::to_api_s(datetime))
      end

      it 'can be written' do
        datetime_str = Time.current.iso8601
        described_class.new(extension).from_json({ field => datetime_str }.to_json)
        expect(extension).to have_received("#{field}=").with(datetime_str)
      end
    end
  end
end
