class JobAccessPolicy
  def self.action_allowed?(action, requestor, task)
    return false unless requestor.is_human?

    case action
    when :index
      !!requestor.administrator
    else
      false
    end
  end
end
