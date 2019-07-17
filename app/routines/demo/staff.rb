# Creates the admin, content, support and zz users
class Demo::Staff < Demo::Base

  lev_routine

  uses_routine User::SetAdministratorState, as: :set_administrator
  uses_routine User::SetContentAnalystState, as: :set_content_analyst
  uses_routine User::SetCustomerServiceState, as: :set_customer_service
  uses_routine User::SetResearcherState, as: :set_researcher

  protected

  def exec
    administrators.each do |admin_username, admin_name|
      admin_user = find_or_create_user_by_username(admin_username, name: admin_name)
      run(:set_administrator, user: admin_user, administrator: true)
      run(:set_content_analyst, user: admin_user, content_analyst: true)
      run(:set_customer_service, user: admin_user, customer_service: true)
      log { "Admin: #{admin_username}" }
    end

    content_analysts.each do |ca_username, ca_name|
      ca_user = find_or_create_user_by_username(ca_username, name: ca_name)
      run(:set_content_analyst, user: ca_user, content_analyst: true)
      log { "Content Analyst: #{ca_username}" }
    end

    customer_support.each do |cs_username, cs_name|
      cs_user = find_or_create_user_by_username(cs_username, name: cs_name)
      run(:set_customer_service, user: cs_user, customer_service: true)
      log { "Customer Support: #{cs_username}" }
    end

    researchers.each do |rr_username, rr_name|
      rr_user = find_or_create_user_by_username(rr_username, name: rr_name)
      run(:set_researcher, user: rr_user, researcher: true)
      log { "Researcher: #{rr_username}" }
    end

    zz_usernames = (0..99).map { |ii| "zz_#{ii.to_s.rjust(2, "0")}" }
    existing_zz_usernames = OpenStax::Accounts::Account.where(username: zz_usernames)
                                                       .pluck(:username)
    missing_zz_usernames = zz_usernames - existing_zz_usernames
    missing_zz_usernames.each do |zz_username|
      new_user(username: zz_username, name: zz_username.gsub('_', ' '))
    end
    log do
      "Made #{missing_zz_usernames.size} extra 'zz' users who are not in any course."
    end unless missing_zz_usernames.empty?
  end

  def administrators
    @admins ||= Hashie::Mash.load(
      File.join(CONFIG_BASE_DIR, "people/staff/administrators.yml")
    )
  end

  def content_analysts
    @content_analysts ||= Hashie::Mash.load(
      File.join(CONFIG_BASE_DIR, "people/staff/content_analysts.yml")
    )
  end

  def customer_support
    @customer_support ||= Hashie::Mash.load(
      File.join(CONFIG_BASE_DIR, "people/staff/customer_support.yml")
    )
  end

  def researchers
    @researchers ||= Hashie::Mash.load(
      File.join(CONFIG_BASE_DIR, "people/staff/researchers.yml")
    )
  end
end
