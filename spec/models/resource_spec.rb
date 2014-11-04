require 'rails_helper'

RSpec.describe Resource, :type => :model do
  it { is_expected.to have_many(:readings) }
  it { is_expected.to have_many(:interactives) }

  it { is_expected.to validate_uniqueness_of(:url) }

  it "is only really destroyed when no one holds a reference" do
    reading1 = FactoryGirl.create(:reading)

    resource = reading1.resource
    resource_id = resource.id

    reading2 = FactoryGirl.create(:reading, resource: resource)
    reading1.destroy

    # The resource is not yet destroyed
    expect(Resource.where(id: resource_id).one?).to be_truthy

    reading2.destroy

    # Now the resource is destroyed
    expect(Resource.where(id: resource_id).one?).to be_falsy
  end
end
