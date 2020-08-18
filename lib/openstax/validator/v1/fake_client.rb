class OpenStax::Validator::V1::FakeClient
  def initialize(validator_configuration)
  end

  def server_url
    'https://validator.fake.openstax.org'
  end

  def timeout
    0.seconds
  end

  def uri_for(path)
    Addressable::URI.join server_url, path.to_s
  end

  def upload_ecosystem_manifest(ecosystem_or_manifest)
    { 'msg' => 'Ecosystem successfully imported' }
  end
end
