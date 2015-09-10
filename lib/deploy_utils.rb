class DeployUtils
  def self.server_nickname
    url = Rails.application.secrets.mail_site_url || 'unknown deploy'

    if url == 'tutor.openstax.org'
      'production'
    else
      match = url.match(/\Atutor-(.+)\.openstax/)

      if match && match[1]
        match[1]
      else
        url
      end
    end
  end
end
