require 'rails_helper'

RSpec.describe ResetPracticeWidget, :type => :routine do

  it "has feedback immediately available" do
    role = Entity::Role.create!
    entity_task = ResetPracticeWidget[role: role, condition: :fake, page_ids: []]
    expect(entity_task.task.feedback_available?).to be_truthy
  end

end
