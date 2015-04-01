module VerifyAndGetIdArray
  def verify_and_get_id_array(values, required_type_if_object=nil)
    values = [values].flatten.compact
    return [] if values.blank?

    first_value = values.first

    return values if first_value.is_a?(Integer)

    if required_type_if_object.present? &&
       !first_value.is_a?(required_type_if_object)
      raise "The provided values are expected to have type '#{required_type_if_object} " +
            "but has type #{first_value.class}"
    end

    values.collect{|value| value.id}
  end
end
