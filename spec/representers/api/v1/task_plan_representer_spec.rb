require 'rails_helper'

RSpec.describe Api::V1::TaskPlanRepresenter, type: :representer do

  let(:job) { Jobba::Status.create! }

  let(:task_plan) {
    instance_spy(Tasks::Models::TaskPlan).tap do |dbl|
      ## bug work-around, see:
      ##   https://github.com/rspec/rspec-rails/issues/1309#issuecomment-118971828
      allow(dbl).to receive(:as_json).and_return(dbl)

      allow(dbl).to receive(:publish_job).and_return(job)
      allow(dbl).to receive(:tasking_plans).and_return([])
    end
  }

  ## NOTE: This is lazily-evaluated on purpose!
  let(:representation) { described_class.new(task_plan).as_json }

  context "id" do
    it "can be read" do
      allow(task_plan).to receive(:id).and_return(12)
      expect(representation).to include("id" => 12.to_s)
    end

    it "cannot be written (attempts are silently ignored)" do
      described_class.new(task_plan).from_json({"id" => 42}.to_json)
      expect(task_plan).to_not have_received(:id=)
    end
  end

  context "ecosystem_id" do
    it "can be read" do
      allow(task_plan).to receive(:content_ecosystem_id).and_return(12)
      expect(representation).to include("ecosystem_id" => 12.to_s)
    end

    it "cannot be written (attempts are silently ignored)" do
      described_class.new(task_plan).from_json({"ecosystem_id" => 42}.to_json)
      expect(task_plan).to_not have_received(:content_ecosystem_id=)
    end
  end

  context "type" do
    it "can be read" do
      allow(task_plan).to receive(:type).and_return('Some type')
      expect(representation).to include("type" => 'Some type')
    end

    it "can be written" do
      described_class.new(task_plan).from_json({"type" => 'New type'}.to_json)
      expect(task_plan).to have_received(:type=).with('New type')
    end
  end

  context "title" do
    it "can be read" do
      allow(task_plan).to receive(:title).and_return('Some title')
      expect(representation).to include("title" => 'Some title')
    end

    it "can be written" do
      described_class.new(task_plan).from_json({"title" => 'New title'}.to_json)
      expect(task_plan).to have_received(:title=).with('New title')
    end
  end

  context "description" do
    it "can be read" do
      allow(task_plan).to receive(:description).and_return('Some description')
      expect(representation).to include("description" => 'Some description')
    end

    it "can be written" do
      described_class.new(task_plan).from_json({"description" => 'New description'}.to_json)
      expect(task_plan).to have_received(:description=).with('New description')
    end
  end

  context "is_publish_requested" do
    it "cannot be read" do
      task_plan.is_publish_requested = true
      expect(representation).not_to have_key("is_publish_requested")
    end

    it "can be written" do
      described_class.new(task_plan).from_json({"is_publish_requested" => true}.to_json)
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
      described_class.new(task_plan).from_json(
        {"publish_last_requested_at" => publish_last_requested_at.to_s}.to_json
      )
      expect(task_plan).to_not have_received(:publish_last_requested_at=)
    end
  end

  context "first_published_at" do
    it "can be read" do
      expected = Time.current
      allow(task_plan).to receive(:first_published_at).and_return(expected)
      expect(representation).to(
        include "first_published_at" => DateTimeUtilities.to_api_s(expected)
      )
    end

    it "cannot be written (attempts are silently ignored)" do
      first_published_at = DateTimeUtilities.to_api_s(Time.current)
      described_class.new(task_plan).from_json(
        {"first_published_at" => first_published_at.to_s}.to_json
      )
      expect(task_plan).to_not have_received(:first_published_at=)
    end
  end

  context "last_published_at" do
    it "can be read" do
      expected = Time.current
      allow(task_plan).to receive(:last_published_at).and_return(expected)
      expect(representation).to(
        include "last_published_at" => DateTimeUtilities.to_api_s(expected)
      )
    end

    it "cannot be written (attempts are silently ignored)" do
      last_published_at = DateTimeUtilities.to_api_s(Time.current)
      described_class.new(task_plan).from_json(
        {"last_published_at" => last_published_at.to_s}.to_json
      )
      expect(task_plan).to_not have_received(:last_published_at=)
    end
  end

  context "settings" do
    it "can be read" do
      object = {"some" => "object"}
      allow(task_plan).to receive(:settings).and_return(object)
      expect(representation).to include("settings" => object)
    end

    it "can be written" do
      described_class.new(task_plan).from_json({"settings" => {"some" => "object"}}.to_json)
      expect(task_plan).to have_received(:settings=).with({"some" => "object"})
    end
  end

  context 'cloned_from_id' do
    it 'can be read' do
      allow(task_plan).to receive(:cloned_from_id).and_return('42')
      expect(representation).to include('cloned_from_id' => '42')
    end

    it 'can be written' do
      described_class.new(task_plan).from_hash('cloned_from_id' => '84')
      expect(task_plan).to have_received(:cloned_from_id=).with('84')
    end
  end

  context 'publish_job' do
    it 'can be read' do
      expect(task_plan).to receive(:publish_job).and_return(job)
      expect(representation).to include 'publish_job' => Api::V1::JobRepresenter.new(job).as_json
    end

    it 'cannot be written (attempts are silently ignored)' do
      described_class.new(task_plan).from_hash(
        'publish_job' => Api::V1::JobRepresenter.new(job).as_json
      )

      expect(task_plan).not_to have_received(:publish_job_uuid=)
    end

    context 'exclude_job_info == true' do
      let(:hash_options) { { user_options: { exclude_job_info: true } } }

      it 'cannot be read' do
        allow(task_plan).to receive(:publish_job).and_return(job)
        rep = described_class.new(task_plan).to_hash(hash_options)
        expect(rep).not_to have_key('publish_job')
      end

      it 'cannot be written (attempts are silently ignored)' do
        described_class.new(task_plan).from_hash(
          { 'publish_job' => Api::V1::JobRepresenter.new(job).as_json }, hash_options
        )

        expect(task_plan).not_to have_received(:publish_job_uuid=)
      end
    end
  end

  context 'publish_job_url' do
    let(:uuid) { SecureRandom.uuid   }
    let(:url)  { "/api/jobs/#{uuid}" }

    it 'can be read' do
      expect(task_plan).to receive(:publish_job_uuid).and_return(uuid).twice
      expect(representation).to include 'publish_job_url' => url
    end

    it 'cannot be written (attempts are silently ignored)' do
      described_class.new(task_plan).from_hash('publish_job_url' => url)

      expect(task_plan).not_to have_received(:publish_job_uuid=)
    end

    context 'exclude_job_info == true' do
      let(:hash_options) { { user_options: { exclude_job_info: true } } }

      it 'cannot be read' do
        allow(task_plan).to receive(:publish_job_uuid).and_return(uuid)
        rep = described_class.new(task_plan).to_hash(hash_options)
        expect(rep).not_to have_key('publish_job_url')
      end

      it 'cannot be written (attempts are silently ignored)' do
        described_class.new(task_plan).from_hash({ 'publish_job_url' => url }, hash_options)

        expect(task_plan).not_to have_received(:publish_job_uuid=)
      end
    end
  end

end
