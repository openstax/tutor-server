require 'rails_helper'

describe Domain::FindOrCreateUserForLegacyUser do
  context "when the given legacy user is not already a domain user" do
    let(:legacy_user) {
      legacy_user = double(User)
      allow(legacy_user).to receive(:id) {10}
      legacy_user
    }
    it "creates and returns a new domain user" do
      result = Domain::FindOrCreateUserForLegacyUser.call(legacy_user)
      expect(result.errors).to be_empty
      expect(result.outputs.user).to_not be_nil
      expect(result.outputs.user.class).to be(Entity::User)
    end
  end
  context "when the given legacy user is already a domain user" do
    let(:legacy_user) {
      legacy_user = double(User)
      allow(legacy_user).to receive(:id) {10}
      legacy_user
    }
    before(:each) do
      result = Domain::FindOrCreateUserForLegacyUser.call(legacy_user)
      expect(result.errors).to be_empty
      expect(result.outputs.user).to_not be_nil
      expect(result.outputs.user.class).to be(Entity::User)
      @previous_entity_user = result.outputs.user
    end
    let(:previous_entity_user) { @previous_entity_user }
    it "creates and returns the existing domain user associated with the legacy user" do
      result = Domain::FindOrCreateUserForLegacyUser.call(legacy_user)
      expect(result.errors).to be_empty
      expect(result.outputs.user).to eq(previous_entity_user)
    end
  end
end
