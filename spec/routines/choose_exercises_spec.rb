require 'rails_helper'

RSpec.describe ChooseExercises, type: :routine do
  let(:args)                 do
    {
      exercises: exercises,
      count: count,
      already_assigned_exercise_numbers: assigned_exercises.map(&:number),
      randomize_exercises: randomize_exercises,
      randomize_order: randomize_order
    }
  end

  subject(:result) { described_class[**args] }

  context 'without multiparts' do
    let(:assigned_exercises)   { 3.times.map { FactoryBot.create :content_exercise } }
    let(:unassigned_exercises) { 2.times.map { FactoryBot.create :content_exercise } }
    let(:exercises) { assigned_exercises + unassigned_exercises }

    context 'enough unassigned exercises' do
      let(:count) { 2 }

      context 'random exercises' do
        let(:randomize_exercises) { true }

        context 'random order' do
          let(:randomize_order) { true }

          it 'returns random unworked exercises in a random order' do
            expect(result.size).to eq count
            expect((result & unassigned_exercises).size).to eq count
          end
        end

        context 'set order' do
          let(:randomize_order) { false }

          it 'returns random unworked exercises' do
            expect(result.size).to eq count
            expect(Set.new result).to eq Set.new unassigned_exercises
          end
        end
      end

      context 'set exercises' do
        let(:randomize_exercises) { false }

        context 'random order' do
          let(:randomize_order) { true }

          it 'returns set unworked exercises in a random order' do
            expect(Set.new result).to eq(Set.new unassigned_exercises.first(count))
          end
        end

        context 'set order' do
          let(:randomize_order) { false }

          it 'returns set unworked exercises in a set order' do
            expect(result).to eq unassigned_exercises.first(count)
          end
        end
      end
    end

    context 'not enough unassigned exercises' do
      let(:count) { 3 }

      context 'random exercises' do
        let(:randomize_exercises) { true }

        context 'random order' do
          let(:randomize_order) { true }

          it 'returns random unworked (higher priority) and worked exercises in a random order' do
            expect(result.size).to eq 3
            expect((result & unassigned_exercises).size).to eq 2
            expect((result & assigned_exercises).size).to eq 1
          end
        end

        context 'set order' do
          let(:randomize_order) { false }

          it 'returns random unworked (first) and worked exercises in a set order' do
            expect(result.size).to eq 3
            expect(Set.new result.first(2)).to eq Set.new unassigned_exercises
            expect(result.third).to be_in assigned_exercises
          end
        end
      end

      context 'set exercises' do
        let(:randomize_exercises) { false }

        context 'random order' do
          let(:randomize_order) { true }

          it 'returns set unworked (higher priority) and worked exercises in a random order' do
            expect(Set.new result).to eq(Set.new unassigned_exercises + assigned_exercises.first(1))
          end
        end

        context 'set order' do
          let(:randomize_order) { false }

          it 'returns set unworked (first) and worked exercises in a set order' do
            expect(result).to eq unassigned_exercises + assigned_exercises.first(1)
          end
        end
      end
    end

    context 'not enough exercises' do
      let(:count) { 6 }

      context 'random exercises' do
        let(:randomize_exercises) { true }

        context 'random order' do
          let(:randomize_order) { true }

          it 'returns all available exercises in a random order' do
            expect(Set.new result).to eq(Set.new unassigned_exercises + assigned_exercises)
          end
        end

        context 'set order' do
          let(:randomize_order) { false }

          it 'returns all available exercises in a random order' do
            expect(Set.new result).to eq(Set.new unassigned_exercises + assigned_exercises)
          end
        end
      end

      context 'set exercises' do
        let(:randomize_exercises) { false }

        context 'random order' do
          let(:randomize_order) { true }

          it 'returns all available exercises in a random order' do
            expect(Set.new result).to eq(Set.new unassigned_exercises + assigned_exercises)
          end
        end

        context 'set order' do
          let(:randomize_order) { false }

          it 'returns all available exercises in a set order' do
            expect(result).to eq exercises
          end
        end
      end
    end
  end

  context 'with multiparts' do
    let(:triple_multipart) { FactoryBot.create :content_exercise, number_of_questions: 3 }
    let(:double_multipart) { FactoryBot.create :content_exercise, number_of_questions: 2 }
    let(:simple_exercises) { 2.times.map { FactoryBot.create :content_exercise }         }
    let(:exercises)        { [ triple_multipart, double_multipart ] + simple_exercises   }

    context 'no exercises already assigned' do
      let(:already_assigned_exercise_numbers) { [] }

      it 'prefers the biggest multiparts when possible' do
        expect(
          described_class[
            exercises: exercises,
            count: 7,
            already_assigned_exercise_numbers: already_assigned_exercise_numbers,
            randomize_exercises: false,
            randomize_order: false
          ]
        ).to eq exercises

        expect(
          described_class[
            exercises: exercises,
            count: 6,
            already_assigned_exercise_numbers: already_assigned_exercise_numbers,
            randomize_exercises: false,
            randomize_order: false
          ]
        ).to eq exercises.first(3)

        expect(
          described_class[
            exercises: exercises,
            count: 5,
            already_assigned_exercise_numbers: already_assigned_exercise_numbers,
            randomize_exercises: false,
            randomize_order: false
          ]
        ).to eq exercises.first(2)

        expect(
          described_class[
            exercises: exercises,
            count: 4,
            already_assigned_exercise_numbers: already_assigned_exercise_numbers,
            randomize_exercises: false,
            randomize_order: false
          ]
        ).to eq [ triple_multipart, simple_exercises.first ]

        expect(
          described_class[
            exercises: exercises,
            count: 3,
            already_assigned_exercise_numbers: already_assigned_exercise_numbers,
            randomize_exercises: false,
            randomize_order: false
          ]
        ).to eq [ triple_multipart ]

        expect(
          described_class[
            exercises: exercises,
            count: 2,
            already_assigned_exercise_numbers: already_assigned_exercise_numbers,
            randomize_exercises: false,
            randomize_order: false
          ]
        ).to eq [ double_multipart ]

        expect(
          described_class[
            exercises: exercises,
            count: 1,
            already_assigned_exercise_numbers: already_assigned_exercise_numbers,
            randomize_exercises: false,
            randomize_order: false
          ]
        ).to eq simple_exercises.first(1)
      end
    end

    context 'simple exercises already assigned' do
      let(:already_assigned_exercise_numbers) { simple_exercises.map(&:number) }

      it 'prefers the biggest multiparts but minimizes dropped questions' do
        expect(
          described_class[
            exercises: exercises,
            count: 7,
            already_assigned_exercise_numbers: already_assigned_exercise_numbers,
            randomize_exercises: false,
            randomize_order: false
          ]
        ).to eq exercises

        expect(
          described_class[
            exercises: exercises,
            count: 6,
            already_assigned_exercise_numbers: already_assigned_exercise_numbers,
            randomize_exercises: false,
            randomize_order: false
          ]
        ).to eq exercises.first(3)

        expect(
          described_class[
            exercises: exercises,
            count: 5,
            already_assigned_exercise_numbers: already_assigned_exercise_numbers,
            randomize_exercises: false,
            randomize_order: false
          ]
        ).to eq exercises.first(2)

        expect(
          described_class[
            exercises: exercises,
            count: 4,
            already_assigned_exercise_numbers: already_assigned_exercise_numbers,
            randomize_exercises: false,
            randomize_order: false
          ]
        ).to eq exercises.first(2)

        expect(
          described_class[
            exercises: exercises,
            count: 3,
            already_assigned_exercise_numbers: already_assigned_exercise_numbers,
            randomize_exercises: false,
            randomize_order: false
          ]
        ).to eq [ triple_multipart ]

        expect(
          described_class[
            exercises: exercises,
            count: 2,
            already_assigned_exercise_numbers: already_assigned_exercise_numbers,
            randomize_exercises: false,
            randomize_order: false
          ]
        ).to eq [ double_multipart ]

        expect(
          described_class[
            exercises: exercises,
            count: 1,
            already_assigned_exercise_numbers: already_assigned_exercise_numbers,
            randomize_exercises: false,
            randomize_order: false
          ]
        ).to eq [ double_multipart ]
      end
    end
  end
end
