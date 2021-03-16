HOMEPAGE_CONFIG = (YAML.load_file("config/homepage/home.yml") || {}).deep_symbolize_keys
