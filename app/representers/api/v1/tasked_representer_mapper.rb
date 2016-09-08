module Api::V1
  class TaskedRepresenterMapper

    REPRESENTER_MAP = {
      'Tasks::Models::TaskedExercise'    => 'Api::V1::Tasks::TaskedExerciseRepresenter',
      'Tasks::Models::TaskedInteractive' => 'Api::V1::Tasks::TaskedInteractiveRepresenter',
      'Tasks::Models::TaskedPlaceholder' => 'Api::V1::Tasks::TaskedPlaceholderRepresenter',
      'Tasks::Models::TaskedReading'     => 'Api::V1::Tasks::TaskedReadingRepresenter',
      'Tasks::Models::TaskedVideo'       => 'Api::V1::Tasks::TaskedVideoRepresenter',
      'Tasks::Models::TaskedExternalUrl' => 'Api::V1::Tasks::TaskedExternalUrlRepresenter'
    }

    include Uber::Callable

    class << self

      def model_class_names
        representer_map.keys
      end

      def representer_class_names
        representer_map.values
      end

      def representer_for(task_step_or_tasked)
        tasked_class = task_step_or_tasked.is_a?(::Tasks::Models::TaskStep) ?
                         task_step_or_tasked.tasked.class :
                         task_step_or_tasked.class
        representer = representer_map[tasked_class.name].constantize
        representer || (raise NotYetImplemented)
      end
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
