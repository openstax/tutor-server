require 'rails_helper'

RSpec.describe Import::Exercises, :type => :routine do
  before(:all) do
    OpenStax::Exercises::V1.fake_client.reset!

    OpenStax::Exercises::V1.fake_client.add_exercise(
      tags: ['ost-topic-apphys-ch5-s1-lo1']
    )
    OpenStax::Exercises::V1.fake_client.add_exercise(
      tags: ['ost-topic-apphys-ch5-s1-lo2']
    )
    OpenStax::Exercises::V1.fake_client.add_exercise(
      tags: ['ost-topic-apphys-ch5-s1-lo3']
    )
    OpenStax::Exercises::V1.fake_client.add_exercise(
      tags: ['ost-topic-apphys-ch5-s1-lo1', 'ost-topic-apphys-ch5-s1-lo2']
    )
    OpenStax::Exercises::V1.fake_client.add_exercise(
      tags: ['ost-topic-apphys-ch5-s1-lo2', 'ost-topic-apphys-ch5-s1-lo3']
    )
    OpenStax::Exercises::V1.fake_client.add_exercise(
      tags: ['ost-topic-apphys-ch5-s1-lo1', 'ost-topic-apphys-ch5-s1-lo3']
    )
  end

  after(:all) do
    OpenStax::Exercises::V1.fake_client.reset!
  end

  it 'can import all exercises with a single tag' do
    result = nil
    expect {
      result = Import::Exercises.call(tag: 'ost-topic-apphys-ch5-s1-lo3')
    }.to change{ Exercise.count }.by(3)

    exercises = Exercise.all.to_a
    expect(exercises[-3].exercise_topics.collect{|et| et.topic.name})
      .to eq ['ost-topic-apphys-ch5-s1-lo3']
    expect(exercises[-2].exercise_topics.collect{|et| et.topic.name})
      .to eq ['ost-topic-apphys-ch5-s1-lo2', 'ost-topic-apphys-ch5-s1-lo3']
    expect(exercises[-1].exercise_topics.collect{|et| et.topic.name})
      .to eq ['ost-topic-apphys-ch5-s1-lo1', 'ost-topic-apphys-ch5-s1-lo3']
  end

  it 'can import all exercises with a set of tags' do
    result = nil
    expect {
      result = Import::Exercises.call(tag: [
        'ost-topic-apphys-ch5-s1-lo1',
        'ost-topic-apphys-ch5-s1-lo2',
        'ost-topic-apphys-ch5-s1-lo3'
      ])
    }.to change{ Exercise.count }.by(6)

    exercises = Exercise.all.to_a
    expect(exercises[-6].exercise_topics.collect{|et| et.topic.name})
      .to eq ['ost-topic-apphys-ch5-s1-lo1']
    expect(exercises[-5].exercise_topics.collect{|et| et.topic.name})
      .to eq ['ost-topic-apphys-ch5-s1-lo2']
    expect(exercises[-4].exercise_topics.collect{|et| et.topic.name})
      .to eq ['ost-topic-apphys-ch5-s1-lo3']
    expect(exercises[-3].exercise_topics.collect{|et| et.topic.name})
      .to eq ['ost-topic-apphys-ch5-s1-lo1', 'ost-topic-apphys-ch5-s1-lo2']
    expect(exercises[-2].exercise_topics.collect{|et| et.topic.name})
      .to eq ['ost-topic-apphys-ch5-s1-lo2', 'ost-topic-apphys-ch5-s1-lo3']
    expect(exercises[-1].exercise_topics.collect{|et| et.topic.name})
      .to eq ['ost-topic-apphys-ch5-s1-lo1', 'ost-topic-apphys-ch5-s1-lo3']
  end
end
