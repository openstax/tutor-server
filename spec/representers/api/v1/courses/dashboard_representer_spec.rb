require 'rails_helper'

RSpec.describe Api::V1::Courses::DashboardRepresenter, :type => :representer do

  let(:data) {
    Hashie::Mash.new.tap do |mash|
      mash.plans = [
        Hashie::Mash.new({
          id: 23,
          title: 'HW1',
          trouble: false,
          type: 'homework',
          tasking_plans: Hashie::Mash.new(
            target: CourseMembership::Models::Period.new(id: 42),
            opens_at: 'now',
            due_at: 'then'
          )
        })
      ]
      mash.tasks = [
        Hashie::Mash.new({
          id: 34,
          title: 'HW2',
          opens_at: 'now',
          due_at: 'then',
          task_type: :homework,
          completed?: false,
          past_due?: false,
          actual_and_placeholder_exercise_count: 5,
          completed_exercise_count: 4,
          correct_exercise_count: 3
        }),
        Hashie::Mash.new({
          id: 37,
          title: 'Reading 1',
          due_at: 'then',
          task_type: :reading,
          completed?: false,
          actual_and_placeholder_exercise_count: 7,
          completed_exercise_count: 6,
        }),
        Hashie::Mash.new({
          id: 89,
          title: 'HW3',
          opens_at: 'now',
          due_at: 'then',
          task_type: :homework,
          completed?: true,
          past_due?: true,
          actual_and_placeholder_exercise_count: 8,
          completed_exercise_count: 8,
          correct_exercise_count: 3
        }),
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

  it "represents dashboard output" do
    representation = Api::V1::Courses::DashboardRepresenter.new(data).as_json

    expect(representation).to include(
      "plans" => [
        a_hash_including(
          "id" => '23',
          "title" => "HW1",
          "type" => "homework",
          "periods" => {
            "id" => '42',
            "opens_at" => "now",
            "due_at" => "then"
          }
        )
      ],
      "tasks" => [
        a_hash_including(
          "id" => '34',
          "title" => "HW2",
          "opens_at" => "now",
          "due_at" => "then",
          "type" => "homework",
          "complete" => false,
          "exercise_count" => 5,
          "complete_exercise_count" => 4
        ),
        a_hash_including(
          "id" => '37',
          "title" => "Reading 1",
          "due_at" => "then",
          "type" => "reading",
          "complete" => false,
          "exercise_count" => 7,
          "complete_exercise_count" => 6
        ),
        a_hash_including(
          "id" => '89',
          "title" => "HW3",
          "opens_at" => "now",
          "due_at" => "then",
          "type" => "homework",
          "complete" => true,
          "exercise_count" => 8,
          "complete_exercise_count" => 8,
          "correct_exercise_count" => 3
        ),
      ],
      "role" => {
        "id" => '34',
        "type" => "teacher"
      },
      "course" => {
        "name" => "Physics 101",
        "teacher_names" => [ "Andrew Garcia", "Bob Newhart" ]
      }
    )

    expect(representation["tasks"][0]).to_not have_key "correct_exercise_count"
    expect(representation["tasks"][1]).to_not have_key "correct_exercise_count"
    expect(representation["tasks"][2]).to     have_key "correct_exercise_count"
  end

end
