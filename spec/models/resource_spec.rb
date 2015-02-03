require 'rails_helper'

RSpec.describe Resource, :type => :model do
  it { is_expected.to have_many(:task_steps) }

  it { is_expected.to validate_uniqueness_of(:url) }

  it "is only really destroyed when no one holds a reference" do
    reading_step1 = FactoryGirl.create(:reading_step)

    resource = reading_step1.task_step.resource
    resource_id = resource.id

    task_step = FactoryGirl.create(:task_step, resource: resource)
    reading_step2 = FactoryGirl.create(:reading_step, task_step: task_step)
    reading_step1.destroy

    # The resource is not yet destroyed
    expect(Resource.where(id: resource_id).one?).to be_truthy

    reading_step2.destroy

    # Now the resource is destroyed
    expect(Resource.where(id: resource_id).one?).to be_falsy
  end
end
