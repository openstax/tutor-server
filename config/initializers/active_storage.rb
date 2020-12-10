ActiveStorage::Blob.class_exec do
  # Returns the key pointing to the file on the service that's associated with this blob. The key is the
  # secure-token format from Rails in lower case. So it'll look like: xtapjjcjiudrlk3tmwyjgpuobabd.
  # This key is not intended to be revealed directly to the user.
  # Always refer to blobs using the signed_id or a verified form of the key.
  def key
    # We can't wait until the record is first saved to have a key for it
    # Rails 6: self[:key] ||= "#{Rails.application.secrets.environment_name}/#{
    #            self.class.generate_unique_secure_token length: MINIMUM_TOKEN_LENGTH}"
    self[:key] ||= "#{Rails.application.secrets.environment_name}/#{
                     self.class.generate_unique_secure_token}"
  end
end
