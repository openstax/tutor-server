require 'aws-sdk-s3'
require 'active_storage/service/s3_service'
require 'active_support/core_ext/numeric/bytes'

# A custom S3 service that supports storing files in a configured path inside the bucket
# https://github.com/rails/rails/issues/32790#issuecomment-487523740
module ActiveStorage
  class Service::TutorS3Service < Service::S3Service
    attr_reader :client, :bucket, :path, :upload_options

    def initialize(bucket:, upload: {}, **options)
      bucket_parts = bucket.split('/')
      bucket_name = bucket_parts.shift
      @path = bucket_parts.join('/')
      super(bucket: bucket_name, upload: upload, **options)
    end
  end
end

ActiveStorage::Blob.class_exec do
  # Returns the key pointing to the file on the service that's associated with this blob. The key is the
  # secure-token format from Rails in lower case. So it'll look like: xtapjjcjiudrlk3tmwyjgpuobabd.
  # This key is not intended to be revealed directly to the user.
  # Always refer to blobs using the signed_id or a verified form of the key.
  def key
    return self[:key] unless self[:key].nil?

    path = service.respond_to?(:path) ? "#{service.path}/" : ''

    # We can't wait until the record is first saved to have a key for it
    # Rails 6: self[:key] = path + self.class.generate_unique_secure_token(
    #            length: MINIMUM_TOKEN_LENGTH
    #          )
    self[:key] = path + self.class.generate_unique_secure_token
  end
end
