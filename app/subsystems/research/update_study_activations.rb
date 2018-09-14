class Research::UpdateStudyActivations

  lev_routine

  uses_routine Research::ActivateStudy
  uses_routine Research::DeactivateStudy

  def exec
    # Only autoactivate studies that have never been active
    Research::Models::Study.never_active.activate_at_has_passed.each do |study|
      run(Research::ActivateStudy, study)
    end

    Research::Models::Study.active.deactivate_at_has_passed.each do |study|
      run(Research::DeactivateStudy, study)
    end
  end
end
