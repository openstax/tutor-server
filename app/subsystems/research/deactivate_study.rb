class Research::DeactivateStudy
  lev_routine

  def exec(study)
    study.update_attribute(last_deactivated_at, Time.current)
    transfer_errors_from(study, {type: :verbatim}, true)

    # ...

    Rails.logger.info{ "Deactivated study #{id} '#{name}' at #{last_deactivated_at}"}
  end
end
