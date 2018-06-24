class Research::ActivateStudy
  lev_routine

  def exec(study)
    study.update_attribute(last_activated_at, Time.current)
    transfer_errors_from(study, {type: :verbatim}, true)

    # ...

    Rails.logger.info{ "Activated study #{id} '#{name}' at #{last_activated_at}"}
  end
end
