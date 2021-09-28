class Lti::ResourceLink < ApplicationRecord
  belongs_to :platform, inverse_of: :resource_links

  validates :resource_link_id, presence: true,
                               uniqueness: { scope: [ :lti_platform_id, :context_id ] }
  validates :can_create_lineitems, inclusion: { in: [ true, false ] }
  validates :can_update_scores, inclusion: { in: [ true, false ] }

  def self.upsert_from_platform_and_raw_info(platform, raw_info)
    context_id = raw_info['https://purl.imsglobal.org/spec/lti/claim/context']&.[]('id')
    return :missing_context if context_id.blank?

    resource_link_id = raw_info['https://purl.imsglobal.org/spec/lti/claim/resource_link']&.[]('id')
    return :missing_resource_link if resource_link_id.blank?

    endpoint = raw_info['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint']
    return :missing_endpoint if endpoint.blank?

    scope = endpoint['scope']
    return :missing_scope if scope.nil?

    lineitems = endpoint['lineitems']
    can_create_lineitems = !lineitems.blank? &&
      scope.include?('https://purl.imsglobal.org/spec/lti-ags/scope/lineitem')
    can_update_scores = scope.include? 'https://purl.imsglobal.org/spec/lti-ags/scope/score'

    import [
      new(
        platform: platform,
        context_id: context_id,
        resource_link_id: resource_link_id,
        can_create_lineitems: can_create_lineitems,
        can_update_scores: can_update_scores,
        lineitems_endpoint: lineitems,
        lineitem_endpoint: endpoint['lineitem']
      )
    ], validate: false, on_duplicate_key_update: {
      conflict_target: [ :lti_platform_id, :context_id, :resource_link_id ], columns: [
        :can_create_lineitems, :can_update_scores, :lineitems_endpoint, :lineitem_endpoint
      ]
    }

    nil
  end

  def scope
    return [] unless can_update_scores?

    [].tap do |scopes|
      scopes << 'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem' if can_create_lineitems
      scopes << 'https://purl.imsglobal.org/spec/lti-ags/scope/score'
    end
  end

  def access_token
    return unless can_update_scores?

    @access_token ||= OAuth2::Client.new(
      '',
      '',
      token_url: platform.token_endpoint,
      auth_scheme: :private_key_jwt
    ).get_token(
      grant_type: 'client_credentials',
      client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      client_assertion: platform.jwt_token.to_s,
      scope: scope.join(' ')
    )
  end

  def lineitems
    @lineitems ||= JSON.parse(access_token.get(lineitems_endpoint).body).map do |lineitem_hash|
      Lti::Lineitem.new lineitem_hash
    end
  end

  def lineitem
    @lineitem ||= Lti::Lineitem.new JSON.parse(access_token.get(lineitem_endpoint).body)
  end
end
