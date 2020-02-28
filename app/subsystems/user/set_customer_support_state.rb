module User
  class SetCustomerSupportState
    lev_routine

    protected

    def exec(user:, customer_support: false)
      return if (customer_support && user.is_customer_support?) || \
                (!customer_support && !user.is_customer_support?)

      customer_support ? user.create_customer_support! : user.customer_support.destroy
    end
  end
end
