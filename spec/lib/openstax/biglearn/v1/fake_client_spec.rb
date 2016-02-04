require 'rails_helper'

module OpenStax::Biglearn
  RSpec.describe V1::FakeClient, type: :external do

    let(:redis_secrets) { Rails.application.secrets['redis'] }

    let(:configuration) {
      c = OpenStax::Biglearn::V1::Configuration.new
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

    it 'allows adding pools' do
      expect(pool_1.uuid).to be_nil

      client.add_pools([pool_1])

      parsed_pool = JSON.parse client.store.read("pools/#{pool_1.uuid}")

      expect(parsed_pool).to eq pool_1.exercises.map(&:question_id)
    end

    context "get_projection_exercises" do
      before(:each) do
        V1.add_exercises([exercise_1, exercise_2, exercise_3, exercise_4, exercise_5])
        V1.add_pools([pool_1, pool_2, pool_3])
      end

      it "works when allow_repetitions is false" do
        exercises = client.get_projection_exercises(
          role: nil,
          pools: [pool_1],
          count: 5,
          difficulty: 0.5,
          allow_repetitions: false
        )

        expect(exercises).to eq(%w(e1 e3 e4))
      end

      it "works when allow_repetitions is true" do
        exercises = client.get_projection_exercises(
          role: nil,
          pools: [pool_1],
          count: 5,
          difficulty: 0.5,
          allow_repetitions: true
        )

        expect(exercises).to eq(%w(e1 e3 e4 e1 e3))
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
        pool_uuids = pools.collect(&:uuid)

        clues = client.get_clues(roles: roles, pools: pools)
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
end
