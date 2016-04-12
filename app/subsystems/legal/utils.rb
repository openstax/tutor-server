module Legal::Utils

  def self.gid(object)
    object.to_global_id.to_s
  end

  def self.available_contract_names
    FinePrint::Contract.published.map(&:name).uniq
  end

end
