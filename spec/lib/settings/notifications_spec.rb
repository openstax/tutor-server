require 'rails_helper'

RSpec.describe Settings::Notifications, type: :lib do

  [:general, :instructor].each do |type|
    context type.to_s do
      after(:each) do
        described_class.messages(type).each{ |id, message| described_class.remove(type, id) }
      end

      it 'can store a message' do
        expect { described_class.add(type, 'a test message') }.to_not raise_error
      end

      it 'can remove a single message' do
        described_class.add(type, 'message one')
        two = described_class.add(type, 'message two')
        described_class.add(type, 'message three')

        expect(described_class.messages(type).size).to eq(3)
        described_class.remove(type, two)
        expect(described_class.messages(type).values).to eq ["message one", "message three"]
      end

      it 'can iterate through messages' do
        3.times { |num| described_class.add(type, "message #{num + 1}") }

        described_class.messages(type).values.each_with_index do |message, num|
          expect(message).to eq("message #{num + 1}")
        end
      end
    end
  end

end
