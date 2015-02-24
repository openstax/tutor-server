require 'rails_helper'

RSpec.describe Api::V1::TaskSearchRepresenter, :type => :representer do

  context "a user" do

    let(:user)    { FactoryGirl.create(:user) }
    let(:outputs) { SearchTasks.call(q: "user_id:#{user.id}").outputs   }
    let(:default_task)   { FactoryGirl.create(:task) }
    let(:representation) { Api::V1::TaskSearchRepresenter.new(outputs).as_json }

    it "generates a JSON representation of their tasks" do

      5.times{ FactoryGirl.create(:tasking, taskee: user) }

      expect(representation).to include(
        "total_count" => 5,
        "items" => a_collection_including(
          a_hash_including(
            "id"           => a_value_within(1).of(5),
            "task_plan_id" => a_value_within(1).of(5),
            "title"        => a_string_matching(default_task.title),
            "is_shared"    => false
          )
        )
      )

    end

  end

end
