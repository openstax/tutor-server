require 'rails_helper'

RSpec.describe Lms::Launch, type: :model do

  let(:course) { FactoryBot.create :course_profile_course, is_lms_enabled: true }
  let(:app) { FactoryBot.create(:lms_app, owner: course) }
  let(:message) { OpenStruct.new(context_id: '1234', tool_consumer_instance_guid: '4242') }
  let(:authenticator) { OpenStruct.new(valid_signature?: true, message: message) }

  context '#from_uuid' do
    it 'verifies the launch already exists' do
      expect { Lms::Launch.from_uuid(42) }.to raise_error(Lms::Launch::CouldNotLoadLaunch)
    end
  end

  context '#validate!' do
    it 'verifies signature valid' do
      request = FactoryBot.create(:launch_request, app: app)
      expect do
        Lms::Launch.from_request(request).validate!
      end.to raise_error(Lms::Launch::InvalidSignature)
    end

    it 'verifies oauth_timestamp not expired' do
      request = FactoryBot.create(
        :launch_request,
        app: app,
        current_time: Time.current - (Lms::Launch::MAX_REQUEST_AGE + 1.minute)
      )
      expect do
        Lms::Launch.from_request(request, authenticator: authenticator).validate!
      end.to raise_error(Lms::Launch::ExpiredTimestamp)
    end

    it 'verifies oauth_timestamp not too far into the future' do
      request = FactoryBot.create(
        :launch_request,
        app: app,
        current_time: Time.current + Lms::Launch::MAX_REQUEST_AGE + 1.minute
      )
      expect do
        Lms::Launch.from_request(request, authenticator: authenticator).validate!
      end.to raise_error(Lms::Launch::InvalidTimestamp)
    end

    it 'verifies nonce unused' do
      request = FactoryBot.create(:launch_request, app: app)
      Lms::Launch.from_request(request, authenticator: authenticator).validate!
      expect do
        Lms::Launch.from_request(request, authenticator: authenticator).validate!
      end.to raise_error(Lms::Launch::NonceAlreadyUsed)
    end
  end

  context '#app' do
    it 'verifies the Lms::App exists' do
      request = FactoryBot.create(:launch_request, app: app)
      app.destroy!
      expect do
        Lms::Launch.from_request(request).validate!
      end.to raise_error(Lms::Launch::AppNotFound)
    end
  end

  context '#context' do
    it 'creates context' do
      launch = Lms::Launch.from_request(
        FactoryBot.create(:launch_request, app: app),
        authenticator: authenticator
      ).validate!
      expect { launch.persist! }.to change { Lms::Models::Context.count }.by 1
      expect(launch.context).not_to be_nil
    end

    it 'can link multiple contexts to a single course' do
      3.times do |i|
        message.context_id = "a-not-so-random-id-#{i}"
        launch = Lms::Launch.from_request(
          FactoryBot.create(:launch_request, app: app),
          authenticator: authenticator
        ).validate!
        launch.persist!
      end
      expect(course.lms_contexts.count).to eq 3
    end

    it 'multiple concurrent contexts without course can be launched' do
      app = Lms::WilloLabs.new
      3.times do |i|
        expect do
          message.context_id = "launch-#{i}"
          launch = Lms::Launch.from_request(
            FactoryBot.create(:launch_request, app: app),
            authenticator: authenticator
          ).validate!
          launch.persist!
        end.to change { Lms::Models::Context.count }.by 1
      end
    end

    it 'will not re-use a context that is linked to a different course' do
      message.context_id = "re-used-launch-id"
      launch1 = Lms::Launch.from_request(FactoryBot.create(:launch_request, app: app), authenticator: authenticator).validate!
      launch1.persist!

      app2 = FactoryBot.create(:lms_app, owner: FactoryBot.create(:course_profile_course, is_lms_enabled: true))
      launch2 = Lms::Launch.from_request(FactoryBot.create(:launch_request, app: app2), authenticator: authenticator).validate!
      launch2.persist!
      expect(launch1.context).not_to eq(launch2.context)
    end

    context 'recording app type on the context' do
      let(:launch) do
        Lms::Launch.from_request(
          FactoryBot.create(:launch_request, app: app),
          authenticator: authenticator
        ).validate!
      end

      it 'defaults to App' do
        expect(launch.context.app).to be_a(Lms::Models::App)
      end

      context 'willo labs' do
        let(:app) { Lms::WilloLabs.new }

        it 'sets app type to WilloLabs' do
          expect(launch.context.app).to be_a(Lms::WilloLabs)
        end
      end
    end

    it 'verifies the course has not yet ended' do
      course.update_attribute :ends_at, Time.current
      request = FactoryBot.create(:launch_request, app: app)
      expect do
        Lms::Launch.from_request(request, authenticator: authenticator).validate!.context
      end.to raise_error(Lms::Launch::CourseEnded)
    end

    it 'verifies the course has LMS enabled' do
      course.update_attribute :is_lms_enabled, false
      request = FactoryBot.create(:launch_request, app: app)
      expect do
        Lms::Launch.from_request(request, authenticator: authenticator).validate!.context
      end.to raise_error(Lms::Launch::LmsDisabled)
    end
  end

  context '#role' do
    it 'maps roles' do
      {
        instructor: %w{Instructor Creator Faculty Mentor Staff SysAdmin SysSupport AccountAdmin Administrator},
        student: %w{Student Learner ProspectiveStudent}
      }.each do |role, mappings|
        mappings.each do |type|
            req = FactoryBot.create(:launch_request, app: app)
            req.request_parameters[:roles] = "IMS::LIS::Roles::Context::URNs::#{type}"
            launch = Lms::Launch.from_request(req,authenticator: authenticator).validate!
            expect(launch.role).to eq role
        end
      end
    end
  end

  context '#store_score_callback' do
    context 'duplicated CourseScoreCallback records' do
      let(:launch) do
        Lms::Launch.from_request(
          FactoryBot.create(:launch_request, :assignment, app: app, course: course),
          authenticator: authenticator
        ).validate!
      end

      let(:dupe) do
        FactoryBot.create :lms_course_score_callback,
                          result_sourcedid: launch.result_sourcedid,
                          outcome_url: launch.outcome_url,
                          course: course
      end

      it 'removes unattached ones' do
        launch.store_score_callback(dupe.profile)
        expect { dupe.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it 'fails if dupe is in use' do
        expect(UserIsCourseStudent).to receive(:[]).and_return(true)
        expect do
          launch.store_score_callback(dupe.profile)
        end.to raise_error Lms::Launch::CourseScoreInUse
      end
    end
  end
end
