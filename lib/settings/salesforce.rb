module Settings
  module Salesforce

    class << self

      def active_onboarding_salesforce_campaign_id
        Settings::Db.store.active_onboarding_salesforce_campaign_id
      end

      def active_nomad_onboarding_salesforce_campaign_id
        Settings::Db.store.active_nomad_onboarding_salesforce_campaign_id
      end

    end

  end
end
