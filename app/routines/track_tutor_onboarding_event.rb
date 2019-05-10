class TrackTutorOnboardingEvent

  lev_routine express_output: :campaign_member

  class InstantFailStandardError < StandardError
    def instantly_fail_if_in_background_job?; true; end
  end

  class MissingArgument < InstantFailStandardError; end
  class CannotTrackOnboardingUser < InstantFailStandardError; end
  class MissingOnboardingCampaignId < InstantFailStandardError; end

protected

  # typing shortcut
  CM = OpenStax::Salesforce::Remote::CampaignMember

  def exec(event:, user:, data: {})
    return if EnvUtilities.load_boolean(name: 'DO_NOT_TRACK_TUTOR_ONBOARDING', default: false) ||
              user.respond_to?(:is_test) && user.is_test

    begin

      cm = nil

      case event.to_sym
      when :arrived_tutor_marketing_page_from_pardot
        # Deprecated event, no longer handling
        return
      when :arrived_tutor_marketing_page_not_from_pardot
        # Deprecated event, no longer handling
        return
      when :arrived_my_courses
        return if user.salesforce_contact_id.blank? # no use if sf ID blank, which may happen
        cm = find_or_initialize_campaign_member(user: user)
        cm.first_arrived_my_courses_at ||= DateTime.current
      when :created_preview_course
        cm = find_or_initialize_campaign_member(user: user)
        cm.preview_created_at ||= DateTime.current
      when :created_real_course
        cm = find_or_initialize_campaign_member(user: user)
        cm.real_course_created_at ||= DateTime.current
      when :like_preview_ask_later
        cm = find_or_initialize_campaign_member(user: user)
        cm.like_preview_ask_later_count ||= 0
        cm.like_preview_ask_later_count += 1
      when :like_preview_yes
        cm = find_or_initialize_campaign_member(user: user)
        cm.like_preview_yes_at ||= DateTime.current
      when :made_adoption_decision
        raise(MissingArgument, "decision") if data[:decision].blank?

        cm = find_or_initialize_campaign_member(user: user)
        cm.latest_adoption_decision_at = DateTime.current
        cm.latest_adoption_decision = data[:decision]

        course = get_course(data)
        course.latest_adoption_decision = data[:decision]
        course.save!
      else
        raise InstantFailStandardError, "unknown tutor onboarding event: #{event}"
      end

      cm.save_if_changed

      if cm.errors.any?
        raise "Could not save CampaignMember #{cm.errors.full_messages}, user: #{user.uuid}, data: #{data}"
      end

      outputs.campaign_member = cm

      if event.to_sym == :created_real_course
        # Save the CampaignMember ID in the course so it gets sent to Salesforce
        # in the daily stats update; have to do this after `cm.save_if_changed`
        # because if the CM is new it won't have an ID yet.

        course = get_course(data)
        course.creator_campaign_member_id = cm.id
        course.save!
      end

    rescue CannotTrackOnboardingUser => ee
      log(:error) { "Cannot get CampaignMember for #{event} event because '#{ee.message}'" }
      raise
    rescue MissingArgument => ee
      raise(MissingArgument, "Missing the `#{ee.message}` argument for event #{event}")
    rescue OpenStax::Salesforce::UserMissing => ee
      log(:error) { "Cannot track onboarding event because Salesforce user not set" }
      raise if Settings::Db.raise_if_salesforce_user_missing
    end
  end

  def get_course(data)
    raise(MissingArgument, "course_id") if data[:course_id].blank?
    CourseProfile::Models::Course.find(data[:course_id])
  end

  def find_or_initialize_campaign_member(user:)
    # Users we have been marketing to should already have a `CampaignMember` record
    # by the time they get to this tracking code.  So our first attempt is to
    # search for an existing CampaignMember by the active campaign ID and the user's
    # SF contact ID.  If it doesn't exist, this user is someone who likely just
    # happened upon Tutor, and our approach is to bundle them under a "nomad"
    # campaign, whose ID we also have in our admin settings.  For these users we
    # create a new CampaignMember.

    raise(CannotTrackOnboardingUser, "user is anonymous") if user.is_anonymous?

    sf_contact_id = user.salesforce_contact_id
    raise(
      CannotTrackOnboardingUser,
      "user #{user.id} has no SF contact ID and is not marked as a test user"
    ) if sf_contact_id.blank?

    onboarding_campaign_id = Settings::Salesforce.active_onboarding_salesforce_campaign_id
    raise(MissingOnboardingCampaignId, "active campaign") if onboarding_campaign_id.blank?

    cm = CM.find_by(contact_id: sf_contact_id, campaign_id: onboarding_campaign_id)

    if cm.nil?
      nomad_onboarding_campaign_id = Settings::Salesforce.active_nomad_onboarding_salesforce_campaign_id
      raise(MissingOnboardingCampaignId, "nomad campaign") if nomad_onboarding_campaign_id.blank?

      cm = CM.find_or_initialize_by(contact_id: sf_contact_id, campaign_id: nomad_onboarding_campaign_id)
    end

    cm.first_teacher_contact_id ||= user.salesforce_contact_id
    cm.accounts_uuid ||= require_and_return_uuid!(user)

    cm
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
