class EcosystemAccessPolicy
  def self.action_allowed?(action, requestor, ecosystem)
    return false unless requestor.is_human?

    # Admins can do all things content
    return true #if requestor.is_admin?

    case action
    when :index
      requestor.is_content_analyst?
    when :readings
      # readings should be readable by course teachers and students
      # because FE uses it for the reference view
      courses = GetUserCourses[user: requestor]
      courses.any? { |course| course.ecosystems.map(&:id).include?(ecosystem.id) }
    when :exercises
      # exercises should be readable by course teachers only
      # because it includes solutions, etc
      courses = GetUserCourses[user: requestor, types: :teacher]
      courses.any? { |course| course.ecosystems.map(&:id).include?(ecosystem.id) }
    else
      false
    end
  end
end
