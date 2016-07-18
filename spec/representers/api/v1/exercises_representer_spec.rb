require 'rails_helper'

RSpec.describe Api::V1::ExercisesRepresenter, type: :representer do
  let(:exercise_hash_array) { [
    Hashie::Mash.new(id: 42, tags: [], pool_types: ['foo', 'bar'], is_excluded: false)
  ] }

  let(:representation) {
    described_class.new(exercise_hash_array).as_json
  }

  let(:params) { [] }

  context "id" do
    it "can be read" do
      expect(representation.first).to include("id" => "42")
    end

    it "can be written" do
      described_class.new(params).from_json([{ "id" => "21" }].to_json)
      expect(params.first).to include("id" => "21")
    end
  end

  context "pool_types" do
    it "can be read" do
      expect(representation.first).to include("pool_types" => ["foo", "bar"])
    end

    it "cannot be written (attempts are silently ignored)" do
      described_class.new(params).from_json([{ "pool_types" => ["bar", "baz"] }].to_json)
      expect(params.first).not_to include("pool_types" => ["bar", "baz"])
    end
  end

  context "is_excluded" do
    it "can be read" do
      expect(representation.first).to include("is_excluded" => false)
    end

    it "can be written" do
      described_class.new(params).from_json([{ "is_excluded" => true }].to_json)
      expect(params.first).to include("is_excluded" => true)
    end
  end
end
