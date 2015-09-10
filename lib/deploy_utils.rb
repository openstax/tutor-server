class DeployUtils
  def self.server_nickname
    url = Rails.application.secrets.mail_site_url
    match = url.match(/\Atutor-(.+)\.openstax/)

    if match && match[1]
      match[1].gsub('-', ' ')
    elsif url == 'tutor.openstax.org'
      'production'
    else
      url
    end
  end
end
