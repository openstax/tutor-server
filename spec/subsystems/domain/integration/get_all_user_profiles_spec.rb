require 'rails_helper'

describe Domain::GetAllUserProfiles do
  context "when there are multiple users in the system" do
    let (:full_name1)   { 'Full Name 1' }
    let!(:legacy_user1) { FactoryGirl.create(:user, full_name: full_name1) }
    let (:entity_user1) { UserProfile::FindOrCreate.call(legacy_user1).outputs.user }
    let (:full_name2)   { 'Full Name 2' }
    let!(:legacy_user2) { FactoryGirl.create(:user, full_name: full_name2) }
    let (:entity_user2) { UserProfile::FindOrCreate.call(legacy_user2).outputs.user }

    it "returns an array containing those user's profiles" do
      result = Domain::GetAllUserProfiles.call
      expect(result.errors).to be_empty
      expect(result.outputs.profiles.size).to eq(2)
      expect(result.outputs.profiles).to include({ legacy_user_id: legacy_user1.id,
                                                   entity_user_id: entity_user1.id,
                                                   full_name:      full_name1 })
      expect(result.outputs.profiles).to include({ legacy_user_id: legacy_user2.id,
                                                   entity_user_id: entity_user2.id,
                                                   full_name:      full_name2 })
    end
  end
end
