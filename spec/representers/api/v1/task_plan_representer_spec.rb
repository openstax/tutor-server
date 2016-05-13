require 'rails_helper'

RSpec.describe Api::V1::TaskPlanRepresenter, type: :representer do

  let!(:task_plan) {
    instance_spy(Tasks::Models::TaskPlan).tap do |dbl|
      ## bug work-around, see:
      ##   https://github.com/rspec/rspec-rails/issues/1309#issuecomment-118971828
      allow(dbl).to receive(:as_json).and_return(dbl)

      allow(dbl).to receive(:tasking_plans).and_return([])
    end
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

  context "ecosystem_id" do
    it "can be read" do
      allow(task_plan).to receive(:content_ecosystem_id).and_return(12)
      expect(representation).to include("ecosystem_id" => 12.to_s)
    end

    it "cannot be written (attempts are silently ignored)" do
      Api::V1::TaskPlanRepresenter.new(task_plan).from_json({"ecosystem_id" => 42}.to_json)
      expect(task_plan).to_not have_received(:content_ecosystem_id=)
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
      allow(task_plan).to receive(:is_publish_requested?).and_return(true)
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
      expected = Time.current
      allow(task_plan).to receive(:publish_last_requested_at).and_return(expected)
      expect(representation).to(
        include("publish_last_requested_at" => DateTimeUtilities.to_api_s(expected))
      )
    end

    it "cannot be written (attempts are silently ignored)" do
      publish_last_requested_at = DateTimeUtilities.to_api_s(Time.current)
      Api::V1::TaskPlanRepresenter.new(task_plan).from_json(
        {"publish_last_requested_at" => publish_last_requested_at.to_s}.to_json
      )
      expect(task_plan).to_not have_received(:publish_last_requested_at=)
    end
  end

  context "published_at" do
    it "can be read" do
      expected = Time.current
      allow(task_plan).to receive(:published_at).and_return(expected)
      expect(representation).to include("published_at" => DateTimeUtilities.to_api_s(expected))
    end

    it "cannot be written (attempts are silently ignored)" do
      published_at = DateTimeUtilities.to_api_s(Time.current)
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

  context "shareable_url" do
    it "can be generated from model" do
      FactoryGirl.create :short_code_short_code, code: 'short',
                         uri: task_plan.to_global_id.to_s
      allow(task_plan).to receive(:title).and_return('Read ch 4')
      expect(representation).to include("shareable_url" => '/@/short/read-ch-4')
    end

    it 'can be read from provided data' do
      data = Hashie::Mash.new FactoryGirl.build(:tasks_task_plan).as_json
      data['shareable_url'] = '/@/blah/foo-bar-baz'
      representation = Api::V1::TaskPlanRepresenter.new(data).as_json
      expect(representation).to include("shareable_url" => '/@/blah/foo-bar-baz')
    end

    it "cannot be written (attempts are silently ignored)" do
      Api::V1::TaskPlanRepresenter.new(task_plan).from_json({
        "shareable_url" => 'http://www.example.org'
      }.to_json)

      representation = Api::V1::TaskPlanRepresenter.new(task_plan).as_json
      expect(representation).to_not include("shareable_url")
    end
  end

end
