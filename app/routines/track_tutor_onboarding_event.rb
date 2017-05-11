class TrackTutorOnboardingEvent

  lev_routine

  class CannotGetToa < StandardError
    def instantly_fail_if_in_background_job?; true; end
  end

  class MissingArgument < StandardError
    def instantly_fail_if_in_background_job?; true; end
  end

protected

  TOA = OpenStax::Salesforce::Remote::TutorOnboardingA

  def exec(event:, user:, data: {})
    begin

      toa = nil

      case event
      when :arrived_tutor_marketing_page_from_pardot
        raise(MissingArgument, "pardot_reported_contact_id") if data[:pardot_reported_contact_id].blank?
        raise(MissingArgument, "pardot_reported_piaid") if data[:pardot_reported_piaid].blank?
        raise(MissingArgument, "pardot_reported_picid") if data[:pardot_reported_picid].blank?

        toa = find_or_initialize_toa(user: user, pardot_reported_contact_id: data[:pardot_reported_contact_id])

        toa.pardot_reported_piaid ||= data[:pardot_reported_piaid]
        toa.pardot_reported_picid ||= data[:pardot_reported_picid]
        toa.arrived_marketing_page_from_pardot_at ||= Time.now # TODO spec doesn't overwrite this on 2nd arrival

      when :arrived_my_courses
        # Nothing to do, just want to make sure a record gets created
        toa = find_or_initialize_toa(user: user)
      when :created_preview_course
        toa = find_or_initialize_toa(user: user)
        toa.preview_created_at ||= Time.now
      when :created_real_course
        toa = find_or_initialize_toa(user: user)
        toa.real_course_created_at ||= Time.now
      when :like_preview_ask_later
        toa = find_or_initialize_toa(user: user)
        toa.like_preview_ask_later_count ||= 0
        toa.like_preview_ask_later_count += 1
      when :like_preview_yes
        toa = find_or_initialize_toa(user: user)
        toa.like_preview_yes_at ||= Time.now
      when :made_adoption_decision
        raise(MissingArgument, "decision") if data[:decision].blank?

        toa = find_or_initialize_toa(user: user)
        toa.latest_adoption_decision_at = Time.now
        toa.latest_adoption_decision = data[:decision]
      else
        raise "unknown tutor onboarding event: #{event}"
      end

      raise "TutorOnboardingA object not set for #{event} and user #{user.id}" if toa.nil?

      toa.save_if_changed

      if toa.errors.any?
        # TODO what to do? raise/log?
      end

    rescue CannotGetToa => ee
      log(:error) { "Cannot get TOA for #{event} event because '#{ee.message}'" }
      raise
    rescue MissingArgument => ee
      log(:error) { "Missing the `#{ee.message}` argument for event #{event}" }
      raise
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
      # Find in priority order by local SF contact ID, pardot Contact ID, UUID,
      # then set missing fields as needed.

      toa = TOA.find_by(first_teacher_contact_id: user.salesforce_contact_id) \
        if user.salesforce_contact_id.present?

      toa ||= TOA.find_by(pardot_reported_contact_id: pardot_reported_contact_id) \
        if pardot_reported_contact_id.present?

      toa ||= TOA.find_or_initialize_by(accounts_uuid: user.uuid)

      # TODO think through / spec different cases (e.g. teacher forwards pardot email to colleage at different times)

      toa.first_teacher_contact_id ||= user.salesforce_contact_id
      toa.pardot_reported_contact_id ||= pardot_reported_contact_id
      toa.accounts_uuid ||= user.uuid
    end
  end

  def log(level, &block)
    Rails.logger.send(level) { "[OnboardingTracking] #{block.call}" }
  end

end
