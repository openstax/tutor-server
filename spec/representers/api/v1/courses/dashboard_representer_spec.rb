require 'rails_helper'

RSpec.describe Api::V1::Courses::DashboardRepresenter, type: :representer do

  let(:opens_at) { Time.current }
  let(:api_opens_at) { DateTimeUtilities.to_api_s(opens_at) }

  let(:due_at) { opens_at + 1.week }
  let(:api_due_at) { DateTimeUtilities.to_api_s(due_at) }

  let(:last_worked_at) { opens_at + 1.day }
  let(:api_last_worked_at) { DateTimeUtilities.to_api_s(last_worked_at) }

  let(:published_at) { opens_at }

  let(:publish_job_uuid) { "394839483948" }

  let(:publish_job_url) { 'http://www.example.com' }

  let(:publish_job) {
    Hashie::Mash.new({
      id: publish_job_uuid,
      state: {
        name: 'succeeded'
      },
      progress: 1.0,
      data: { url: publish_job_url },
      errors: []
    })
  }

  let(:publish_job_representation) {
    {
      id: publish_job_uuid,
      status: 'succeeded',
      progress: 1.0,
      url: publish_job_url,
      errors: []
    }.stringify_keys
  }

  let(:data) {
    Hashie::Mash.new.tap do |mash|
      mash.plans = [
        Hashie::Mash.new({
          id: 23,
          title: 'HW1',
          is_trouble: false,
          type: 'homework',
          is_draft: false,
          is_publishing: true,
          is_published: true,
          first_published_at: published_at,
          last_published_at: published_at,
          publish_last_requested_at: published_at,
          publish_job_uuid: publish_job_uuid,
          tasking_plans: [
            Hashie::Mash.new(
              target_id: 42,
              target_type: 'CourseMembership::Models::Period',
              opens_at: opens_at,
              due_at: due_at
            )
          ]
        })
      ]
      mash.tasks = [
        Hashie::Mash.new({
          id: 34,
          title: 'HW2',
          opens_at: opens_at,
          due_at: due_at,
          last_worked_at: last_worked_at,
          task_type: :homework,
          completed?: false,
          past_due?: false,
          actual_and_placeholder_exercise_count: 5,
          completed_exercise_count: 4,
          correct_exercise_count: 3,
          deleted?: true
        }),
        Hashie::Mash.new({
          id: 37,
          title: 'Reading 1',
          due_at: due_at,
          last_worked_at: last_worked_at,
          task_type: :reading,
          completed?: false,
          actual_and_placeholder_exercise_count: 7,
          completed_exercise_count: 6,
          deleted?: false
        }),
        Hashie::Mash.new({
          id: 89,
          title: 'HW3',
          opens_at: opens_at,
          due_at: due_at,
          last_worked_at: last_worked_at,
          task_type: :homework,
          completed?: true,
          past_due?: true,
          actual_and_placeholder_exercise_count: 8,
          completed_exercise_count: 8,
          correct_exercise_count: 3,
          deleted?: false
        }),
        Hashie::Mash.new({
          id: 99,
          title: 'Ext1',
          opens_at: opens_at,
          due_at: due_at,
          last_worked_at: last_worked_at,
          task_type: :external,
          completed?: true,
          past_due?: true,
          deleted?: false
        }),
      ]
      mash.course = {
        course_id: 2,
        name: 'Physics 101',
        teachers: [
          Hashie::Mash.new({
            id: '42',
            role_id: '43',
            first_name: 'Andrew',
            last_name: 'Garcia'
          }),
          Hashie::Mash.new({
            id: '44',
            role_id: '45',
            first_name: 'Bob',
            last_name: 'Newhart'
          })
        ]
      }
      mash.role = {
        id: 34,
        type: 'teacher'
      }
    end
  }

  it "represents dashboard output" do
    expect(Jobba).to receive(:find).with(publish_job_uuid).and_return(publish_job)

    representation = described_class.new(data).as_json

    expect(representation).to include(
      "plans" => [
        a_hash_including(
          "id" => '23',
          "title" => 'HW1',
          "is_trouble" => false,
          "type" => 'homework',
          "is_draft" => false,
          "is_publishing" => true,
          "is_published" => true,
          "first_published_at" => be_kind_of(String),
          "last_published_at" => be_kind_of(String),
          "publish_last_requested_at" => be_kind_of(String),
          "publish_job" => publish_job_representation,
          "tasking_plans" => [
            {
              "target_id" => '42',
              "target_type" => 'period',
              "opens_at" => api_opens_at,
              "due_at" => api_due_at
            }
          ]
        )
      ],
      "tasks" => a_collection_containing_exactly(
        a_hash_including(
          "id" => '34',
          "title" => 'HW2',
          "opens_at" => api_opens_at,
          "due_at" => api_due_at,
          "last_worked_at" => api_last_worked_at,
          "type" => 'homework',
          "complete" => false,
          "exercise_count" => 5,
          "complete_exercise_count" => 4,
          "is_deleted" => true
        ),
        a_hash_including(
          "id" => '37',
          "title" => 'Reading 1',
          "due_at" => api_due_at,
          "last_worked_at" => api_last_worked_at,
          "type" => 'reading',
          "complete" => false,
          "exercise_count" => 7,
          "complete_exercise_count" => 6,
          "is_deleted" => false
        ),
        a_hash_including(
          "id" => '89',
          "title" => 'HW3',
          "opens_at" => api_opens_at,
          "due_at" => api_due_at,
          "last_worked_at" => api_last_worked_at,
          "type" => 'homework',
          "complete" => true,
          "exercise_count" => 8,
          "complete_exercise_count" => 8,
          "correct_exercise_count" => 3,
          "is_deleted" => false
        ),
        a_hash_including(
          "id" => '99',
          "title" => 'Ext1',
          "opens_at" => api_opens_at,
          "due_at" => api_due_at,
          "last_worked_at" => api_last_worked_at,
          "type" => 'external',
          "complete" => true,
          "is_deleted" => false
        ),
      ),
      "role" => {
        "id" => '34',
        "type" => 'teacher'
      },
      "course" => {
        "name" => 'Physics 101',
        "teachers" => [
          { "id" => '42',
            "role_id" => '43',
            "first_name" => 'Andrew',
            "last_name" => 'Garcia' },
          { "id" => '44',
            "role_id" => '45',
            "first_name" => 'Bob',
            "last_name" => 'Newhart' }
        ]
      }
    )

    expect(representation["tasks"][0]).to_not have_key "correct_exercise_count"
    expect(representation["tasks"][1]).to_not have_key "correct_exercise_count"
    expect(representation["tasks"][2]).to     have_key "correct_exercise_count"
  end

end
