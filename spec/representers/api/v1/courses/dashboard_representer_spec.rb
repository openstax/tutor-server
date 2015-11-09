require 'rails_helper'

RSpec.describe Api::V1::Courses::DashboardRepresenter, type: :representer do

  let(:opens_at) { Time.now }
  let(:api_opens_at) { DateTimeUtilities.to_api_s(opens_at) }

  let(:due_at) { opens_at + 1.week }
  let(:api_due_at) { DateTimeUtilities.to_api_s(due_at) }

  let(:last_worked_at) { opens_at + 1.day }
  let(:api_last_worked_at) { DateTimeUtilities.to_api_s(last_worked_at) }

  let(:published_at) { opens_at }

  let(:data) {
    Hashie::Mash.new.tap do |mash|
      mash.plans = [
        Hashie::Mash.new({
          id: 23,
          title: 'HW1',
          is_trouble: false,
          type: 'homework',
          is_publish_requested: true,
          published_at: published_at,
          publish_last_requested_at: published_at,
          publish_job_uuid: "394839483948",
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
          correct_exercise_count: 3
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
          correct_exercise_count: 3
        }),
        Hashie::Mash.new({
          id: 99,
          title: 'Ext1',
          opens_at: opens_at,
          due_at: due_at,
          last_worked_at: last_worked_at,
          task_type: :external,
          completed?: true,
          past_due?: true
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
        ],
        periods: [
          Hashie::Mash.new({
            id: '46',
            name: '1st',
            chapters: [
              Hashie::Mash.new({
                id: '47',
                title: 'Ch 1',
                book_location: [1],
                pages: [
                  Hashie::Mash.new({
                    id: '48',
                    title: 'Pg 1',
                    book_location: [1, 1],
                    completed: 0,
                    in_progress: 1,
                    not_started: 2,
                    original_performance: 0.0,
                    spaced_practice_performance: 0.1
                  }),
                  Hashie::Mash.new({
                    id: '49',
                    title: 'Pg 2',
                    book_location: [1, 2],
                    completed: 3,
                    in_progress: 4,
                    not_started: 5,
                    original_performance: 0.2,
                    spaced_practice_performance: 0.3
                  })
                ]
              }),
              Hashie::Mash.new({
                id: '50',
                title: 'Ch 2',
                book_location: [2],
                pages: [
                  Hashie::Mash.new({
                    id: '51',
                    title: 'Pg 3',
                    book_location: [2, 1],
                    completed: 6,
                    in_progress: 7,
                    not_started: 8,
                    original_performance: 0.4,
                    spaced_practice_performance: 0.5
                  }),
                  Hashie::Mash.new({
                    id: '52',
                    title: 'Pg 4',
                    book_location: [2, 2],
                    completed: 9,
                    in_progress: 10,
                    not_started: 11,
                    original_performance: 0.6,
                    spaced_practice_performance: 0.7
                  })
                ]
              })
            ]
          }),
          Hashie::Mash.new({
            id: '53',
            name: '2nd',
            chapters: [
              Hashie::Mash.new({
                id: '47',
                title: 'Ch 1',
                book_location: [1],
                pages: [
                  Hashie::Mash.new({
                    id: '48',
                    title: 'Pg 1',
                    book_location: [1, 1],
                    completed: 12,
                    in_progress: 13,
                    not_started: 14,
                    original_performance: 0.7,
                    spaced_practice_performance: 0.8
                  }),
                  Hashie::Mash.new({
                    id: '49',
                    title: 'Pg 2',
                    book_location: [1, 2],
                    completed: 15,
                    in_progress: 16,
                    not_started: 17,
                    original_performance: 0.9,
                    spaced_practice_performance: 1.0
                  })
                ]
              })
            ]
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
    representation = Api::V1::Courses::DashboardRepresenter.new(data).as_json

    expect(representation).to include(
      "plans" => [
        a_hash_including(
          "id" => '23',
          "title" => "HW1",
          "is_trouble" => false,
          "type" => "homework",
          "is_publish_requested" => true,
          "published_at" => be_kind_of(String),
          "publish_last_requested_at" => be_kind_of(String),
          "publish_job_uuid" => "394839483948",
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
          "title" => "HW2",
          "opens_at" => api_opens_at,
          "due_at" => api_due_at,
          "last_worked_at" => api_last_worked_at,
          "type" => "homework",
          "complete" => false,
          "exercise_count" => 5,
          "complete_exercise_count" => 4
        ),
        a_hash_including(
          "id" => '37',
          "title" => "Reading 1",
          "due_at" => api_due_at,
          "last_worked_at" => api_last_worked_at,
          "type" => "reading",
          "complete" => false,
          "exercise_count" => 7,
          "complete_exercise_count" => 6
        ),
        a_hash_including(
          "id" => '89',
          "title" => "HW3",
          "opens_at" => api_opens_at,
          "due_at" => api_due_at,
          "last_worked_at" => api_last_worked_at,
          "type" => "homework",
          "complete" => true,
          "exercise_count" => 8,
          "complete_exercise_count" => 8,
          "correct_exercise_count" => 3
        ),
        a_hash_including(
          "id" => '99',
          "title" => "Ext1",
          "opens_at" => api_opens_at,
          "due_at" => api_due_at,
          "last_worked_at" => api_last_worked_at,
          "type" => "external",
          "complete" => true
        ),
      ),
      "role" => {
        "id" => '34',
        "type" => "teacher"
      },
      "course" => {
        "name" => "Physics 101",
        "teachers" => [
          { "id" => "42",
            "role_id" => "43",
            "first_name" => "Andrew",
            "last_name" => "Garcia" },
          { "id" => "44",
            "role_id" => "45",
            "first_name" => "Bob",
            "last_name" => "Newhart" }
        ],
        "periods" => [
          {
            "id" => "46",
            "name" => "1st",
            "chapters" => [
              {
                "id" => "47",
                "title" => "Ch 1",
                "chapter_section" => [1],
                "pages" => [
                  {
                    "id" => "48",
                    "title" => "Pg 1",
                    "chapter_section" => [1, 1],
                    "completed" => 0,
                    "in_progress" => 1,
                    "not_started" => 2,
                    "original_performance" => 0.0,
                    "spaced_practice_performance" => 0.1
                  },
                  {
                    "id" => "49",
                    "title" => "Pg 2",
                    "chapter_section" => [1, 2],
                    "completed" => 3,
                    "in_progress" => 4,
                    "not_started" => 5,
                    "original_performance" => 0.2,
                    "spaced_practice_performance" => 0.3
                  }
                ]
              },
              {
                "id" => "50",
                "title" => "Ch 2",
                "chapter_section" => [2],
                "pages" => [
                  {
                    "id" => "51",
                    "title" => "Pg 3",
                    "chapter_section" => [2, 1],
                    "completed" => 6,
                    "in_progress" => 7,
                    "not_started" => 8,
                    "original_performance" => 0.4,
                    "spaced_practice_performance" => 0.5
                  },
                  {
                    "id" => "52",
                    "title" => "Pg 4",
                    "chapter_section" => [2, 2],
                    "completed" => 9,
                    "in_progress" => 10,
                    "not_started" => 11,
                    "original_performance" => 0.6,
                    "spaced_practice_performance" => 0.7
                  }
                ]
              }
            ]
          },
          {
            "id" => "53",
            "name" => "2nd",
            "chapters" => [
              {
                "id" => "47",
                "title" => "Ch 1",
                "chapter_section" => [1],
                "pages" => [
                  {
                    "id" => "48",
                    "title" => "Pg 1",
                    "chapter_section" => [1, 1],
                    "completed" => 12,
                    "in_progress" => 13,
                    "not_started" => 14,
                    "original_performance" => 0.7,
                    "spaced_practice_performance" => 0.8
                  },
                  {
                    "id" => "49",
                    "title" => "Pg 2",
                    "chapter_section" => [1, 2],
                    "completed" => 15,
                    "in_progress" => 16,
                    "not_started" => 17,
                    "original_performance" => 0.9,
                    "spaced_practice_performance" => 1.0
                  }
                ]
              }
            ]
          }
        ]
      }
    )

    expect(representation["tasks"][0]).to_not have_key "correct_exercise_count"
    expect(representation["tasks"][1]).to_not have_key "correct_exercise_count"
    expect(representation["tasks"][2]).to     have_key "correct_exercise_count"
  end

end
