require 'rails_helper'
require './lib/deploy_utils'

RSpec.describe DeployUtils do
  describe '.server_nickname' do
    it 'bases the nickname from url cname parts after tutor-' do
      Rails.application.secrets.mail_site_url = 'tutor-test.openstax.org'
      expect(DeployUtils.server_nickname).to eq('test')

      Rails.application.secrets.mail_site_url = 'tutor-multi-word-cname.openstax.org'
      expect(DeployUtils.server_nickname).to eq('multi word cname')
    end

    it 'recognizes production' do
      Rails.application.secrets.mail_site_url = 'tutor.openstax.org'
      expect(DeployUtils.server_nickname).to eq('production')
    end

    it 'fallsback to non-conventional urls' do
      Rails.application.secrets.mail_site_url = 'something-wild.com'
      expect(DeployUtils.server_nickname).to eq('something-wild.com')
    end
  end
end

