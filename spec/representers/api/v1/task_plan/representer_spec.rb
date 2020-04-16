require 'rails_helper'

RSpec.describe Api::V1::TaskPlan::Representer, type: :representer do
  let(:job) { Jobba::Status.create! }

  let(:task_plan) do
    instance_spy(Tasks::Models::TaskPlan).tap do |dbl|
      ## bug work-around, see:
      ##   https://github.com/rspec/rspec-rails/issues/1309#issuecomment-118971828
      allow(dbl).to receive(:as_json).and_return(dbl)

      allow(dbl).to receive(:publish_job).and_return(job)
      allow(dbl).to receive(:tasking_plans).and_return([])
      allow(dbl).to receive(:extensions).and_return([])
      allow(dbl).to receive(:dropped_questions).and_return([])
    end
  end

  ## NOTE: This is lazily-evaluated on purpose!
  let(:representation) { described_class.new(task_plan).as_json }

  context 'id' do
    it 'can be read' do
      allow(task_plan).to receive(:id).and_return(12)
      expect(representation).to include('id' => '12')
    end

    it 'cannot be written (attempts are silently ignored)' do
      described_class.new(task_plan).from_json({'id' => 42}.to_json)
      expect(task_plan).to_not have_received(:id=)
    end
  end

  context 'ecosystem_id' do
    it 'can be read' do
      allow(task_plan).to receive(:content_ecosystem_id).and_return(12)
      expect(representation).to include('ecosystem_id' => '12')
    end

    it 'cannot be written (attempts are silently ignored)' do
      described_class.new(task_plan).from_json({'ecosystem_id' => 42}.to_json)
      expect(task_plan).to_not have_received(:content_ecosystem_id=)
    end
  end

  context 'grading_template_id' do
    it 'can be read' do
      allow(task_plan).to receive(:tasks_grading_template_id).and_return(42)
      expect(representation).to include('grading_template_id' => '42')
    end

    it 'can be written' do
      described_class.new(task_plan).from_json({'grading_template_id' => '42'}.to_json)
      expect(task_plan).to have_received(:tasks_grading_template_id=).with('42')
    end
  end

  context 'type' do
    it 'can be read' do
      allow(task_plan).to receive(:type).and_return('Some type')
      expect(representation).to include('type' => 'Some type')
    end

    it 'can be written' do
      described_class.new(task_plan).from_json({'type' => 'New type'}.to_json)
      expect(task_plan).to have_received(:type=).with('New type')
    end
  end

  context 'title' do
    it 'can be read' do
      allow(task_plan).to receive(:title).and_return('Some title')
      expect(representation).to include('title' => 'Some title')
    end

    it 'can be written' do
      described_class.new(task_plan).from_json({'title' => 'New title'}.to_json)
      expect(task_plan).to have_received(:title=).with('New title')
    end
  end

  context 'description' do
    it 'can be read' do
      allow(task_plan).to receive(:description).and_return('Some description')
      expect(representation).to include('description' => 'Some description')
    end

    it 'can be written' do
      described_class.new(task_plan).from_json({'description' => 'New description'}.to_json)
      expect(task_plan).to have_received(:description=).with('New description')
    end
  end

  context 'is_publish_requested' do
    it 'cannot be read' do
      task_plan.is_publish_requested = true
      expect(representation).not_to have_key('is_publish_requested')
    end

    it 'can be written' do
      described_class.new(task_plan).from_json({'is_publish_requested' => true}.to_json)
      expect(task_plan).to have_received(:is_publish_requested=).with(true)
    end
  end

  context 'publish_last_requested_at' do
    it 'can be read' do
      expected = Time.current
      allow(task_plan).to receive(:publish_last_requested_at).and_return(expected)
      expect(representation).to(
        include('publish_last_requested_at' => DateTimeUtilities.to_api_s(expected))
      )
    end

    it 'cannot be written (attempts are silently ignored)' do
      publish_last_requested_at = DateTimeUtilities.to_api_s(Time.current)
      described_class.new(task_plan).from_json(
        {'publish_last_requested_at' => publish_last_requested_at.to_s}.to_json
      )
      expect(task_plan).to_not have_received(:publish_last_requested_at=)
    end
  end

  context 'first_published_at' do
    it 'can be read' do
      expected = Time.current
      allow(task_plan).to receive(:first_published_at).and_return(expected)
      expect(representation).to(
        include 'first_published_at' => DateTimeUtilities.to_api_s(expected)
      )
    end

    it 'cannot be written (attempts are silently ignored)' do
      first_published_at = DateTimeUtilities.to_api_s(Time.current)
      described_class.new(task_plan).from_json(
        {'first_published_at' => first_published_at.to_s}.to_json
      )
      expect(task_plan).to_not have_received(:first_published_at=)
    end
  end

  context 'last_published_at' do
    it 'can be read' do
      expected = Time.current
      allow(task_plan).to receive(:last_published_at).and_return(expected)
      expect(representation).to(
        include 'last_published_at' => DateTimeUtilities.to_api_s(expected)
      )
    end

    it 'cannot be written (attempts are silently ignored)' do
      last_published_at = DateTimeUtilities.to_api_s(Time.current)
      described_class.new(task_plan).from_json(
        {'last_published_at' => last_published_at.to_s}.to_json
      )
      expect(task_plan).to_not have_received(:last_published_at=)
    end
  end

  context 'settings' do
    it 'can be read' do
      object = {'some' => 'object'}
      allow(task_plan).to receive(:settings).and_return(object)
      expect(representation).to include('settings' => object)
    end

    it 'can be written' do
      described_class.new(task_plan).from_json({'settings' => {'some' => 'object'}}.to_json)
      expect(task_plan).to have_received(:settings=).with({'some' => 'object'})
    end
  end

  context 'is_preview' do
    it 'can be read' do
      allow(task_plan).to receive(:is_preview).and_return(true)
      expect(representation).to include('is_preview' => true)
    end
    it 'cannot be written (attempts are silently ignored)' do
        described_class.new(task_plan).from_hash({ 'is_preview' => true })
        expect(task_plan).not_to have_received(:is_preview=)
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

      it 'can be read' do
        expect(task_plan).to receive(:publish_job_uuid).and_return(uuid).twice
        expect(representation).to include 'publish_job_url' => url
      end

      it 'cannot be written (attempts are silently ignored)' do
        described_class.new(task_plan).from_hash({ 'publish_job_url' => url }, hash_options)

        expect(task_plan).not_to have_received(:publish_job_uuid=)
      end
    end
  end

  context 'num_completed_tasks' do
    let(:num_completed_tasks) { rand(10) }

    it 'can be read' do
      expect(task_plan).to receive(:num_completed_tasks).and_return(num_completed_tasks)
      expect(representation).to include 'num_completed_tasks' => num_completed_tasks
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect do
        described_class.new(task_plan).from_hash('num_completed_tasks' => num_completed_tasks)
      end.not_to raise_error
    end
  end

  context 'num_in_progress_tasks' do
    let(:num_in_progress_tasks) { rand(10) }

    it 'can be read' do
      expect(task_plan).to receive(:num_in_progress_tasks).and_return(num_in_progress_tasks)
      expect(representation).to include 'num_in_progress_tasks' => num_in_progress_tasks
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect do
        described_class.new(task_plan).from_hash('num_in_progress_tasks' => num_in_progress_tasks)
      end.not_to raise_error
    end
  end

  context 'num_not_started_tasks' do
    let(:num_not_started_tasks) { rand(10) }

    it 'can be read' do
      expect(task_plan).to receive(:num_not_started_tasks).and_return(num_not_started_tasks)
      expect(representation).to include 'num_not_started_tasks' => num_not_started_tasks
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect do
        described_class.new(task_plan).from_hash('num_not_started_tasks' => num_not_started_tasks)
      end.not_to raise_error
    end
  end

  context 'extensions' do
    let(:extension)  do
      Hashie::Mash.new(
        entity_role_id: 42, due_at: Time.current + 1.hour, closes_at: Time.current + 1.day
      )
    end
    let(:extension_representation) do
      Api::V1::TaskPlan::ExtensionRepresenter.new(extension).to_hash
    end

    it 'can be read' do
      expect(task_plan).to receive(:extensions).and_return([ extension ])
      expect(representation).to include 'extensions' => [ extension_representation ]
    end

    it 'can be written' do
      extensions = spy
      expect(task_plan).to receive(:extensions).and_return(extensions)

      described_class.new(task_plan).from_hash({ 'extensions' => [ extension_representation ] })

      expect(extensions).to have_received(:delete_all).with(:delete_all)
      expect(extensions).to have_received(:<<)
    end
  end

  context 'dropped_questions' do
    let(:dropped_question)  do
      Hashie::Mash.new question_id: '42', drop_method: [ :zeroed, :full_credit ].sample
    end
    let(:dropped_question_representation) do
      Api::V1::TaskPlan::DroppedQuestionRepresenter.new(dropped_question).to_hash
    end

    it 'can be read' do
      expect(task_plan).to receive(:dropped_questions).and_return([ dropped_question ])
      expect(representation).to include 'dropped_questions' => [ dropped_question_representation ]
    end

    it 'can be written' do
      dropped_questions = spy
      expect(task_plan).to receive(:dropped_questions).and_return(dropped_questions)

      described_class.new(task_plan).from_hash(
        { 'dropped_questions' => [ dropped_question_representation ] }
      )

      expect(dropped_questions).to have_received(:delete_all).with(:delete_all)
      expect(dropped_questions).to have_received(:<<)
    end
  end
end
