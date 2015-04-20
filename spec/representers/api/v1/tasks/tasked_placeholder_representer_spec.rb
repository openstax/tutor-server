require 'rails_helper'

RSpec.describe Api::V1::Tasks::TaskedPlaceholderRepresenter, :type => :representer do

  let(:tasked_placeholder) {
    task_step = FactoryGirl.create(:tasks_task_step)
    tasked_placeholder = Tasks::Models::TaskedPlaceholder.new
    task_step.tasked = tasked_placeholder
    task_step.save!
    tasked_placeholder
  }
  let(:representation)     { Api::V1::TaskedPlaceholderRepresenter.new(tasked_placeholder).as_json }

  it "represents a tasked placeholder" do
    expect(representation).to include(
      "id"           => tasked_placeholder.task_step.id,
      "type"         => "exercise",  ## <-- not a typo
      "is_completed" => false,
      # "content_url"  => tasked_placeholder.url,
      # "content"      => tasked_placeholder.content
    )
  end

end
