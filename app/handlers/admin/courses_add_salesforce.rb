class Admin::CoursesAddSalesforce
  lev_handler

  paramify :add_salesforce do
    attribute :salesforce_id, type: String
    validates :salesforce_id, presence: true
  end

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    course = CourseProfile::Models::Course.find(params[:id])

    sf_object = get_salesforce_object_for_id(add_salesforce_params.salesforce_id)
    fatal_error(code: :salesforce_object_does_not_exist) if sf_object.nil?

    new_ar = Salesforce::Models::AttachedRecord.without_deleted.find_or_initialize_by(
      tutor_gid: course.to_global_id.to_s,
      salesforce_class_name: sf_object.class.name,
      salesforce_id: sf_object.id
    )

    fatal_error(code: :course_and_salesforce_object_already_attached) if new_ar.persisted?

    new_ar.save

    transfer_errors_from(new_ar, {type: :verbatim}, true)
  end

  def get_salesforce_object_for_id(id)
    # An OsAncillary
    get_os_ancillary_for_id(id)
  end

  def get_os_ancillary_for_id(id)
    begin
      OpenStax::Salesforce::Remote::OsAncillary.find(id)
    rescue Faraday::ClientError => e
      nil
    end
  end

end
