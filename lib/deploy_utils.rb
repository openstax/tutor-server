class DeployUtils
  def self.server_nickname
    url = Rails.application.secrets.mail_site_url
    match = url.match(/\Atutor-(.+)\.openstax/)

    return 'production' if url == 'tutor.openstax.org'

    if match && match[1]
      match[1].gsub('-', ' ')
    else
      url
    end
  end
end
