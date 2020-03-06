require 'rails_helper'

RSpec.describe ChooseExercises, type: :routine do

  let(:exercises)          { 5.times.map{ FactoryBot.create :content_exercise } }
  let(:worked_exercises)   { exercises.first(3) }
  let(:unworked_exercises) { exercises - worked_exercises }

  let(:count)    { 3 }
  let(:history)  { Hashie::Mash.new(exercise_numbers: [worked_exercises.map(&:number)]) }

  let(:args) do
    {
      exercises: exercises,
      count: count,
      worked_exercise_numbers: worked_exercises.map(&:number),
      allow_repeats: allow_repeats,
      randomize_exercises: randomize_exercises,
      randomize_order: randomize_order
    }
  end

  context 'allow repeats' do
    let(:allow_repeats) { true }

    context 'random exercises' do
      let(:randomize_exercises) { true }

      context 'random order' do
        let(:randomize_order) { true }

        it 'returns random unworked (higher priority) and worked exercises in a random order' do
          result = described_class[**args]
          expect(result.size).to eq 3
          expect((result & unworked_exercises).size).to eq 2
          expect((result & worked_exercises).size).to eq 1
        end
      end

      context 'set order' do
        let(:randomize_order) { false }

        it 'returns random unworked (first) and worked exercises in a set order' do
          result = described_class[**args]
          expect(result.size).to eq 3
          expect(Set.new result.first(2)).to eq Set.new unworked_exercises
          expect(result.third).to be_in worked_exercises
        end
      end
    end

    context 'set exercises' do
      let(:randomize_exercises) { false }

      context 'random order' do
        let(:randomize_order) { true }

        it 'returns set unworked (higher priority) and worked exercises in a random order' do
          result = described_class[**args]
          expect(Set.new result).to eq(Set.new unworked_exercises + worked_exercises.first(1))
        end
      end

      context 'set order' do
        let(:randomize_order) { false }

        it 'returns set unworked (first) and worked exercises in a set order' do
          result = described_class[**args]
          expect(result).to eq unworked_exercises + worked_exercises.first(1)
        end
      end
    end
  end

  context 'disallow repeats' do
    let(:allow_repeats) { false }

    context 'randomize' do
      let(:randomize_exercises) { true }
      let(:randomize_order) { true }

      it 'returns random unworked exercises in a random order' do
        result = described_class[**args]
        expect(Set.new result).to eq(Set.new unworked_exercises)
      end
    end

    context 'don\'t randomize' do
      let(:randomize_exercises) { false }
      let(:randomize_order) { false }

      it 'returns set unworked exercises in a set order' do
        result = described_class[**args]
        expect(result).to eq unworked_exercises
      end
    end
  end

end
