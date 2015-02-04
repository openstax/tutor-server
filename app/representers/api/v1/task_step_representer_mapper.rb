module Api::V1
  class TaskStepRepresenterMapper
    include Uber::Callable

    def self.models 
      map.keys
    end

    def self.representers
      map.values.collect{|v| v.call}
    end

    def call(*args)
      if args[2].is_a?(Hash) && args[2][:all_sub_representers]
        self.class.representers
      else
        step_class = args[1].is_a?(TaskStep) ? args[1].step.class :
                                               args[1].class
        representer = self.class.map[step_class].call
        raise NotYetImplemented if representer.nil?
        representer
      end
    end

protected

    def self.map
      @@map ||= {
        ReadingStep => ->(*) {Api::V1::ReadingStepRepresenter},
        ExerciseStep => ->(*) {Api::V1::ExerciseStepRepresenter},
        InteractiveStep => ->(*) {Api::V1::InteractiveStepRepresenter}
      }
    end

  end
end