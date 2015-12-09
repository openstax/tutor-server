class GetPracticeWidget
  lev_routine outputs: { task: Tasks::GetPracticeTask }

  protected

  def exec(role:)
    run(:tasks_get_practice_task, role: role)
  end
end
