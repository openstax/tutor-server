module Api::V1
  class MetataskedRepresenterMapper

    REPRESENTER_MAP = {
      'Tasks::Models::TaskedExercise'    => '::Api::V1::Metatasks::TaskedExerciseRepresenter',
      'Tasks::Models::TaskedInteractive' => '::Api::V1::Metatasks::TaskedInteractiveRepresenter',
      'Tasks::Models::TaskedPlaceholder' => '::Api::V1::Metatasks::TaskedPlaceholderRepresenter',
      'Tasks::Models::TaskedReading'     => '::Api::V1::Metatasks::TaskedReadingRepresenter',
      'Tasks::Models::TaskedVideo'       => '::Api::V1::Metatasks::TaskedVideoRepresenter',
      'Tasks::Models::TaskedExternalUrl' => '::Api::V1::Metatasks::TaskedExternalUrlRepresenter'
    }

    include Uber::Callable

    def self.representer_for(task_step_or_tasked)
      tasked_class = task_step_or_tasked.is_a?(::Tasks::Models::TaskStep) ?
                       task_step_or_tasked.tasked.class :
                       task_step_or_tasked.class
      representer = REPRESENTER_MAP[tasked_class.name].constantize
      representer || (raise NotYetImplemented)
    end

    def call(*args)
      if args[2].is_a?(Hash) && args[2][:all_sub_representers]
        self.class.representers
      else
        self.class.representer_for(args[1])
      end
    end

  end
end
