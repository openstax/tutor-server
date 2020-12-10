class ExportUploader < CarrierWave::Uploader::Base
  ALLOWED_EXTENSIONS = %w(xdoc doc pdf csv xls xlsx)

  def extension_white_list
    ALLOWED_EXTENSIONS
  end

  def content_hash
    Digest::SHA2.new.update(read).to_s
  end

  def cache_dir
    Rails.root.join 'tmp/exports'
  end

  def store_dir
    Rails.application.secrets.environment_name
  end

  def filename
    return if original_filename.blank?

    # Reuse hashed filename for other versions of the same file
    return model.read_attribute(mounted_as) unless version_name.blank?

    # Don't try to hash development files and uncached files
    return super if Rails.env.development? || !cached?

    "#{content_hash}.#{file.extension}"
  end

  def fog_attributes
    return super if original_filename.blank?

    super.merge('Content-Disposition' => "attachment; filename=\"#{original_filename}\"")
  end
end
