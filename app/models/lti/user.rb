class Lti::User < ApplicationRecord
  # LTI context roles allowed to pair courses and become instructors
  INSTRUCTOR_ROLES = [ 'Instructor', 'Administrator', 'ContentDeveloper', 'Mentor' ]

  # LTI context roles allowed to enroll into courses as students
  STUDENT_ROLES = [ 'Learner' ]

  belongs_to :profile, subsystem: :user, optional: true, inverse_of: :lti_users
  belongs_to :platform, inverse_of: :users

  validates :uid, presence: true, uniqueness: { scope: :lti_platform_id }
  validates :last_context_id, presence: true
  validates :last_is_instructor, inclusion: { in: [ true, false ] }
  validates :last_is_student, inclusion: { in: [ true, false ] }
  validates :last_target_link_uri, presence: true

  # Stores the last LTI launch request in the Lti::User record
  # On error, returns an error code to be displayed
  def set_launch_info_from_lti_auth(lti_auth)
    raw_info = lti_auth.extra.raw_info
    roles = raw_info['https://purl.imsglobal.org/spec/lti/claim/roles']
    return :missing_roles if roles.nil?

    context_roles ||= roles.select do |role|
      role.starts_with? 'http://purl.imsglobal.org/vocab/lis/v2/membership#'
    end.map { |role| role.sub('http://purl.imsglobal.org/vocab/lis/v2/membership#', '') }

    # These are used in error messages so we try to set them as early as possible
    self.last_is_instructor = !(INSTRUCTOR_ROLES & context_roles).empty?
    self.last_is_student = !(STUDENT_ROLES & context_roles).empty?

    # Fail for anonymous launches since we need to pass back grades
    # and anonymous launches do not give us a user ID
    return :anonymous_launch if lti_auth.uid.nil?

    self.last_message_type = raw_info['https://purl.imsglobal.org/spec/lti/claim/message_type']
    return :unsupported_message_type unless last_message_type == 'LtiResourceLinkRequest'

    self.last_context_id = raw_info['https://purl.imsglobal.org/spec/lti/claim/context']&.[]('id')
    return :missing_context if last_context_id.blank?

    return :no_valid_roles unless last_is_instructor || last_is_student

    self.last_target_link_uri = raw_info[
      'https://purl.imsglobal.org/spec/lti/claim/target_link_uri'
    ]
    return :missing_target_link_uri if last_target_link_uri.blank?

    nil
  end

  # If this returns true, we display simplified error messages,
  # usually something like "contact your instructor".
  def is_definitely_student?
    last_is_student && !last_is_instructor
  end
end
