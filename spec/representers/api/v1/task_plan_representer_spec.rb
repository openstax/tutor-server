require 'rails_helper'

RSpec.describe Api::V1::TaskPlanRepresenter, type: :representer do

  let!(:task_plan) {
    tmp = instance_spy(Tasks::Models::TaskPlan)

    # set defaults for represented properties
    allow(tmp).to receive(:id).and_return(nil)
    allow(tmp).to receive(:type).and_return(nil)
    allow(tmp).to receive(:title).and_return(nil)
    allow(tmp).to receive(:description).and_return(nil)
    allow(tmp).to receive(:is_publish_requested).and_return(nil)
    allow(tmp).to receive(:publish_last_requested_at).and_return(nil)
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

  context "description" do
    it "can be read" do
      allow(task_plan).to receive(:description).and_return('Some description')
      expect(representation).to include("description" => 'Some description')
    end

    it "can be written" do
      Api::V1::TaskPlanRepresenter.new(task_plan)
                                  .from_json({"description" => 'New description'}.to_json)
      expect(task_plan).to have_received(:description=).with('New description')
    end
  end

  context "is_publish_requested" do
    it "can be read" do
      allow(task_plan).to receive(:is_publish_requested).and_return(true)
      expect(representation).to include("is_publish_requested" => true)
    end

    it "can be written" do
      Api::V1::TaskPlanRepresenter.new(task_plan).from_json(
        {"is_publish_requested" => true}.to_json
      )
      expect(task_plan).to have_received(:is_publish_requested=).with(true)
    end
  end

  context "publish_last_requested_at" do
    it "can be read" do
      publish_last_requested_at = Time.now
      allow(task_plan).to receive(:publish_last_requested_at).and_return(publish_last_requested_at)
      expect(representation).to(
        include("publish_last_requested_at" => publish_last_requested_at.to_s)
      )
    end

    it "cannot be written (attempts are silently ignored)" do
      publish_last_requested_at = Chronic.parse(Time.now.to_s)
      Api::V1::TaskPlanRepresenter.new(task_plan).from_json(
        {"publish_last_requested_at" => publish_last_requested_at.to_s}.to_json
      )
      expect(task_plan).to_not have_received(:publish_last_requested_at=)
    end
  end

  context "published_at" do
    it "can be read" do
      published_at = Time.now
      allow(task_plan).to receive(:published_at).and_return(published_at)
      expect(representation).to include("published_at" => published_at.to_s)
    end

    it "cannot be written (attempts are silently ignored)" do
      published_at = Chronic.parse(Time.now.to_s)
      Api::V1::TaskPlanRepresenter.new(task_plan).from_json({"published_at" => published_at.to_s}.to_json)
      expect(task_plan).to_not have_received(:published_at=)
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
