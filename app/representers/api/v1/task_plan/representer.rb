class Api::V1::TaskPlan::Representer < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  property :id,
           type: String,
           readable: true,
           writeable: false

  property :tasks_grading_template_id,
           as: :grading_template_id,
           type: String,
           readable: true,
           writeable: true

  property :content_ecosystem_id,
           as: :ecosystem_id,
           type: String,
           readable: true,
           writeable: false

  property :type,
           type: String,
           readable: true,
           writeable: true

  property :title,
           type: String,
           readable: true,
           writeable: true

  property :description,
           type: String,
           readable: true,
           writeable: true

  property :is_publish_requested,
           readable: false,
           writeable: true,
           schema_info: { type: 'boolean' }

  property :is_draft,
           readable: true,
           writeable: false,
           getter: ->(*) { is_draft? },
           schema_info: { type: 'boolean' }

  property :is_preview,
           readable: true,
           writeable: false

  property :is_publishing,
           readable: true,
           writeable: false,
           getter: ->(*) { is_publishing? },
           schema_info: { type: 'boolean' }

  property :is_published,
           readable: true,
           writeable: false,
           getter: ->(*) { is_published? },
           schema_info: { type: 'boolean' }

  property :publish_last_requested_at,
           type: String,
           readable: true,
           writeable: false,
           getter: ->(*) { DateTimeUtilities.to_api_s(publish_last_requested_at) }

  property :first_published_at,
           type: String,
           readable: true,
           writeable: false,
           getter: ->(*) { DateTimeUtilities.to_api_s(first_published_at) }

  property :last_published_at,
           type: String,
           readable: true,
           writeable: false,
           getter: ->(*) { DateTimeUtilities.to_api_s(last_published_at) }

  property :settings,
           type: Object,
           readable: true,
           writeable: true

  property :cloned_from_id,
           type: String,
           readable: true,
           writeable: true

  property :publish_job,
           extend: Api::V1::JobRepresenter,
           readable: true,
           writeable: false,
           if: ->(user_options:, **) { !user_options.try!(:[], :exclude_job_info) }

  property :publish_job_url,
           type: String,
           readable: true,
           writeable: false,
           getter: ->(*) { "/api/jobs/#{publish_job_uuid}" if publish_job_uuid.present? }

  property :num_completed_tasks,
           type: Integer,
           readable: true,
           writeable: false

  property :num_in_progress_tasks,
           type: Integer,
           readable: true,
           writeable: false

  property :num_not_started_tasks,
           type: Integer,
           readable: true,
           writeable: false

  property :wrq_count,
           type: Integer,
           readable: true,
           writeable: false

  property :gradable_step_count,
           type: Integer,
           readable: true,
           writeable: false

  property :ungraded_step_count,
           type: Integer,
           readable: true,
           writeable: false

  collection :tasking_plans,
             class: ::Tasks::Models::TaskingPlan,
             extend: Api::V1::TaskPlan::TaskingPlanRepresenter,
             setter: Api::V1::RailsCollectionSetter,
             readable: true,
             writeable: true

  collection :extensions,
             class: ::Tasks::Models::Extension,
             extend: Api::V1::TaskPlan::ExtensionRepresenter,
             setter: Api::V1::RailsCollectionSetter,
             readable: true,
             writeable: true

  collection :dropped_questions,
             class: ::Tasks::Models::DroppedQuestion,
             extend: Api::V1::TaskPlan::DroppedQuestionRepresenter,
             setter: Api::V1::RailsCollectionSetter,
             readable: true,
             writeable: true
end
