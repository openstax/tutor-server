class Api::V1::Demo::Assign::Course::TaskPlan::Representer < Api::V1::Demo::TaskPlanRepresenter
  property :type,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  collection :book_indices,
             type: Integer,
             getter: ->(*) do
               next unless settings.has_key? 'page_ids'

               Content::Models::Page.where(id: settings['page_ids']).map(&:book_indices).sort
             end,
             readable: true,
             writeable: true

  property :exercises_count_core,
           type: Integer,
           readable: true,
           writeable: true,
           getter: ->(*) { settings['exercises']&.size }

  property :exercises_count_dynamic,
           type: Integer,
           readable: true,
           writeable: true,
           getter: ->(*) { settings['exercises_count_dynamic'] }

  property :external_url,
           type: String,
           readable: true,
           writeable: true,
           getter: ->(*) { settings['external_url'] }

  collection :assigned_to,
             extend: Api::V1::Demo::Assign::Course::TaskPlan::AssignedToRepresenter,
             class: Demo::Mash,
             getter: ->(*) { tasking_plans },
             readable: true,
             writeable: true,
             schema_info: { required: true }

  property :is_published,
           type: Virtus::Attribute::Boolean,
           readable: true,
           writeable: true,
           getter: ->(*) { respond_to?(:is_published) ? is_published : is_published? }
end
