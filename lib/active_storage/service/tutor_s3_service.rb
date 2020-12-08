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
      @path = bucket_parts.empty? ? '' : bucket_parts.join('/')
      super(bucket: bucket_name, upload: upload, **options)
    end

    private

    def object_for(key)
      path = path.present? ? File.join(path, key) : key
      bucket.object(path)
    end
  end
end
