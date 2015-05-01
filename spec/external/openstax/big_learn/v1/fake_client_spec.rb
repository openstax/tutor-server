require 'rails_helper'

module OpenStax::BigLearn
  RSpec.describe V1::FakeClient, :type => :external do

    let(:client) { described_class.new }

    it 'allows adding of exercises' do
      expect{client.add_exercises(V1::Exercise.new('e42', 'topic'))}
        .to change{client.store_exercises_copy.count}.by(1)

      client.reload! # make sure data is really saved

      expect(client.store_exercises_copy).to include('e42' => ['topic'])
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
        client.add_exercises(V1::Exercise.new('e1', 'lo1', 'concept'))
        client.add_exercises(V1::Exercise.new('e2', 'lo1', 'homework'))
        client.add_exercises(V1::Exercise.new('e3', 'lo2', 'concept'))
        client.add_exercises(V1::Exercise.new('e4', 'lo2', 'concept'))
        client.add_exercises(V1::Exercise.new('e5', 'lo3', 'concept'))
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

  end
end
