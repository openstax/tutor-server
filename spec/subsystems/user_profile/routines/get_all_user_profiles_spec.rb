require 'rails_helper'

describe UserProfile::GetAllUserProfiles do
  context "when there are no users in the system" do
    it "returns an empty array" do
      result = UserProfile::GetAllUserProfiles.call
      expect(result.errors).to be_empty
      expect(result.outputs.profiles).to be_empty
    end
  end

  context "when there is one user in the system" do
    it "returns an array containing that user profile" do
      user = FactoryGirl.create(:user, full_name: 'Hello World')

      result = UserProfile::GetAllUserProfiles.call
      expect(result.errors).to be_empty
      expect(result.outputs.profiles.size).to eq(1)
      expect(result.outputs.profiles).to include({ profile_id: user.id,
                                                   entity_user_id: user.entity_user_id,
                                                   full_name: 'Hello World' })
    end
  end

  context "when there are multiple users in the system" do
    it "returns an array containing those user's profiles" do
      user1 = FactoryGirl.create(:user, full_name: 'User1')
      user2 = FactoryGirl.create(:user, full_name: 'User2')

      result = UserProfile::GetAllUserProfiles.call
      expect(result.errors).to be_empty
      expect(result.outputs.profiles.size).to eq(2)
      expect(result.outputs.profiles).to include({ profile_id: user1.id,
                                                   entity_user_id: user1.entity_user_id,
                                                   full_name: 'User1' })
      expect(result.outputs.profiles).to include({ profile_id: user2.id,
                                                   entity_user_id: user2.entity_user_id,
                                                   full_name: 'User2' })
    end
  end
end
