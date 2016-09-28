require 'rails_helper'

RSpec.xdescribe OpenStax::Biglearn::Api, type: :external do
  before(:each) { RequestStore.clear! }
  after(:all)   { RequestStore.clear! }

  it 'can be configured' do
    configuration = OpenStax::Biglearn::Api.configuration
    expect(configuration).to be_a(OpenStax::Biglearn::Api::Configuration)

    OpenStax::Biglearn::Api.configure do |config|
      expect(config).to eq configuration
    end
  end

  it 'can use the fake client or the real client or the local query client with real or fake' do
    OpenStax::Biglearn::Api.use_fake_client
    expect(OpenStax::Biglearn::Api.send :client).to be_a(OpenStax::Biglearn::Api::FakeClient)

    OpenStax::Biglearn::Api.use_real_client
    expect(OpenStax::Biglearn::Api.send :client).to be_a(OpenStax::Biglearn::Api::RealClient)

    OpenStax::Biglearn::Api.use_client_named(:local_query_with_fake)
    expect(OpenStax::Biglearn::Api.send :client).to be_a(OpenStax::Biglearn::Api::LocalQueryClient)

    OpenStax::Biglearn::Api.use_client_named(:local_query_with_real)
    expect(OpenStax::Biglearn::Api.send :client).to be_a(OpenStax::Biglearn::Api::LocalQueryClient)

    OpenStax::Biglearn::Api.use_fake_client
    expect(OpenStax::Biglearn::Api.send :client).to be_a(OpenStax::Biglearn::Api::FakeClient)
  end

  context "#default_client_name" do
    it "returns whatever is in the settings and caches it until the end of the request" do
      allow(Settings::Biglearn).to receive(:client) { "blah" }
      expect(described_class.default_client_name).to eq "blah"
      allow(Settings::Biglearn).to receive(:client) { :fake }
      expect(described_class.default_client_name).to eq "blah"

      RequestStore.clear!

      expect(described_class.default_client_name).to eq :fake
    end
  end

  context 'api calls' do
    let(:dummy_role)              { 'some role' }
    let(:dummy_roles)             { [dummy_role] }
    let(:dummy_exercises)         { ['some exercises'] }
    let(:dummy_pools)             { [double(uuid: 'some uuid')] }
    let(:dummy_excluded_pools)    { [double(uuid: 'some excluded uuid')] }
    let(:dummy_pool_exclusions)   do
      dummy_excluded_pools.map{ |pool| { pool_id: pool.uuid, ignore_versions: true } }
    end
    let(:dummy_count)             { 'some count' }
    let(:dummy_difficulty)        { 'some difficulty' }
    let(:dummy_allow_repetitions) { 'some allow repetitions' }

    let(:client_double) do
      double.tap do |dbl|
        allow(dbl).to receive(:get_clues)
                  .with(roles: dummy_roles, pool_uuids: dummy_pools.map(&:uuid), force_cache_miss: false)
                  .and_return('client get_clues response')
        allow(dbl).to receive(:add_exercises)
                  .with(exercises: dummy_exercises)
                  .and_return('client add_exercises response')
        allow(dbl).to receive(:get_projection_exercises)
                  .with(
                    role:              dummy_role,
                    pool_uuids:        dummy_pools.map(&:uuid),
                    pool_exclusions:   dummy_pool_exclusions,
                    count:             dummy_count,
                    difficulty:        dummy_difficulty,
                    allow_repetitions: dummy_allow_repetitions
                  ).and_return(dummy_exercises)
      end
    end

    before(:each) do
      RequestStore.store[:biglearn_v1_forced_client_in_use] = true
      OpenStax::Biglearn::Api.client = client_double
    end

    it 'delegates get_clues to the client' do
      response = OpenStax::Biglearn::Api.get_clues(roles: dummy_roles, pools: dummy_pools)
      expect(response).to eq('client get_clues response')
    end

    it 'returns an empty hash if pools is empty' do
      response = OpenStax::Biglearn::Api.get_clues(roles: dummy_roles, pools: [])
      expect(response).to eq({})
    end

    it 'returns a hash that maps all given pool uuids to nil if roles is empty' do
      response = OpenStax::Biglearn::Api.get_clues(roles: [], pools: dummy_pools)
      expect(response).to eq({'some uuid' => nil})
    end

    it 'delegates add_exercises to the client' do
      response = OpenStax::Biglearn::Api.add_exercises(exercises: dummy_exercises)
      expect(response).to eq('client add_exercises response')
    end

    it 'delegates get_projection_exercises to the client' do
      response = OpenStax::Biglearn::Api.get_projection_exercises(
        role:              dummy_role,
        pools:             dummy_pools,
        pool_exclusions:   dummy_pool_exclusions,
        count:             dummy_count,
        difficulty:        dummy_difficulty,
        allow_repetitions: dummy_allow_repetitions
      )
      expect(response).to eq(dummy_exercises)
    end

    it 'logs a warning and does not explode when client does not return expected number of exercises' do
      allow(client_double).to receive(:get_projection_exercises).and_return(['only exercise'])
      expect(Rails.logger).to receive(:warn)
      response = OpenStax::Biglearn::Api.get_projection_exercises(
        role:              dummy_role,
        pools:             dummy_pools,
        count:             2,
        difficulty:        dummy_difficulty,
        allow_repetitions: dummy_allow_repetitions
      )
    end

    it 'errors when biglearn returns exercises not present locally' do
      course = role.student.course
      ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(page.ecosystem)
      ecosystem = ::Content::Ecosystem.new(strategy: ecosystem_strategy)
      AddEcosystemToCourse[ecosystem: ecosystem, course: course]
      allow(OpenStax::Biglearn::Api).to receive(:fetch_topic_pes) do
        [OpenStruct.new(number: 'dummy')]
      end
      result = ResetPracticeWidget.call role: role, exercise_source: :biglearn, page_ids: [page.id]
      expect(result.errors.first.code).to eq :missing_local_exercises
    end
  end
end
