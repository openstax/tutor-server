module IAm
  def self.real_production?
    Rails.application.secrets.environment_name == "prodtutor"
  end
end
