require 'ims/lis'

FactoryGirl.define do
  factory :launch_request, class: OpenStruct do
    user_id { SecureRandom.hex(10) }
    full_name { Faker::Name.name }
    outcome_url nil
    result_sourcedid nil
    signature { 'not-real-sig'}
    nonce { SecureRandom.hex(10)}
    request_url { Faker::Internet.url }
    roles {[:student]}
    tool_consumer_instance_guid { SecureRandom.uuid }
    context_id { SecureRandom.uuid }

    transient do
      app nil
    end

    trait :assignment do
      outcome_url { Faker::Internet.url }
      result_sourcedid { SecureRandom.hex(10) }
    end

    initialize_with {
      raise "`app` must be defined" if app.nil?

      roles = ([self.roles].flatten.compact).uniq.map(&:to_sym).map{|rr| ROLES[rr]}

      raise "Encountered an unknown role" if roles.any?{|rr| rr.nil?}

      new(
        request_parameters: {
          user_id: user_id,
          lis_person_name_full: full_name,
          lis_outcome_service_url: outcome_url,
          lis_result_sourcedid: result_sourcedid,
          oauth_signature: signature,
          oauth_nonce: nonce,
          oauth_consumer_key: app.key,
          roles: roles.join(','),
          tool_consumer_instance_guid: tool_consumer_instance_guid,
          lti_message_type: "basic-lti-launch-request",
          context_id: context_id
        }.compact,
        request_url: request_url
      )
    }

    ROLES = {
      student: IMS::LIS::Roles::Context::URNs::Learner,
      instructor: IMS::LIS::Roles::Context::URNs::Instructor,
      administrator: IMS::LIS::Roles::Context::URNs::Administrator
    }
  end
end
