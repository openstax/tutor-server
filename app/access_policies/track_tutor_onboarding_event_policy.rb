class TrackTutorOnboardingEventPolicy

  TEACHER_EVENTS = %w{
    arrived_my_courses created_preview_course created_real_course
    like_preview_ask_later like_preview_yes made_adoption_decision
  }
  def self.action_allowed?(event, requestor, force)
    return false if requestor.is_anonymous? || requestor.account.student?

    TEACHER_EVENTS.include?(event)
  end

end
