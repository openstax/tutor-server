class GenerateToken
  def self.apply!(record, attribute)
    begin
      record[attribute] = SecureRandom.urlsafe_base64
    end while record.class.exists?(attribute => record[attribute])

    record.save!
  end
end
