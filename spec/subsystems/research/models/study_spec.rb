require 'rails_helper'

RSpec.describe Research::Models::Study, type: :model do

  context "brand new study" do
    let(:study) { FactoryBot.create :research_study }

    it "is in never_active scope" do
      expect(described_class.never_active).to include(study)
    end

    context "activated first time" do
      before { study.update_attribute(:last_activated_at, Time.current); study.reload }

      it "is active" do
        expect(study).to be_active
      end

      it "is in in the active scope" do
        expect(described_class.active).to include(study)
      end

      it "cannot be destroyed" do
        expect(study.destroy).to eq false
        expect{described_class.find(study.id)}.not_to raise_error
      end

      context "then deactivated" do
        before { study.update_attribute(:last_deactivated_at, Time.current); study.reload }

        it "is inactive" do
          expect(study).not_to be_active
        end

        it "can be destroyed" do
          expect(study.destroy).not_to eq false
          expect{described_class.find(study.id)}.to raise_error(ActiveRecord::RecordNotFound)
        end

        context "then reactivated" do
          before { study.update_attribute(:last_activated_at, Time.current); study.reload }

          it "is active again" do
            expect(study.reload).to be_active
          end
        end
      end
    end
  end

  context "scheduled for activation" do
    let!(:study) { FactoryBot.create :research_study, activate_at: Time.current }

    it "is in the activate_at_has_passed scope" do
      expect(described_class.activate_at_has_passed).to include(study)
    end
  end

  context "scheduled for deactivation" do
    let!(:study) { FactoryBot.create :research_study, deactivate_at: Time.current }

    it "is in the activate_at_has_passed scope" do
      expect(described_class.deactivate_at_has_passed).to include(study)
    end
  end

end
