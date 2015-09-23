class EcosystemAccessPolicy
  def self.action_allowed?(action, requestor, ecosystem)
    return false unless requestor.is_human?

    # Content Analysts can read all things content
    return true if requestor.is_content_analyst?

    case action
    when :readings
      # readings should be readable by course teachers and students
      # because FE uses it for the reference view
      courses = GetUserCourses[user: requestor.user]
      courses.any?{ |course| course.ecosystems.collect(&:id).include?(ecosystem.id) }
    when :exercises
      # exercises should be readable by course teachers only
      # because it includes solutions, etc
      courses = GetUserCourses[user: requestor.user, types: :teacher]
      courses.any?{ |course| course.ecosystems.collect(&:id).include?(ecosystem.id) }
    else
      false
    end
  end
end
