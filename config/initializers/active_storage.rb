Rails.application.config.after_initialize do
  ActiveStorage::Blob.class_exec do
    # Rails 6:
    # To prevent problems with case-insensitive filesystems, especially in combination
    # with databases which treat indices as case-sensitive, all blob keys generated are going
    # to only contain the base-36 character alphabet and will therefore be lowercase. To maintain
    # the same or higher amount of entropy as in the base-58 encoding used by `has_secure_token`
    # the number of bytes used is increased to 28 from the standard 24
    # def self.generate_unique_secure_token(length: ActiveStorage::Blob::MINIMUM_TOKEN_LENGTH)
    #   "#{Rails.application.secrets.environment_name}/#{SecureRandom.base36(length)}"
    # end
    def self.generate_unique_secure_token
      "#{Rails.application.secrets.environment_name}/#{SecureRandom.base58(28)}"
    end
  end
end
