module Doorkeeper
  class ApplicationAccessPolicy
    # Contains all the rules for which requestors can do what with which Doorkeeper::Application objects.
    def self.action_allowed?(action, requestor, application)
      return false unless requestor.is_human? # No applications
      case action
      when :index, :create, :read, :update, :destroy # Administrators only
        !!requestor.administrator
      else
        false
      end
    end
  end
end
