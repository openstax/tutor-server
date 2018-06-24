class Research::UpdateStudyActivations

  lev_routine

  uses_routine Research::ActivateStudy
  uses_routine Research::DeactivateStudy

  def exec
    # Only auto
    Research::Models::Study.never_active.activate_at_has_passed.each do |study|
      run(Research::ActivateStudy, study)
    end

    Research::Models::Study.active.deactivate_at_has_passed.each do |study|
      run(Research::DeactivateStudy, study)
    end
  end
end
