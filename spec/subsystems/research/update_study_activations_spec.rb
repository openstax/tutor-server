require 'rails_helper'

RSpec.describe Research::UpdateStudyActivations do

  let!(:study1) { FactoryBot.create :research_study }
  let!(:study2) { FactoryBot.create :research_study, activate_at: 2.minutes.from_now }
  let!(:study3) { FactoryBot.create :research_study, activate_at: 2.minutes.from_now, deactivate_at: 4.minutes.from_now }
  let!(:study4) { FactoryBot.create :research_study, activate_at: 4.minutes.from_now }

  it "works when called repeatedly" do
    described_class.call

    expect_active(study1: false, study2: false, study3: false, study4: false)

    Timecop.freeze(2.minute.from_now) do
      described_class.call
      expect_active(study1: false, study2: true, study3: true, study4: false)
      expect(study2).not_to receive(:update_attribute) # shouldn't be reactivated or deactivated
    end

    Timecop.freeze(4.minute.from_now) do
      described_class.call
      expect_active(study1: false, study2: true, study3: false, study4: true)
    end
  end

  it "can autodeactive a study that was started manually" do
    study = FactoryBot.create :research_study, deactivate_at: 2.minutes.ago
    Research::ActivateStudy[study]
    expect(study).to be_active
    described_class.call
    expect(study.reload).not_to be_active
  end

  def expect_active(args)
    args.each do |key, value|
      study = self.send(key)
      study.reload
      to_or_not_to = value ? :to : :not_to
      expect(study).send(to_or_not_to, be_active)
    end
  end

end
