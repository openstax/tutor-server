require 'rails_helper'

module OpenStax::Biglearn
  RSpec.describe V1::FakeClient, type: :external do

    let(:client) { described_class.instance }

    it 'allows adding of exercises' do
      expect{client.add_exercises(V1::Exercise.new(question_id: 'e42', version: 1, tags: 'topic'))}
        .to change{client.store_exercises_copy.count}.by(1)

      client.reload! # make sure data is really saved

      expect(client.store_exercises_copy).to include('e42' => { '1' => ['topic'] })
    end

    it 'matches boolean tag searches' do

      scenarios = [
        {
          tags: ['a'],
          condition: 'a',
          succeeds: true
        },
        {
          tags: ['a'],
          condition: { _or: ['b','a'] },
          succeeds: true
        },
        {
          tags: ['c'],
          condition: { _or: ['b','a'] },
          succeeds: false
        },
        {
          tags: ['c','b'],
          condition: { _or: ['b','a'] },
          succeeds: true
        },
        {
          tags: ['c', 'a'],
          condition: { _and: [ { _or: ['b','a'] }, 'c' ] },
          succeeds: true
        },
        {
          tags: ['c', 'd'],
          condition: { _and: [ { _or: ['b','a'] }, 'c' ] },
          succeeds: false
        }
      ]

      scenarios.each do |scenario|
        expect(client.tags_match_condition?(
                                 scenario[:tags],
                                 scenario[:condition])).to eq scenario[:succeeds]
      end
    end

    context "get_projection_exercises" do
      before do
        client.add_exercises(V1::Exercise.new(question_id: 'e1', tags: ['lo1', 'concept']))
        client.add_exercises(V1::Exercise.new(question_id: 'e2', tags: ['lo1', 'homework']))
        client.add_exercises(V1::Exercise.new(question_id: 'e3', tags: ['lo2', 'concept']))
        client.add_exercises(V1::Exercise.new(question_id: 'e4', tags: ['lo2', 'concept']))
        client.add_exercises(V1::Exercise.new(question_id: 'e5', tags: ['lo3', 'concept']))
      end

      it "works when allow_repetitions is false" do
        exercises = client.get_projection_exercises(
          role: nil,
          tag_search: { _and: [ { _or: ['lo1', 'lo2'] }, 'concept'] },
          count: 5,
          difficulty: 0.5,
          allow_repetitions: false
        )

        expect(exercises).to eq(%w(e1 e3 e4))
      end

      it "works when allow_repetitions is true" do
        exercises = client.get_projection_exercises(
          role: nil,
          tag_search: { _and: [ { _or: ['lo1', 'lo2'] }, 'concept'] },
          count: 5,
          difficulty: 0.5,
          allow_repetitions: true
        )

        expect(exercises).to eq(%w(e1 e3 e4 e1 e3))
      end
    end

    context "get_clue" do
      it 'returns a well-formatted clue' do
        profile = UserProfile::CreateProfile.call(username: SecureRandom.hex).outputs.profile
        profile.update_attribute(:exchange_read_identifier, '0edbe5f8f30abc5ba56b5b890bddbbe2')
        role = Role::CreateUserRole[profile.entity_user]

        # This assumes that a book has been imported
        clue = client.get_clue(roles: role, tags: 'k12phys-ch04-s02-lo01')

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
