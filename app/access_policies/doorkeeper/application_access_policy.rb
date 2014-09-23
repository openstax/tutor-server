module Doorkeeper
  class ApplicationAccessPolicy
    # Contains all the rules for which requestors can do what with which Doorkeeper::Application objects.
    def self.action_allowed?(action, requestor, application)
      case action
      when :read, :update, :destroy
        application.owner.has_member?(requestor) || requestor.administrator
      when :create
        requestor.administrator
      else
        false
      end
    end
  end
end
