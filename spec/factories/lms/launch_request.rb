require 'ims/lis'

FactoryBot.define do
  factory :launch_request, class: OpenStruct do
    user_id { SecureRandom.hex(10) }
    full_name { Faker::Name.name }
    outcome_url { nil }
    result_sourcedid { nil }
    signature { 'not-real-sig'}
    nonce { SecureRandom.hex(10)}
    url { Faker::Internet.url }
    roles {[:student]}
    tool_consumer_instance_guid { SecureRandom.uuid }
    context_id { SecureRandom.uuid }

    transient do
      app          { nil }
      current_time { Time.current }
    end

    trait :assignment do
      outcome_url { Faker::Internet.url }
      result_sourcedid { SecureRandom.hex(10) }
    end

    initialize_with do
      raise "`app` must be defined" if app.nil?

      roles_map = {
        student: IMS::LIS::Roles::Context::URNs::Learner,
        instructor: IMS::LIS::Roles::Context::URNs::Instructor,
        administrator: IMS::LIS::Roles::Context::URNs::Administrator
      }
      roles = ([self.roles].flatten.compact).uniq.map(&:to_sym).map{|rr| roles_map[rr]}

      raise "Encountered an unknown role" if roles.any?(&:nil?)

      new(
        request_parameters: HashWithIndifferentAccess.new(
          user_id: user_id,
          lis_person_name_full: full_name,
          lis_outcome_service_url: outcome_url,
          lis_result_sourcedid: result_sourcedid,
          oauth_signature: signature,
          oauth_nonce: nonce,
          oauth_consumer_key: app.key,
          oauth_timestamp: current_time.to_i.to_s,
          roles: roles.join(','),
          tool_consumer_instance_guid: tool_consumer_instance_guid,
          lti_message_type: "basic-lti-launch-request",
          lti_version: 'LTI-1p0',
          context_id: context_id,
          resource_link_id: Faker::Internet.url,
        ).compact,
        url: url
      )
    end
  end
end
