require "rails_helper"

# WARNING!  The `log_and_deliver` method logs lines from this file.
# If lines are added/removed before, the title matching specs must be updated.

RSpec.describe WarningMailer, type: :mailer do

  let(:mail) do
    described_class.warning(
      subject: 'test', message: 'A test message',
      details: { value_one: 1, value_two: 2 }
    )
  end

  context "log and deliver" do

    it 'can log strings' do
      expect(Rails.logger).to receive(:warn).with("Help! I'm stuck in the matrix")
      expect {
        described_class.log_and_deliver {
          "Help! I'm stuck in the matrix"
        }
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq('[Tutor] (test) [Warning] warning_mailer_spec.rb:20')
    end


    it 'can log hashes' do
      expect(Rails.logger).to receive(:warn).with("Printer on fire")
      expect {
        described_class.log_and_deliver {
          {message: 'Printer on fire', details: {error_code: 'FIRE'}}
        }
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq('[Tutor] (test) [Warning] warning_mailer_spec.rb:32')
      expect(mail.body).to match('Error code')
      expect(mail.body).to match('FIRE')
    end

    it 'does nothing if a falsy value returned' do
      expect(Rails.logger).to_not receive(:warn)
      expect {
        described_class.log_and_deliver {
          false
        }
      }.to_not change { ActionMailer::Base.deliveries.count }
    end

    it 'can also be called with arguments' do
      expect(Rails.logger).to receive(:warn).with("Printer on fire")
      expect {
        described_class.log_and_deliver(subject: 'Via args') {
          {message: 'Printer on fire', details: {error_code: 'FIRE'}}
        }
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq('[Tutor] (test) [Warning] Via args')
      expect(mail.body).to match('FIRE')
    end

  end

  it 'sends an email' do
    expect { mail.deliver_now }
      .to change { ActionMailer::Base.deliveries.count }.by(1)
  end

  it 'sets the subject' do
    expect(mail.subject).to eq('[Tutor] (test) [Warning] test')
  end

  it 'includes the message' do
    expect(mail.body).to match('A test message')
  end

  it 'logs details' do
    expect(mail.body).to match('Value one')
    expect(mail.body).to match('Value two')
  end



end
