module Api::V1
  class RefreshRepresenter < Roar::Decorator

    include Roar::JSON

    property :refresh_step,
             type: Object,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: 'The step to be used for "refresh my memory"'
             }

    property :recovery_step,
             writeable: false,
             readable: true,
             extend: Api::V1::TaskStepRepresenter,
             schema_info: {
               required: true,
               description: 'The exercise to be used for "try another"'
             }
  end
end
