module Api::V1
  class TaskedRepresenterMapper

    include Uber::Callable

    def self.models
      map.keys
    end

    def self.representers
      map.values.collect{|v| v.call}
    end

    def self.representer_for(task_step_or_tasked)
      tasked_class = task_step_or_tasked.is_a?(Tasks::Models::TaskStep) ?
                       task_step_or_tasked.tasked.class :
                       task_step_or_tasked.class
      representer = map[tasked_class].call
      representer || (raise NotYetImplemented)
    end

    def call(*args)
      if args[2].is_a?(Hash) && args[2][:all_sub_representers]
        self.class.representers
      else
        self.class.representer_for(args[1])
      end
    end

    protected

    def self.map
      @@map ||= {
        Tasks::Models::TaskedReading     => ->(*){TaskedReadingRepresenter},
        Tasks::Models::TaskedExercise    => ->(*){TaskedExerciseRepresenter},
        Tasks::Models::TaskedVideo       => ->(*){TaskedVideoRepresenter},
        Tasks::Models::TaskedInteractive => ->(*){TaskedInteractiveRepresenter},
        Tasks::Models::TaskedPlaceholder => ->(*){TaskedPlaceholderRepresenter}
      }
    end

  end
end
