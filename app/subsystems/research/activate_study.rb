class Research::ActivateStudy
  lev_routine

  def exec(study)
    study.update_attribute(:last_activated_at, Time.current)
    transfer_errors_from(study, {type: :verbatim}, true)

    # side effects?

    Rails.logger.info{ "Activated study #{id} '#{study.name}' at #{study.last_activated_at}"}
  end
end
