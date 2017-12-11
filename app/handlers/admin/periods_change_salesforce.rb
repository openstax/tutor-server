class Admin::PeriodsChangeSalesforce
  lev_handler

  paramify :change_salesforce do
    attribute :salesforce_id, type: String
  end

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    # Regardless of whether we're adding or removing SF info to a period, don't
    # worry about updating stats, they'll update on the next manual or cron run.

    if change_salesforce_params.salesforce_id.blank?
      remove_salesforce
    else
      add_salesforce
    end
  end

  def remove_salesforce
    existing = existing_period_ar
    return if existing.nil?
    existing.destroy
    transfer_errors_from(existing, {type: :verbatim}, true)
  end

  def add_salesforce
    # Make sure that the incoming SF ID is already attached to this period's course

    fatal_error(code: :can_only_use_course_salesforce_ids_for_periods) if matching_course_ar.nil?

    # Find existing period AR, there should be one or there could be none if this
    # period hasn't had an AR yet (in which case, initialize one)

    period_ar = existing_period_ar ||
                Salesforce::Models::AttachedRecord.new(tutor_gid: period.to_global_id.to_s)

    # Update that AR to point to the new SF object; can copy the class from the
    # course AR so we don't have to query SF to figure it out.

    period_ar.update_attributes(
      salesforce_class_name: matching_course_ar.salesforce_class_name,
      salesforce_id: change_salesforce_params.salesforce_id
    )

    transfer_errors_from(period_ar, {type: :verbatim}, true)
  end

  def matching_course_ar
    @matching_course_ar ||= begin
      course = period.course

      Salesforce::Models::AttachedRecord.without_deleted.where(
        tutor_gid: course.to_global_id.to_s,
        salesforce_id: change_salesforce_params.salesforce_id
      ).first
    end
  end

  def existing_period_ar
    # Find existing period AR, there should be one or there could be none if this
    # period hasn't had an AR yet (in which case, initialize one)

    period_ars = Salesforce::Models::AttachedRecord.where(
      tutor_gid: period.to_global_id.to_s
    ).all

    fatal_error(code: :found_unexpected_period_attached_salesforce_records) if period_ars.many?

    period_ars.first
  end

  def period
    @period ||= CourseMembership::Models::Period.find(params[:id])
  end

end
