require 'rails_helper'

RSpec.xdescribe OpenStax::Biglearn::Api::FakeClient, type: :external do

  let(:redis_secrets) { Rails.application.secrets['redis'] }

  let(:configuration) {
    c = OpenStax::Biglearn::Api::Configuration.new
    c.fake_store = ActiveSupport::Cache::RedisStore.new(
      url: redis_secrets['url'],
      namespace: redis_secrets['namespaces']['fake_biglearn']
    )
    c
  }

  let(:client) { described_class.new(configuration) }

  let(:exercise_1) { V1::Exercise.new(question_id: 'e1', version: 1, tags: ['lo1', 'concept']) }
  let(:exercise_2) { V1::Exercise.new(question_id: 'e2', version: 2, tags: ['lo1', 'homework']) }
  let(:exercise_3) { V1::Exercise.new(question_id: 'e3', version: 3, tags: ['lo2', 'concept']) }
  let(:exercise_4) { V1::Exercise.new(question_id: 'e4', version: 4, tags: ['lo2', 'concept']) }
  let(:exercise_5) { V1::Exercise.new(question_id: 'e5', version: 5, tags: ['lo3', 'concept']) }

  let(:pool_1)     { V1::Pool.new(exercises: [exercise_1, exercise_3, exercise_4]) }
  let(:pool_2)     { V1::Pool.new(exercises: [exercise_2]) }
  let(:pool_3)     { V1::Pool.new(exercises: [exercise_5]) }
  let(:pool_4)     { V1::Pool.new(exercises: [exercise_2]) }
  let(:pool_5)     { V1::Pool.new(exercises: [exercise_3]) }

  let(:exercise_1_new) { V1::Exercise.new(question_id: 'e1', version: 10,
                                          tags: ['lo1', 'concept']) }
  let(:exercise_3_new) { V1::Exercise.new(question_id: 'e3', version: 30,
                                          tags: ['lo2', 'concept']) }
  let(:exercise_4_new) { V1::Exercise.new(question_id: 'e4', version: 40,
                                          tags: ['lo2', 'concept']) }
  let(:pool_1_new)     { V1::Pool.new(exercises: [exercise_1_new,
                                                  exercise_3_new,
                                                  exercise_4_new]) }
  let(:pool_5_new)     { V1::Pool.new(exercises: [exercise_3_new]) }

  context 'add_exercises' do
    it 'allows adding exercises' do
      [exercise_1, exercise_2].each do |exercise|
        expect(client.store.read("exercises/#{exercise.question_id}")).to be_nil
      end

      expect(client.add_exercises([exercise_1, exercise_2])).to(
        eq [ { 'message' => 'Question tags saved.' }]
      )

      [exercise_1, exercise_2].each do |exercise|
        parsed_exercise = JSON.parse client.store.read("exercises/#{exercise.question_id}")
        version = exercise.version.to_s
        expect(parsed_exercise[version]).to eq exercise.tags
      end
    end

    it 'returns an empty array if an empty array is given' do
      expect(client.add_exercises([])).to eq []
    end
  end

  context 'add_pools' do
    it 'allows adding pools' do
      expect(pool_1.uuid).to be_nil

      client.add_pools([pool_1])

      parsed_pool = JSON.parse client.store.read("pools/#{pool_1.uuid}")

      expected_pool = pool_1.exercises.map do |ex|
        { question_id: ex.question_id.to_s, version: ex.version }.stringify_keys
      end
      expect(parsed_pool).to eq expected_pool
    end
  end

  context "get_projection_exercises" do
    before(:each) do
      V1.add_exercises([exercise_1, exercise_2, exercise_3, exercise_4, exercise_5])
      V1.add_pools([pool_1, pool_2, pool_3])
      V1.add_pools([pool_4, pool_5])
    end

    it "works" do
      exercises = client.get_projection_exercises(
        role: nil,
        pool_uuids: [pool_1.uuid],
        pool_exclusions: [],
        count: 5,
        difficulty: 0.5,
        allow_repetitions: true
      )

      expect(exercises).to eq(%w(e1 e3 e4))
    end

    it "works when pool_exclusions is given" do
      V1.add_pools([pool_1_new, pool_5_new])

      exercises = client.get_projection_exercises(
        role: nil,
        pool_uuids: [pool_1.uuid],
        pool_exclusions: [{pool: pool_1_new, ignore_versions: false},
                          {pool: pool_4, ignore_versions: false},
                          {pool: pool_5_new, ignore_versions: true}],
        count: 5,
        difficulty: 0.5,
        allow_repetitions: true
      )

      expect(exercises).to eq(%w(e1 e4))
    end
  end

  context "get_clues" do
    before(:each) do
      pool_1.uuid = SecureRandom.hex
      pool_2.uuid = SecureRandom.hex
    end

    it 'returns a well-formatted array of clues' do
      user = User::CreateUser.call(username: SecureRandom.hex).outputs.user
      roles = [Role::CreateUserRole[user]]
      pools = [pool_1, pool_2]
      pool_uuids = pools.map(&:uuid)

      clues = client.get_clues(roles: roles, pool_uuids: pool_uuids)
      expect(clues.keys.size).to eq pools.size

      clues.each do |pool_uuid, clue|
        expect(pool_uuids).to include pool_uuid
        expect(clue[:value]).to be_a(Float)
        expect(['high', 'medium', 'low']).to include(clue[:value_interpretation])
        expect(clue[:confidence_interval]).to contain_exactly(kind_of(Float), kind_of(Float))
        expect(['good', 'bad']).to include(clue[:confidence_interval_interpretation])
        expect(clue[:sample_size]).to be_kind_of(Integer)
        expect(['above', 'below']).to include(clue[:sample_size_interpretation])
      end
    end
  end

end
