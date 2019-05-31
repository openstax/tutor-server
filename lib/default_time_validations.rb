module DefaultTimeValidations

  protected

  def default_times_have_good_values
    %w(default_open_time default_due_time).each do |time_field|
      value = self.send(time_field)

      next if value.nil?

      match = value.match(/(\d\d):(\d\d)/)

      if match.nil?
        errors.add(time_field.to_sym, "is not of format '16:23'")
        next
      end

      if match[1].to_i > 23 || match[2].to_i > 59
        errors.add(time_field.to_sym, "has the right syntax but invalid time value")
      end
    end

    throw(:abort) if errors.any?
  end

end
