class Admin::CoursesRemoveSalesforce
  lev_handler

  paramify :remove_salesforce do
    attribute :salesforce_id, type: String
    validates :salesforce_id, presence: true
  end

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    course = Entity::Course.find(params[:id])

    # Find the attached records for this course and periods that match
    # the provided SF ID
    course_and_period_gids = [course, course.periods].flatten
                                                     .compact
                                                     .map(&:to_global_id)
                                                     .map(&:to_s)

    existing_ars = Salesforce::Models::AttachedRecord.where(
      tutor_gid: course_and_period_gids,
      salesforce_id: remove_salesforce_params.salesforce_id
    ).all

    fatal_error(code: :no_salesforce_matches_for_this_course) if existing_ars.none?

    # All have the same SF object, so just pull from one
    sf_object = existing_ars.first.salesforce_object

    # Get rid of all the attached records
    existing_ars.each do |existing_ar|
      existing_ar.destroy
      transfer_errors_from(existing_ar, {type: :verbatim}, true)
    end

    # If that all went well, zero the stats on the SF object
    sf_object.reset_stats
    fatal_error(code: :could_not_clear_salesforce_stats) if !sf_object.save
  end

end
