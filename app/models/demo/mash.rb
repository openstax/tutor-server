# A Hashie::Mash that works as a Rails form model
class Demo::Mash < Hashie::Mash
  # Prevent Rails from thinking this object accepts nested attributes
  def respond_to_missing?(method_name, *args)
    return false if method_name.to_s.ends_with?('_attributes=')

    super
  end

  # This object is not yet saved
  def persisted?
    false
  end

  # This object should produce inputs with [] in the form name (arrays of new records)
  def to_param
    ''
  end

  # Same as above
  def model_name
    self.class.new param_key: to_param
  end

  # This object does not represent extractable options
  def extractable_options?
    false
  end
end
