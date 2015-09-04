require 'rails_helper'

module OpenStax::Biglearn
  RSpec.describe V1::FakeClient, type: :external do

    let(:client) { described_class.instance }

    let(:exercise_1) { V1::Exercise.new(question_id: 'e1', tags: ['lo1', 'concept']) }
    let(:exercise_2) { V1::Exercise.new(question_id: 'e2', tags: ['lo1', 'homework']) }
    let(:exercise_3) { V1::Exercise.new(question_id: 'e3', tags: ['lo2', 'concept']) }
    let(:exercise_4) { V1::Exercise.new(question_id: 'e4', tags: ['lo2', 'concept']) }
    let(:exercise_5) { V1::Exercise.new(question_id: 'e5', tags: ['lo3', 'concept']) }

    let(:pool_1)     { V1::Pool.new(exercises: [exercise_1, exercise_3, exercise_4]) }
    let(:pool_2)     { V1::Pool.new(exercises: [exercise_2]) }
    let(:pool_3)     { V1::Pool.new(exercises: [exercise_5]) }

    it 'allows adding of exercises' do
      expect{client.add_exercises([exercise_1, exercise_2])}
        .to change{client.store_exercises_copy.count}.by(2)

      client.reload! # make sure data is really saved

      expect(client.store_exercises_copy).to include('e1' => { '' => ['lo1', 'concept'] })
      expect(client.store_exercises_copy).to include('e2' => { '' => ['lo1', 'homework'] })
    end

    it 'allows adding of pools' do
      expect{client.add_pools([pool_1])}.to change{client.store_pools_copy.count}.by(1)

      client.reload! # make sure data is really saved

      expect(client.store_pools_copy.values).to include(['e1', 'e3', 'e4'])
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
      it 'returns a well-formatted array of clues' do
        profile = UserProfile::CreateProfile.call(username: SecureRandom.hex).outputs.profile
        profile.update_attribute(:exchange_read_identifier, '0edbe5f8f30abc5ba56b5b890bddbbe2')
        role = Role::CreateUserRole[profile.entity_user]
        pools = ['ignored-in-fake-client', 'only-the-size-of-the-array-matters']

        clues = client.get_clues(roles: role, pools: pools)
        expect(clues.size).to eq pools.size

        clues.each do |clue|
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
