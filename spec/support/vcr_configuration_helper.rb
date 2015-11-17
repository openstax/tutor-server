module VcrConfigurationHelper
  def set_vcr_config_around(group, config = {})
    before(group) do
      config.each do |k, v|
        instance_variable_set("@previous_#{k}", VcrConfiguration.current_config(k))
        VCR.configure { |c| c.send("#{k}=", v) }
      end
    end

    after(group) do
      VCR.configure do |c|
        config.each { |k, _| c.send("#{k}=", instance_variable_get("@previous_#{k}")) }
      end
    end
  end

  class VcrConfiguration
    def self.current_config(key)
      case key.to_sym
      when :ignore_localhost
        VCR.request_ignorer.instance_variable_get('@ignored_hosts').include?('localhost')
      end
    end
  end
end
