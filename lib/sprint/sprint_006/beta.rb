module Sprint006
  class Beta

    OpenStax::Exchange.configure do |config|
      config.client_platform_id     = '123'
      config.client_platform_secret = 'abc' ## do not check real secrets into version control!
      config.client_server_url      = 'http://www.example.com:3000/base/path'
      config.client_api_version     = 'v1'
    end

    OpenStax::Exchange.use_fake_client

    OpenStax::Exchange::FakeClient.configure do |config|
      config.registered_platforms   = {'123' => 'abc'}
      config.server_url             = 'http://www.example.com:3000/base/path'
      config.supported_api_versions = ['v1']
    end

    OpenStax::Exchange.reset!

    lev_routine

    uses_routine OpenStax::Accounts::Dev::CreateAccount, 
                 as: :create_account,
                 translations: { outputs: {type: :verbatim} }

  protected

    def exec(username_or_user:, opens_at: Time.now)

      if username_or_user.is_a? String
        run(:create_account, username: username_or_user)
        user = UserMapper.account_to_user(outputs[:account])
      else
        user = username_or_user
      end

      ##########
      # Do all the sprint 6 setup, e.g. importing books, adding fake exercises
      # to OpenStax::Exercises::V1.fake_client matching the tags from the books
      # call the assistant to create an ireading, etc etc.

      task = FactoryGirl.create(
               :task, 
               step_types: [:tasked_reading, :tasked_exercise, :tasked_exercise, :tasked_reading],
               tasked_to: user)

    end

  end
end