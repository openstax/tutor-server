class GenerateToken
  def self.apply(record:, attribute:, mode: :hex)
    begin
      record[attribute] = SecureRandom.send(mode)
    end while record.class.exists?(attribute => record[attribute])
  end

  def self.apply!(record:, attribute:, mode: :hex)
    apply(record: record, attribute: attribute, mode: mode)
    record.save!
  end
end
