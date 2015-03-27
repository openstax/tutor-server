require 'rails_helper'

describe Entity::CreateBook do
  it "returns a newly created book entity" do
    result = nil

    expect {
      result = Entity::CreateBook.call
    }.to change{Entity::Models::Book.count}.by(1)

    expect(result.errors).to be_empty
    expect(result.outputs.book).to eq(Entity::Models::Book.all.last)
  end
end
