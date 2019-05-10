require 'rails_helper'

RSpec.describe User::RecordTourView, type: :routine do
  let(:user) { FactoryBot.create :user_profile }

  context 'a new tour' do
    let(:view){ described_class[user: user, tour_identifier: 'whirlwind'] }

    it 'creates a tour' do
      id = view.tour.identifier
      expect(User::Models::Tour.find_by(identifier: id)).not_to be_nil
    end

    it 'marks the user as having viewed it' do
      expect(view.view_count).to eq(1)
    end

  end

  context 'an existing tour' do
    let(:tour) { FactoryBot.create :user_tour }
    let(:view) { described_class[user: user, tour_identifier: tour.identifier] }

    it 'marks the user as having viewed it' do
      expect(view.view_count).to eq(1)
    end

    context 'that has been previously viewed by user' do
      before { 2.times{ described_class[user: user, tour_identifier: tour.identifier] } }
      it 'marks the user as having viewed additional times' do
        expect(view.view_count).to eq(3)
      end
    end

  end

  context 'an invalid tour id' do
    let(:error_code) do
      errors = described_class.call(user: user, tour_identifier: @identifier).errors
      errors.any? ? errors.first.code : nil
    end

    it 'disallows spaces' do
      @identifier = 'whirlwind bob'
      expect(error_code).to eq(:invalid)
    end

    it 'disallows other characters' do
      @identifier = 'evil%one'
      expect(error_code).to eq(:invalid)
    end

    it 'allows digits' do
      @identifier = 'test-1'
      expect(error_code).to be_nil
    end

    it 'cant be blank' do
      @identifier = ''
      expect(error_code).to eq(:blank)
    end

  end

end
