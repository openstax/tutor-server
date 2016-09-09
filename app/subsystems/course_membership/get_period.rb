class CourseMembership::GetPeriod
  lev_routine express_output: :period

  protected

  def exec(id: nil, enrollment_code: nil)
    model = if id.present?
      CourseMembership::Models::Period.with_deleted.preload(:course).find(id)
    elsif enrollment_code.present?
      enrollment_code = enrollment_code.gsub(/-/,' ') # for codes from URLs
      CourseMembership::Models::Period.with_deleted.find_by(enrollment_code: enrollment_code)
    else
      raise IllegalArgument, "One of `id` or `enrollment_code` must be given."
    end

    outputs.period = model.nil? ? nil : CourseMembership::Period.new(strategy: model.wrap)
  end
end
