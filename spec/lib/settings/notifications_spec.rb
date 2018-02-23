require 'rails_helper'

RSpec.describe Settings::Notifications, type: :lib do

  [:general, :instructor].each do |type|
    context type.to_s do
      after(:each) do
        described_class.all(type: type).each do |notification|
          described_class.remove(type: notification.type, id: notification.id)
        end
      end

      it 'can store a message' do
        expect { described_class.add(type: type, message: 'a test message') }.to_not raise_error
      end

      it 'can remove a single message' do
        described_class.add(type: type, message: 'message one')
        two = described_class.add(type: type, message: 'message two')
        described_class.add(type: type, message: 'message three')

        expect(described_class.all(type: type).size).to eq(3)
        described_class.remove(type: type, id: two)
        expect(described_class.all(type: type).map(&:message)).to(
          eq ["message one", "message three"]
        )
      end

      it 'can iterate through all messages, automatically removing expired ones' do
        current_time = Time.current
        3.times do |num|
          from = current_time - 1.day + num.days
          to = current_time + num.days

          described_class.add(type: type, message: "message #{num + 1}", from: from, to: to)
        end

        notifications = described_class.all(type: type)
        expect(notifications.size).to eq 2
        notifications.each_with_index do |notification, num|
          expect(notification.message).to eq "message #{num + 2}"
        end
      end

      it 'can iterate through active messages, automatically removing expired ones' do
        current_time = Time.current
        3.times do |num|
          from = current_time - 1.day + num.days
          to = current_time + num.days

          described_class.add(type: type, message: "message #{num + 1}", from: from, to: to)
        end

        notifications = described_class.active(type: type)
        expect(notifications.size).to eq 1
        expect(notifications.first.message).to eq "message 2"
      end
    end
  end

end
