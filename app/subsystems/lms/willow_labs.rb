class Lms::WillowLabs

  ID = 'willow_labs'

  def self.find_by(key:)
    config['key'] == key ? self.new : nil
  end

  def id
    nil
  end

  def self.config
    Rails.application.secrets.dig(:lms, ID) || {}
  end

  def secret
    self.class.config['secret']
  end

end
