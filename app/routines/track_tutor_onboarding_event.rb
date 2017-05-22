class TrackTutorOnboardingEvent

  lev_routine express_output: :tutor_onboarding_a

  class InstantFailStandardError < StandardError
    def instantly_fail_if_in_background_job?; true; end
  end

  class CannotGetToa < InstantFailStandardError; end
  class MissingArgument < InstantFailStandardError; end

protected

  # typing shortcut
  TOA = OpenStax::Salesforce::Remote::TutorOnboardingA

  def exec(event:, user:, data: {})
    begin

      toa = nil

      case event.to_sym
      when :arrived_tutor_marketing_page_from_pardot
        raise(MissingArgument, "pardot_reported_contact_id") if data[:pardot_reported_contact_id].blank?
        raise(MissingArgument, "pardot_reported_piaid") if data[:pardot_reported_piaid].blank?
        raise(MissingArgument, "pardot_reported_picid") if data[:pardot_reported_picid].blank?

        toa = find_or_initialize_toa(user: user, pardot_reported_contact_id: data[:pardot_reported_contact_id])

        toa.pardot_reported_piaid ||= data[:pardot_reported_piaid]
        toa.pardot_reported_picid ||= data[:pardot_reported_picid]
        toa.arrived_marketing_page_from_pardot_at ||= DateTime.current
      when :arrived_tutor_marketing_page_not_from_pardot
        toa = find_or_initialize_toa(user: user)
        toa.arrived_marketing_page_not_from_pardot_at ||= DateTime.current
      when :arrived_my_courses
        # Nothing to do, just want to make sure a record gets created
        toa = find_or_initialize_toa(user: user)
      when :created_preview_course
        toa = find_or_initialize_toa(user: user)
        toa.preview_created_at ||= DateTime.current
      when :created_real_course
        toa = find_or_initialize_toa(user: user)
        toa.real_course_created_at ||= DateTime.current
      when :like_preview_ask_later
        toa = find_or_initialize_toa(user: user)
        toa.like_preview_ask_later_count ||= 0
        toa.like_preview_ask_later_count += 1
      when :like_preview_yes
        toa = find_or_initialize_toa(user: user)
        toa.like_preview_yes_at ||= DateTime.current
      when :made_adoption_decision
        raise(MissingArgument, "decision") if data[:decision].blank?

        toa = find_or_initialize_toa(user: user)
        toa.latest_adoption_decision_at = DateTime.current
        toa.latest_adoption_decision = data[:decision]
      else
        raise InstantFailStandardError, "unknown tutor onboarding event: #{event}"
      end

      toa.save_if_changed

      if toa.errors.any?
        raise "Could not save TutorOnboardingA #{toa.errors.full_messages}, user: #{user.uuid}, data: #{data}"
      end

      outputs.tutor_onboarding_a = toa

    rescue CannotGetToa => ee
      log(:error) { "Cannot get TOA for #{event} event because '#{ee.message}'" }
      raise
    rescue MissingArgument => ee
      raise(MissingArgument, "Missing the `#{ee.message}` argument for event #{event}")
    end

  end


  def find_or_initialize_toa(user:, pardot_reported_contact_id: nil)
    if user.is_anonymous?
      if pardot_reported_contact_id.blank?
        raise CannotGetToa, "user is anonymous and no pardot SF contact ID given"
      else
        TOA.find_or_initialize_by(pardot_reported_contact_id: pardot_reported_contact_id)
      end
    else
      # Find in priority order by local SF contact ID, UUID, pardot Contact ID; if
      # not found, init by UUID.  Put Pardot ID later in priority because there is
      # a chance that the ID could be shared by people forwarding emails around, whereas
      # the local SF contact ID and UUID are more specific to one user. Then set missing
      # fields as needed.

      toa = TOA.find_by(first_teacher_contact_id: user.salesforce_contact_id) \
        if user.salesforce_contact_id.present?

      toa ||= TOA.find_by(accounts_uuid: user.uuid) if user.uuid.present?

      toa ||= TOA.find_by(pardot_reported_contact_id: pardot_reported_contact_id) \
        if pardot_reported_contact_id.present?

      toa ||= TOA.new(accounts_uuid: require_and_return_uuid!(user))

      # TODO think through / spec different cases (e.g. teacher forwards pardot email to colleage at different times)

      toa.first_teacher_contact_id ||= user.salesforce_contact_id
      toa.pardot_reported_contact_id ||= pardot_reported_contact_id
      toa.accounts_uuid ||= require_and_return_uuid!(user)

      toa
    end
  end

  def log(level, &block)
    Rails.logger.send(level) { "[OnboardingTracking] #{block.call}" }
  end

  def require_and_return_uuid!(user)
    if user.uuid.blank?
      raise IllegalState, "User #{user.id} does not have a UUID; sync with Accounts!"
    end

    user.uuid
  end

end
