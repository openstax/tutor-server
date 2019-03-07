module Api::V1
  class MetataskStepRepresenter < Roar::Decorator

    def self.prepare(task_step)
      tasked = task_step.tasked
      MetataskedRepresenterMapper.representer_for(tasked).prepare(tasked)
    end
  end
end
