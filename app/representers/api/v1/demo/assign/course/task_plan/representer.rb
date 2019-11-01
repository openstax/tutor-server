class Api::V1::Demo::Assign::Course::TaskPlan::Representer < Api::V1::Demo::TaskPlanRepresenter
  property :type,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :exercises_count_core,
           type: Integer,
           readable: false,
           writeable: true

  property :exercises_count_dynamic,
           type: Integer,
           readable: false,
           writeable: true

  property :is_published,
           type: Virtus::Attribute::Boolean,
           readable: false,
           writeable: true,
           getter: ->(*) { respond_to?(:is_published) ? is_published : is_published? }

  collection :book_locations,
             extend:
             Api::V1::Demo::Assign::Course::TaskPlan::BookLocationRepresenter,
             class: Demo::Mash,
             getter: ->(*) do
               Content::Models::Page.where(id: settings['page_ids'])
                                    .map(&:book_location).sort.map do |book_location|
                 Demo::Mash.new(chapter: book_location.first, section: book_location.last)
               end
             end,
             readable: true,
             writeable: true,
             schema_info: { required: true }

  collection :assigned_to,
             extend: Api::V1::Demo::Assign::Course::TaskPlan::AssignedToRepresenter,
             class: Demo::Mash,
             getter: ->(*) { tasking_plans },
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
