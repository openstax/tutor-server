require 'rails_helper'

RSpec.describe Tasks::Models::TaskedPlaceholder, type: :model do
  let(:tasked_placeholder) { Tasks::Models::TaskedPlaceholder.new }

  it { is_expected.to validate_presence_of(:placeholder_type) }

  context "placeholder types" do
    it "is created with 'default' placeholder type" do
      expect(tasked_placeholder.default_type?).to be_truthy
    end

    it "supports the 'exercise' placeholder type" do
      tasked_placeholder.exercise_type!
      expect(tasked_placeholder.exercise_type?).to be_truthy
    end
  end

  it "converts its placeholder type to a name" do
    name_by_type = {
      "default_type"   => "default",
      "exercise_type"  => "exercise"
    }

    Tasks::Models::TaskedPlaceholder.placeholder_types.keys.each do |placeholder_type|
      tasked_placeholder.send("#{placeholder_type}!".to_sym)
      expect(tasked_placeholder.placeholder_name).to eq(name_by_type[placeholder_type])
    end
  end
end
