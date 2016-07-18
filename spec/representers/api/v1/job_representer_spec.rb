require 'rails_helper'

RSpec.describe Api::V1::JobRepresenter, type: :representer do

  let(:job) {
    instance_spy(Jobba::Status).tap do |dbl|
      ## bug work-around, see:
      ##   https://github.com/rspec/rspec-rails/issues/1309#issuecomment-118971828
      allow(dbl).to receive(:as_json).and_return(dbl)
      allow(dbl).to receive(:state).and_return(
        instance_spy(Jobba::State).tap do |dbl2|
          allow(dbl2).to receive(:name).and_return('test')
        end
      )
      allow(dbl).to receive(:errors).and_return([])
    end
  }

  let(:representation) { ## NOTE: This is lazily-evaluated on purpose!
    described_class.new(job).as_json
  }

  context "id" do
    it "can be read" do
      allow(job).to receive(:id).and_return(42)
      expect(representation).to include("id" => "42")
    end

    it "cannot be written (attempts are silently ignored)" do
      described_class.new(job).from_json({"id" => "42"}.to_json)
      expect(job).to_not have_received(:id=)
    end
  end

  context "status" do
    it "can be read" do
      expect(representation).to include("status" => "test")
    end

    it "cannot be written (attempts are silently ignored)" do
      expect{ described_class.new(job).from_json({"status" => "test"}.to_json) }.not_to raise_error
      expect(job).to_not have_received(:state)
      expect(job).to_not have_received(:state=)
    end
  end

  context "progress" do
    it "can be read" do
      allow(job).to receive(:progress).and_return(1.0)
      expect(representation).to include("progress" => 1.0)
    end

    it "cannot be written (attempts are silently ignored)" do
      described_class.new(job).from_json({"progress" => 1.0}.to_json)
      expect(job).to_not have_received(:progress=)
    end
  end

  context "url" do
    it "can be read" do
      allow(job).to receive(:data).and_return({'url' => "https://www.example.com"})
      expect(representation).to include("url" => "https://www.example.com")
    end

    it "cannot be written (attempts are silently ignored)" do
      described_class.new(job).from_json({"url" => "https://www.example.com"}.to_json)
      expect(job).to_not have_received(:data)
      expect(job).to_not have_received(:data=)
    end
  end

  context "errors" do
    it "can be read" do
      allow(job).to receive(:errors).and_return([{"code" => "test"}])
      expect(representation).to include("errors" => [{"code" => "test"}])
    end

    it "cannot be written (attempts are silently ignored)" do
      described_class.new(job).from_json(
        {"errors" => [{"code" => "test"}]}.to_json
      )
      expect(job).to_not have_received(:errors=)
    end
  end

end
