class SecretsGenerator < Rails::Generators::Base

  source_root File.expand_path('../templates', __FILE__)

  def generate_secrets
    template "secrets.yml.erb", "config/secrets.yml"
  end

end
