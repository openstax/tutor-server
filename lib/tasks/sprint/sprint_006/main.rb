module Sprint006
  class Main

    FIXTURE_FILE = 'spec/fixtures/m50577/index.cnxml.html'

    include WebMock::API

    lev_routine

    uses_routine OpenStax::Accounts::Dev::CreateAccount, 
                 as: :create_account,
                 translations: { outputs: {type: :verbatim} }

    uses_routine Import::Page,
                 as: :import_page,
                 translations: { outputs: {type: :verbatim} }

    uses_routine DistributeTasks,
                 as: :distribute,
                 translations: { outputs: {type: :verbatim} }


    protected

    def exec(username_or_user:, opens_at: Time.now)

      # Don't try to connect to Exchange
      OpenStax::Exchange.use_fake_client

      OpenStax::Exchange::FakeClient.configure do |config|
        config.registered_platforms   = {'123' => 'abc'}
        config.server_url             = 'https://exchange.openstax.org'
        config.supported_api_versions = ['v1']
      end

      if username_or_user.is_a? String
        run(:create_account, username: username_or_user)
        user = UserMapper.account_to_user(outputs[:account])
      else
        user = username_or_user
      end

      # Not importing the book because there's no way
      # to get the prototype collection from archive
      book = FactoryGirl.create :book

      hash = {
        title: 'Inertial Frames of Reference',
        id: 'm50577',
        version: '1.6',
        content: open(FIXTURE_FILE) { |f| f.read }
      }

      # Faking the module request because it is not in archive...
      stub_request(:get, "archive.cnx.org/contents/m50577")
        .to_return(:body => hash.to_json, :status => 200)

      run(:import_page, 'm50577', book)

      i_reading_assistant = FactoryGirl.create(
        :assistant, name: 'iReading', code_class_name: 'IReadingAssistant'
      )
      task_plan = FactoryGirl.create(
        :task_plan, assistant: i_reading_assistant,
                    settings: { page_id: outputs[:page].id },
      )
      task_plan.tasking_plans << FactoryGirl.create(
        :tasking_plan, task_plan: task_plan, target: user
      )

      run(:distribute, task_plan)

      ##########
      # Do all the sprint 6 setup, e.g. importing books, adding fake exercises
      # to OpenStax::Exercises::V1.fake_client matching the tags from the books
      # call the assistant to create an ireading, etc etc.

    end

  end
end