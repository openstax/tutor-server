require 'rails_helper'

RSpec.describe Api::V1::TaskPlanRepresenter, type: :representer do

  let!(:task_plan) {
    tmp = instance_spy(Tasks::Models::TaskPlan)

    # set defaults for represented properties
    allow(tmp).to receive(:id).and_return(nil)
    allow(tmp).to receive(:type).and_return(nil)
    allow(tmp).to receive(:title).and_return(nil)
    allow(tmp).to receive(:published_at).and_return(nil)
    allow(tmp).to receive(:settings).and_return(nil)
    allow(tmp).to receive(:tasking_plans).and_return(nil)

    tmp
  }

  let(:representation) { ## NOTE: This is lazily-evaluated on purpose!
    Api::V1::TaskPlanRepresenter.new(task_plan).as_json
  }

  context "id" do
    it "can be read" do
      allow(task_plan).to receive(:id).and_return(12)
      expect(representation).to include("id" => 12.to_s)
    end

    it "cannot be written (attempts are silently ignored)" do
      Api::V1::TaskPlanRepresenter.new(task_plan).from_json({"id" => 42}.to_json)
      expect(task_plan).to_not have_received(:id=)
    end
  end

  context "type" do
    it "can be read" do
      allow(task_plan).to receive(:type).and_return('Some type')
      expect(representation).to include("type" => 'Some type')
    end

    it "can be written" do
      Api::V1::TaskPlanRepresenter.new(task_plan).from_json({"type" => 'New type'}.to_json)
      expect(task_plan).to have_received(:type=).with('New type')
    end
  end

  context "title" do
    it "can be read" do
      allow(task_plan).to receive(:title).and_return('Some title')
      expect(representation).to include("title" => 'Some title')
    end

    it "can be written" do
      Api::V1::TaskPlanRepresenter.new(task_plan).from_json({"title" => 'New title'}.to_json)
      expect(task_plan).to have_received(:title=).with('New title')
    end
  end

  context "published_at" do
    it "can be read" do
      published_at = Time.now
      allow(task_plan).to receive(:published_at).and_return(published_at)
      expect(representation).to include("published_at" => published_at.to_s)
    end

    it "can be written (String coerced to Time)" do
      published_at = Chronic.parse(Time.now.to_s)
      Api::V1::TaskPlanRepresenter.new(task_plan).from_json({"published_at" => published_at.to_s}.to_json)
      expect(task_plan).to have_received(:published_at=).with(published_at)
    end
  end

  context "settings" do
    it "can be read" do
      object = {"some" => "object"}
      allow(task_plan).to receive(:settings).and_return(object)
      expect(representation).to include("settings" => object)
    end

    it "can be written" do
      Api::V1::TaskPlanRepresenter.new(task_plan).from_json({"settings" => {"some" => "object"}}.to_json)
      expect(task_plan).to have_received(:settings=).with({"some" => "object"})
    end
  end

end
