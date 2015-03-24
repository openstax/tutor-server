require 'rails_helper'

module OpenStax::BigLearn
  RSpec.describe V1::FakeClient, :type => :external do

    it 'allows adding of tags' do
      expect{V1::fake_client.add_tags(V1::Tag.new('test', 'topic'))}
        .to change{V1::fake_client.store_tags_copy.count}.by(1)

      V1::fake_client.reload! # make sure data is really saved

      expect(V1::fake_client.store_tags_copy).to include('test' => ['topic'])
    end

    it 'allows adding of exercises' do
      expect{V1::fake_client.add_exercises(V1::Exercise.new('e42', 'topic'))}
        .to change{V1::fake_client.store_exercises_copy.count}.by(1)

      V1::fake_client.reload! # make sure data is really saved

      expect(V1::fake_client.store_exercises_copy).to include('e42' => ['topic'])
    end

  end
end