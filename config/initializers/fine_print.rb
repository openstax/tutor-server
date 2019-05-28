FinePrint.configure do |config|

  # Engine Configuration: Must be set in an initializer

  # Layout to be used for FinePrint's controllers
  # Default: 'application'
  config.layout = 'application'

  # Array of custom helpers for FinePrint's controllers
  # Default: [] (no custom helpers)
  config.helpers = [::ApplicationHelper, OpenStax::Utilities::OsuHelper]

  # Proc called with a controller as self. Returns the current user.
  # Default: lambda { current_user }
  config.current_user_proc = lambda {
    # FinePrint does not understand how to read/write contract signatures for wrappers
    current_user.to_model
  }

  # Proc called with a user as argument and a controller as self.
  # This proc is called when a user tries to access FinePrint's controllers.
  # Should raise and exception, render or redirect unless the user is a manager
  # or admin. Contract managers can create and edit agreements and terminate
  # accepted agreements. The default renders 403 Forbidden for all users.
  # Note: Proc must account for nil users, if current_user_proc returns nil.
  # Default: lambda { |user| head(:forbidden) }
  config.authenticate_manager_proc = lambda { |user| !!user.administrator || head(:forbidden) }

  # Proc called with a user as argument and a controller as self.
  # This proc is called before FinePrint determines if contracts need to be
  # signed. If it returns true, FinePrint will proceed with its checks and
  # potentially call the redirect_to_contracts_proc with the user as argument.
  # If it returns false, renders or redirects, FinePrint will stop its checks.
  # Note that returning false will allow the user to proceed without signing
  # contracts, unless another before_action renders or redirects (to a login
  # page, for example). The default renders 401 Unauthorized for nil users and
  # checks all others for contracts to be signed.
  # Default: lambda { |user| !user.nil? || head(:unauthorized) }
  config.authenticate_user_proc = lambda { |user|
    user.class == ::User::Models::Profile || authenticate_user!
  }

  # Controller Configuration
  # Can be set in this initializer or passed as options to `fine_print_require`

  # Proc called with a user and an array of contracts as arguments and a
  # controller as self. This proc is called when a user tries to access a
  # resource protected by FinePrint, but has not signed all the required
  # contracts. Should redirect the user, render or raise an exception.
  # The `contracts` argument contains the contracts that need to be signed.
  # The default redirects users to FinePrint's contract signing views.
  # The `fine_print_return` method can be used to return from this redirect.
  # Default: lambda { |user, contracts|
  #            redirect_to(fine_print.new_contract_signature_path(
  #              contract_id: contracts.first.id
  #            ))
  #          }
  config.redirect_to_contracts_proc = lambda do |user, contracts|
    respond_to do |format|
      format.html do
        redirect_to(pose_terms_path(
          id: contracts.first.id
        ))
      end

      format.json do
        render(
          status: :unauthorized,
          json: {
            'errors' => [{
              'status' => 401,
              'message' => 'You must accept the user agreements to continue',
              'data' => { 'term_ids' => contract_ids }
            }]
          }
        )
      end
    end
  end

end
