require 'rails_helper'

module OpenStax::BigLearn
  RSpec.describe V1::FakeClient, :type => :external do

    it 'allows adding of tags' do
      expect{V1::fake_client.add_tags(V1::Tag.new('test'))}
        .to change{V1::fake_client.store_tags_copy.count}.by(1)

      V1::fake_client.reload! # make sure data is really saved

      expect(V1::fake_client.store_tags_copy).to include('test')
    end

    it 'allows adding of exercises' do
      expect{V1::fake_client.add_exercises(V1::Exercise.new('e42', 'topic'))}
        .to change{V1::fake_client.store_exercises_copy.count}.by(1)

      V1::fake_client.reload! # make sure data is really saved

      expect(V1::fake_client.store_exercises_copy).to include('e42' => ['topic'])
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
        expect(V1::fake_client.tags_match_condition?(
                                 scenario[:tags], 
                                 scenario[:condition])).to eq scenario[:succeeds]
      end
    end

  end
end