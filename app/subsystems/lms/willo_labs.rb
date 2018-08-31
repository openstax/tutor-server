class Lms::WilloLabs

  ID = 'willo_labs'

  def self.find_by(key:)
    config['key'] == key ? self.new : nil
  end

  def id
    nil
  end

  def owner
    nil
  end

  def self.config
    Rails.application.secrets.dig(:lms, ID) || {}
  end

  def key
    self.class.config['key']
  end

  def secret
    self.class.config['secret']
  end

end
