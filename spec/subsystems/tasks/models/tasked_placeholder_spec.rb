require 'rails_helper'

RSpec.describe Tasks::Models::TaskedPlaceholder, type: :model do
  subject { Tasks::Models::TaskedPlaceholder.new }

  it { is_expected.to validate_presence_of(:placeholder_type) }

  context "placeholder types" do
    it "is created with 'unknown_type' placeholder type" do
      expect(subject.unknown_type?).to be_truthy
    end

    it "supports the 'exercise_type' placeholder type" do
      subject.exercise_type!
      expect(subject.exercise_type?).to be_truthy
    end
  end
end
