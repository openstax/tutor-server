module User
  class SetCustomerSupportState
    lev_routine

    protected

    def exec(user:, customer_support: false)
      return if (customer_support && user.is_customer_support?) || \
                (!customer_support && !user.is_customer_support?)

      profile = user.to_model
      customer_support ? profile.create_customer_support! : profile.customer_support.destroy
    end
  end
end
