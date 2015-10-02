module User
  class SetCustomerServiceState
    lev_routine

    protected

    def exec(user:, customer_service: false)
      return if (customer_service && user.is_customer_service?) || \
                (!customer_service && !user.is_customer_service?)

      profile = user.to_model
      customer_service ? profile.create_customer_service! : profile.customer_service.destroy
    end
  end
end
