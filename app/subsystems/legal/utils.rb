module Legal::Utils

  def self.gid(object)
    object.to_global_id.to_s
  end

end
