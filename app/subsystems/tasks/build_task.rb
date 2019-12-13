class Tasks::BuildTask
  lev_routine express_output: :task

  protected

  def exec(attributes)
    outputs.task = Tasks::Models::Task.new(attributes)
  end
end
