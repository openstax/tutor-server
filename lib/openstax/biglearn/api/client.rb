module OpenStax::Biglearn::Api::Client
  # Must be implemented by all clients so that sequentially_prepare_and_update_course_ecosystem
  # can be successfully called
  def prepare_course_ecosystem(request)
    raise NotImplementedError
  end

  # Executes prepare_course_ecosystem and update_course_ecosystems sequentially
  def sequentially_prepare_and_update_course_ecosystem(request)
    prepare_course_ecosystem(request)

    # Call OpenStax::Biglearn::Api to obtain a new sequence_number in a fresh background job
    OpenStax::Biglearn::Api.update_course_ecosystems request.slice(:course, :preparation_uuid)
  end
end
