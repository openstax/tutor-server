# Creates the admin, content, support, researchers, teachers, students and zz demo users
class Demo::Users < Demo::Base
  lev_routine use_jobba: true

  uses_routine User::SetAdministratorState, as: :set_administrator
  uses_routine User::SetContentAnalystState, as: :set_content_analyst
  uses_routine User::SetCustomerSupportState, as: :set_customer_support
  uses_routine User::SetResearcherState, as: :set_researcher

  protected

  def sign_contract(user:, name:)
    string_name = name.to_s
    return unless FinePrint::Contract.where(name: string_name).exists?

    FinePrint.sign_contract(user.to_model, string_name)
  end

  def create_or_update_users(users, attributes = {})
    return [] if users.nil?

    usernames = users.map { |user| user[:username] }
    existing_users_by_username = User::Models::Profile
      .joins(:account)
      .where(account: { username: usernames })
      .preload(:account)
      .index_by(&:username)
    attributes = { is_test: true }.merge attributes

    outputs.users ||= []
    outputs.users += users.map do |user|
      model = existing_users_by_username[user[:username]]
      attrs = attributes.merge(user)

      if model.nil?
        attrs[:password] = Rails.application.secrets.demo_user_password if attrs[:password].blank?

        if attrs[:first_name].blank? || attrs[:last_name].blank?
          attrs[:full_name] = attrs[:username].split('_').map(&:capitalize).join(' ') \
            if attrs[:full_name].blank?

          attrs[:first_name], attrs[:last_name] = attrs[:full_name].split(' ', 2)
          raise "#{attrs[:full_name]} is not a full name" if attrs[:last_name].blank?
        elsif attrs[:full_name].blank?
          attrs[:full_name] = "#{attrs[:first_name]} #{attrs[:last_name]}"
        end

        sign_contracts = attrs.has_key?(:sign_contracts) ? attrs[:sign_contracts] : true

        # The password will be set if stubbing is disabled
        model = run(User::CreateUser, attrs.except(:sign_contracts)).outputs.user.tap do |user|
          next unless sign_contracts

          sign_contract(user: user, name: :general_terms_of_use)
          sign_contract(user: user, name: :privacy_policy)
        end
      else
        model.account.update_attributes(attrs.except(:sign_contracts))
      end

      model
    end
  end

  def exec(users:)
    create_or_update_users(users[:administrators], role: :other).each do |user|
      run(:set_administrator, user: user, administrator: true)
      log { "Admin: #{user.username}" }
    end

    create_or_update_users(users[:content_analysts], role: :other).each do |user|
      run(:set_content_analyst, user: user, content_analyst: true)
      log { "Content Analyst: #{user.username}" }
    end

    create_or_update_users(users[:customer_support], role: :other).each do |user|
      run(:set_customer_support, user: user, customer_support: true)
      log { "Customer Support: #{user.username}" }
    end

    create_or_update_users(users[:researchers], role: :other).each do |user|
      run(:set_researcher, user: user, researcher: true)
      log { "Researcher: #{user.username}" }
    end

    create_or_update_users(
      users[:students], role: :student, school_type: :college
    ).each { |user| log { "Student: #{user.username}" } }

    create_or_update_users(
      users[:teachers], faculty_status: :confirmed_faculty, role: :instructor, school_type: :college
    ).each { |user| log { "Teacher: #{user.username}" } }

    log_status
  end
end
