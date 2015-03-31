module Api::V1
  module TaskStepProperties

    include Roar::JSON

    # These properties will be included in specific Tasked steps; therefore
    # their getters will be called from that context and so must call up to
    # the "task_step" to access data in the TaskStep "base" class.
    #
    # Using included properties instead of decorator inheritance makes it easier
    # to render and parse json -- there is no confusion about which level to use
    # it is always just the Tasked level and properties that access "base" class
    # values always reach up to it.

    property :id,
             type: Integer,
             writeable: false,
             getter: -> (*) { task_step.id },
             schema_info: {
               required: true
             }

    property :type,
             type: String,
             writeable: false,
             readable: true,
             getter: lambda { |*| self.class.name.demodulize.gsub("Tasked","").underscore.downcase },
             schema_info: {
               required: true,
               description: "The type of this TaskStep, one of: #{
                            TaskedRepresenterMapper.models.collect{ |klass|
                              "'" + klass.name.demodulize.gsub("Tasked","")
                                         .underscore.downcase + "'"
                            }.join(',')}"
             }

    property :is_completed,
             type: 'boolean',
             writeable: false,
             readable: true,
             getter: lambda {|*| task_step.completed?},
             schema_info: {
               required: true,
               description: "Whether or not this step is complete"
             }


  end
end
