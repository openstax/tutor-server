module Api::V1
  class TaskStepRepresenter < Roar::Decorator
    def self.prepare(task_step)
      tasked = task_step.tasked
      TaskedRepresenterMapper.representer_for(tasked).prepare(tasked)
    end
  end
end
