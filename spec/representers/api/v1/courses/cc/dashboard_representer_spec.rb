require 'rails_helper'

RSpec.describe Api::V1::Courses::Cc::DashboardRepresenter, type: :representer do

  let(:opens_at) { Time.current }
  let(:api_opens_at) { DateTimeUtilities.to_api_s(opens_at) }

  let(:due_at) { opens_at + 1.week }
  let(:api_due_at) { DateTimeUtilities.to_api_s(due_at) }

  let(:last_worked_at) { opens_at + 1.day }
  let(:api_last_worked_at) { DateTimeUtilities.to_api_s(last_worked_at) }

  let(:published_at) { opens_at }

  let(:data) do
    OpenStruct.new(
      tasks: [
        OpenStruct.new(
          id: 34,
          title: 'CC2',
          opens_at: opens_at,
          last_worked_at: last_worked_at,
          task_type: :concept_coach,
          completed?: false
        ),
        OpenStruct.new(
          id: 37,
          title: 'CC1',
          last_worked_at: last_worked_at,
          task_type: :concept_coach,
          completed?: false
        ),
        OpenStruct.new(
          id: 89,
          title: 'CC3',
          opens_at: opens_at,
          last_worked_at: last_worked_at,
          task_type: :concept_coach,
          completed?: true
        ),
        OpenStruct.new(
          id: 99,
          title: 'CC4',
          opens_at: opens_at,
          last_worked_at: last_worked_at,
          task_type: :concept_coach,
          completed?: true
        ),
      ],
      course: OpenStruct.new(
        course_id: 2,
        name: 'Physics 101',
        teachers: [
          OpenStruct.new(
            id: '42',
            role_id: '43',
            first_name: 'Andrew',
            last_name: 'Garcia'
          ),
          OpenStruct.new(
            id: '44',
            role_id: '45',
            first_name: 'Bob',
            last_name: 'Newhart'
          )
        ],
        periods: [
          OpenStruct.new(
            id: '46',
            name: '1st',
            chapters: [
              OpenStruct.new(
                id: '47',
                title: 'Ch 1',
                book_location: [1],
                pages: [
                  OpenStruct.new(
                    id: '48',
                    title: 'Pg 1',
                    uuid: 'u48',
                    version: 'v1',
                    book_location: [1, 1],
                    completed: 0,
                    in_progress: 1,
                    not_started: 2,
                    original_performance: 0.0,
                    spaced_practice_performance: 0.1
                  ),
                  OpenStruct.new(
                    id: '49',
                    title: 'Pg 2',
                    uuid: 'u49',
                    version: 'v2',
                    book_location: [1, 2],
                    completed: 3,
                    in_progress: 4,
                    not_started: 5,
                    original_performance: 0.2,
                    spaced_practice_performance: 0.3
                  )
                ]
              ),
              OpenStruct.new(
                id: '50',
                title: 'Ch 2',
                book_location: [2],
                pages: [
                  OpenStruct.new(
                    id: '51',
                    title: 'Pg 3',
                    uuid: 'u51',
                    version: 'v3',
                    book_location: [2, 1],
                    completed: 6,
                    in_progress: 7,
                    not_started: 8,
                    original_performance: 0.4,
                    spaced_practice_performance: 0.5
                  ),
                  OpenStruct.new(
                    id: '52',
                    title: 'Pg 4',
                    uuid: 'u52',
                    version: 'v4',
                    book_location: [2, 2],
                    completed: 9,
                    in_progress: 10,
                    not_started: 11,
                    original_performance: 0.6,
                    spaced_practice_performance: 0.7
                  )
                ]
              )
            ]
          ),
          OpenStruct.new(
            id: '53',
            name: '2nd',
            chapters: [
              OpenStruct.new(
                id: '47',
                title: 'Ch 1',
                book_location: [1],
                pages: [
                  OpenStruct.new(
                    id: '48',
                    title: 'Pg 1',
                    uuid: 'u48',
                    version: 'v1',
                    book_location: [1, 1],
                    completed: 12,
                    in_progress: 13,
                    not_started: 14,
                    original_performance: 0.7,
                    spaced_practice_performance: 0.8
                  ),
                  OpenStruct.new(
                    id: '49',
                    title: 'Pg 2',
                    uuid: 'u49',
                    version: 'v2',
                    book_location: [1, 2],
                    completed: 15,
                    in_progress: 16,
                    not_started: 17,
                    original_performance: 0.9,
                    spaced_practice_performance: 1.0
                  )
                ]
              )
            ]
          )
        ]
      ),
      role: OpenStruct.new(
        id: 34,
        type: 'teacher'
      )
    )
  end

  it "represents dashboard output" do
    representation = described_class.new(data).as_json

    expect(representation).to include(
      "tasks" => a_collection_containing_exactly(
        a_hash_including(
          "id" => '34',
          "title" => "CC2",
          "opens_at" => api_opens_at,
          "last_worked_at" => api_last_worked_at,
          "type" => "concept_coach",
          "complete" => false
        ),
        a_hash_including(
          "id" => '37',
          "title" => "CC1",
          "last_worked_at" => api_last_worked_at,
          "type" => "concept_coach",
          "complete" => false
        ),
        a_hash_including(
          "id" => '89',
          "title" => "CC3",
          "opens_at" => api_opens_at,
          "last_worked_at" => api_last_worked_at,
          "type" => "concept_coach",
          "complete" => true
        ),
        a_hash_including(
          "id" => '99',
          "title" => "CC4",
          "opens_at" => api_opens_at,
          "last_worked_at" => api_last_worked_at,
          "type" => "concept_coach",
          "complete" => true
        ),
      ),
      "role" => {
        "id" => '34',
        "type" => "teacher"
      },
      "course" => {
        "name" => 'Physics 101',
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
                    "uuid" => "u48",
                    "version" => "v1",
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
                    "uuid" => "u49",
                    "version" => "v2",
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
                    "uuid" => "u51",
                    "version" => "v3",
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
                    "uuid" => "u52",
                    "version" => "v4",
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
                    "uuid" => "u48",
                    "version" => "v1",
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
                    "uuid" => "u49",
                    "version" => "v2",
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
  end

end
