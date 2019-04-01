module Api::V1::Tasks
  class TaskedExternalUrlRepresenter < TaskStepRepresenter
    property :url,
             as: :external_url,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: 'The URL for this external assignment'
             }

    property :title,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: 'The title for this external assignment'
             }
  end
end
