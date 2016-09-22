require 'rails_helper'

RSpec.describe OpenStax::Biglearn::Api::LocalClue do
  let(:local_clue) { described_class.new(responses: responses) }

  context 'no learners or responses' do
    let(:responses) { [] }

    it "'aggregate' is 0.5" do
      expect(local_clue.aggregate).to be 0.5
    end
    it "'left' is 0.0" do
      expect(local_clue.left).to be 0.0
    end
    it "'right' is 1.0" do
      expect(local_clue.right).to be 1.0
    end
    it "'level' is :medium" do
      expect(local_clue.level).to be :medium
    end
    it "'threshold' is :below" do
      expect(local_clue.threshold).to be :below
    end
    it "'confidence' is :bad" do
      expect(local_clue.confidence).to be :bad
    end
  end

  context 'single learner' do
    context 'no responses' do
      let(:responses) { [] }

      it "'aggregate' is 0.5" do
        expect(local_clue.aggregate).to be 0.5
      end
      it "'left' is 0.0" do
        expect(local_clue.left).to be 0.0
      end
      it "'right' is 1.0" do
        expect(local_clue.right).to be 1.0
      end
      it "'level' is :medium" do
        expect(local_clue.level).to be :medium
      end
      it "'threshold' is :below" do
        expect(local_clue.threshold).to be :below
      end
      it "'confidence' is :bad" do
        expect(local_clue.confidence).to be :bad
      end
    end

    context 'few responses' do
      let(:responses) { [ 1.0, 0.0, 0.0 ] }

      it "'level' is :medium" do
        expect(local_clue.level).to be :medium
      end
      it "'threshold' is :below" do
        expect(local_clue.threshold).to be :below
      end
      it "'confidence' is :bad" do
        expect(local_clue.confidence).to be :bad
      end
    end

    context 'many responses' do
      let(:responses) { [ 1, 0, 0, 1, 1, 1, 1, 1, 0, 1, 0 ].map(&:to_f) }

      it "'threshold' is :above" do
        expect(local_clue.threshold).to be :above
      end
      it "'confidence' is :good" do
        expect(local_clue.confidence).to be :good
      end
    end
  end

end
