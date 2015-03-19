class Domain::ResetPracticeWidget
  lev_routine

  protected

  def exec(role:, page_ids:)
    # Create a new Task with 5 random exercise steps
    # type == 'practice'
    # Assign it to role inside the Task subsystem (might not have much in there now)
    # return the Task

    binding.pry
    raise NotYetImplemented
    # Delete any incomplete exercises on the current practice widget
    # Create a new practice widget task
    # Populate it with 5 exercises
  end
end