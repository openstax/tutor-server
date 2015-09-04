require 'rails_helper'

RSpec.describe OpenStax::Biglearn::V1, :type => :external do
  before(:each) do
    @initial_client = OpenStax::Biglearn::V1.send :client
  end

  after(:each) do
    OpenStax::Biglearn::V1.instance_variable_set('@client', @initial_client)
  end

  it 'can be configured' do
    configuration = OpenStax::Biglearn::V1.configuration
    expect(configuration).to be_a(OpenStax::Biglearn::V1::Configuration)

    OpenStax::Biglearn::V1.configure do |config|
      expect(config).to eq configuration
    end
  end

  it 'can use the fake client or the real client' do
    OpenStax::Biglearn::V1.use_fake_client
    expect(OpenStax::Biglearn::V1.send :client).to be_a(OpenStax::Biglearn::V1::FakeClient)

    OpenStax::Biglearn::V1.use_real_client
    expect(OpenStax::Biglearn::V1.send :client).to be_a(OpenStax::Biglearn::V1::RealClient)

    OpenStax::Biglearn::V1.use_fake_client
    expect(OpenStax::Biglearn::V1.send :client).to be_a(OpenStax::Biglearn::V1::FakeClient)
  end

  context 'api calls' do
    let!(:dummy_roles) { 'some roles' }
    let!(:dummy_pages) { 'some pages' }
    let!(:dummy_exercises) { 'some exercises' }

    let!(:dummy_role)               { ['some role'] }
    let!(:dummy_pools)              { [ double(uuid: 'some uuid') ] }
    let!(:dummy_tag_search)         { 'some tag search' }
    let!(:dummy_count)              { 'some count' }
    let!(:dummy_difficulty)         { 'some difficulty' }
    let!(:dummy_allow_repetitions)  { 'some allow repetitions' }

    let!(:client_double) {
      double.tap do |dbl|
        allow(dbl).to receive(:get_clue)
                  .with(roles: [dummy_roles], pages: [dummy_pages])
                  .and_return('client get_clue response')
        allow(dbl).to receive(:add_exercises)
                  .with(exercises: dummy_exercises)
                  .and_return('client add_exercises response')
        allow(dbl).to receive(:get_projection_exercises)
                  .with(
                    role:              dummy_role,
                    pools:             dummy_pools,
                    tag_search:        dummy_tag_search,
                    count:             dummy_count,
                    difficulty:        dummy_difficulty,
                    allow_repetitions: dummy_allow_repetitions
                  ).and_return(['some exercises'])
      end
    }

    before(:each) do
      OpenStax::Biglearn::V1.instance_variable_set('@client', client_double)
    end

    it 'delegates get_clue to the client' do
      response = OpenStax::Biglearn::V1.get_clue(roles: dummy_roles, pages: dummy_pages)
      expect(response).to eq('client get_clue response')
    end

    it 'delegates add_exercises to the client' do
      response = OpenStax::Biglearn::V1.add_exercises(exercises: dummy_exercises)
      expect(response).to eq('client add_exercises response')
    end

    it 'delegates get_projection_exercises to the client' do
      response = OpenStax::Biglearn::V1.get_projection_exercises(
        role:              dummy_role,
        pools:             dummy_pools,
        tag_search:        dummy_tag_search,
        count:             dummy_count,
        difficulty:        dummy_difficulty,
        allow_repetitions: dummy_allow_repetitions
      )
      expect(response).to eq(['some exercises'])
    end

    it 'logs a warning and does not explode when client does not return expected number of exercises' do
      allow(client_double).to receive(:get_projection_exercises).and_return(['only exercise'])
      expect(Rails.logger).to receive(:warn)
      response = OpenStax::Biglearn::V1.get_projection_exercises(
        role:              dummy_role,
        pools:             dummy_pools,
        tag_search:        dummy_tag_search,
        count:             2,
        difficulty:        dummy_difficulty,
        allow_repetitions: dummy_allow_repetitions
      )
    end
  end
end
