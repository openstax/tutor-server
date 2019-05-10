require "rails_helper"

RSpec.describe WarningMailer, type: :mailer do

  let(:mail) do
    described_class.warning(
      subject: 'test',
      message: 'A test message',
      details: { value_one: 1, value_two: 2 }
    )
  end

  context "log and deliver" do

    it 'can log strings' do
      expect(Rails.logger).to receive(:warn).with("Help! I'm stuck in the matrix")
      line = nil
      expect do
        line = __LINE__ + 1
        described_class.log_and_deliver { "Help! I'm stuck in the matrix" }.perform_now
      end.to change { ActionMailer::Base.deliveries.count }.by(1)
      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq("[Tutor] (test) [Warning] #{File.basename(__FILE__)}:#{line}")
    end


    it 'can log hashes' do
      expect(Rails.logger).to receive(:warn).with("Printer on fire")
      line = nil
      expect do
        line = __LINE__ + 1
        described_class.log_and_deliver do
          { message: 'Printer on fire', details: { error_code: 'FIRE' } }
        end.perform_now
      end.to change { ActionMailer::Base.deliveries.count }.by(1)

      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq("[Tutor] (test) [Warning] #{File.basename(__FILE__)}:#{line}")
      expect(mail.body).to match('Error code')
      expect(mail.body).to match('FIRE')
    end

    it 'does nothing if a falsy value returned' do
      expect(Rails.logger).to_not receive(:warn)
      result = nil
      expect do
        result = described_class.log_and_deliver { false }
      end.to_not change { ActionMailer::Base.deliveries.count }
      expect(result).to be_nil
    end

    it 'can also be called with arguments' do
      expect(Rails.logger).to receive(:warn).with("Printer on fire")
      expect do
        described_class.log_and_deliver(subject: 'Via args') do
          { message: 'Printer on fire', details: { error_code: 'FIRE' } }
        end.perform_now
      end.to change { ActionMailer::Base.deliveries.count }.by(1)
      mail = ActionMailer::Base.deliveries.last
      expect(mail.subject).to eq('[Tutor] (test) [Warning] Via args')
      expect(mail.body).to match('FIRE')
    end

  end

  it 'sends an email' do
    expect { mail.deliver_now }.to change { ActionMailer::Base.deliveries.count }.by(1)
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
