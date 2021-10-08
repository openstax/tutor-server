HOMEPAGE_CONFIG = (YAML.load_file("config/homepage/home.yml") || {}).deep_symbolize_keys
PARDOT_CONFIG = {
  sandbox: {
    piAId: '309222',
    piCId: '1943',
    piHostname: 'pi.demo.pardot.com'
  },
  production: {
    piAId: '219812',
    piCId: '1120',
    piHostname: 'pi.pardot.com'
  }
}[IAm.real_production? ? :production : :sandbox]
