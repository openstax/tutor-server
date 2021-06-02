class OpenStax::Content::S3
  def initialize
    @ls = {}
  end

  def content_secrets
    Rails.application.secrets.openstax[:content]
  end

  def bucket_name
    content_secrets[:bucket_name]
  end

  def bucket_configured?
    !bucket_name.blank?
  end

  def client
    @client ||= Aws::S3::Client.new(
      region: content_secrets[:s3_region],
      access_key_id: content_secrets[:s3_access_key_id],
      secret_access_key: content_secrets[:s3_secret_access_key]
    )
  end

  def ls(archive_version = nil)
    return @ls[archive_version] unless @ls[archive_version].nil?
    return unless bucket_configured?

    archive_path = content_secrets[:archive_path].chomp('/')

    if archive_version.nil?
      prefix = "#{archive_path}/"
      delimiter = '/'
    else
      prefix = "#{archive_path}/#{archive_version}/contents/"
      delimiter = ':'
    end

    @ls[archive_version] = client.list_objects_v2(
      bucket: bucket_name, prefix: prefix, delimiter: delimiter
    ).flat_map(&:common_prefixes).map do |common_prefix|
      common_prefix.prefix.sub(prefix, '').chomp(delimiter)
    end
  end
end
