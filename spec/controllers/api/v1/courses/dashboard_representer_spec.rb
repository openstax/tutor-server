require 'rails_helper'

RSpec.describe Api::V1::Courses::DashboardRepresenter, :type => :representer do

  let(:data) {
    Hashie::Mash.new.tap do |mash|
      mash.plans = [
        Hashie::Mash.new({
          id: 23,
          title: 'HW1',
          opens_at: 'now',
          due_at: 'then',
          trouble: false,
          type: 'homework'
        })
      ]
      mash.tasks = [
        Hashie::Mash.new({
          id: 34,
          title: 'HW2',
          opens_at: 'now',
          due_at: 'then',
          task_type: 'homework',
          completed?: true
        }),
        Hashie::Mash.new({
          id: 37,
          title: 'Reading 1',
          due_at: 'then',
          task_type: 'reading',
          completed?: false
        })
      ]
      mash.course = {
        course_id: 2,
        name: 'Physics 101',
        teacher_names: ['Andrew Garcia', 'Bob Newhart']
      }
      mash.role = {
        id: 34,
        type: 'teacher'
      }
    end
  }
  # let(:representation) { Api::V1::TaskPlanRepresenter.new(task_plan).as_json }

  it "represents dashboard output" do
    representation = Api::V1::Courses::DashboardRepresenter.new(data).as_json

    expect(representation).to include(
      "plans" => [
        a_hash_including(
          "id" => 23,
          "title" => "HW1",
          "opens_at" => "now",
          "due_at" => "then",
          "type" => "homework"
        )
      ],
      "tasks" => [
        a_hash_including(
          "id" => 34,
          "title" => "HW2",
          "opens_at" => "now",
          "due_at" => "then",
          "type" => "homework",
          "complete" => true
        ),
        a_hash_including(
          "id" => 37,
          "title" => "Reading 1",
          "due_at" => "then",
          "type" => "reading",
          "complete" => false
        )
      ],
      "role" => {
        "id" => 34,
        "type" => "teacher"
      },
      "course" => {
        "name" => "Physics 101",
        "teacher_names" => [ "Andrew Garcia", "Bob Newhart" ]
      }
    )

  end

end
