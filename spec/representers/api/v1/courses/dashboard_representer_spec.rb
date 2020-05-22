require 'rails_helper'

RSpec.describe Api::V1::Courses::DashboardRepresenter, type: :representer do
  let(:opens_at)           { Time.current }
  let(:api_opens_at)       { DateTimeUtilities.to_api_s(opens_at) }

  let(:due_at)             { opens_at + 1.week }
  let(:api_due_at)         { DateTimeUtilities.to_api_s(due_at) }

  let(:closes_at)          { due_at + 1.week }
  let(:api_closes_at)      { DateTimeUtilities.to_api_s(closes_at) }

  let(:last_worked_at)     { opens_at + 1.day }
  let(:api_last_worked_at) { DateTimeUtilities.to_api_s(last_worked_at) }

  let(:published_at)       { opens_at }

  let(:publish_job_uuid)   { '394839483948' }

  let(:publish_job_url)    { 'https://www.example.com' }

  let(:publish_job) do
    OpenStruct.new(
      id: publish_job_uuid,
      state: OpenStruct.new(name: 'succeeded'),
      progress: 1.0,
      data: { url: publish_job_url }.stringify_keys,
      errors: []
    )
  end

  let(:publish_job_representation) do
    {
      id: publish_job_uuid,
      status: 'succeeded',
      progress: 1.0,
      url: publish_job_url,
      data: { url: publish_job_url },
      errors: []
    }.deep_stringify_keys
  end

  let(:data) do
    OpenStruct.new(
      plans: [
        OpenStruct.new(
          id: 23,
          title: 'HW1',
          is_trouble: false,
          type: 'homework',
          is_draft?: false,
          is_publishing?: true,
          is_published?: true,
          first_published_at: published_at,
          last_published_at: published_at,
          publish_last_requested_at: published_at,
          publish_job_uuid: publish_job_uuid,
          publish_job: publish_job,
          tasking_plans: [
            OpenStruct.new(
              target_id: 42,
              target_type: 'CourseMembership::Models::Period',
              opens_at: opens_at,
              due_at: due_at,
              closes_at: closes_at
            )
          ]
        )
      ],
      tasks: [
        OpenStruct.new(
          id: 34,
          title: 'HW2',
          opens_at: opens_at,
          due_at: due_at,
          closes_at: closes_at,
          auto_grading_feedback_available?: true,
          manual_grading_feedback_available?: false,
          last_worked_at: last_worked_at,
          task_type: :homework,
          completed?: false,
          past_due?: false,
          extended?: false,
          steps_count: 5,
          actual_and_placeholder_exercise_count: 5,
          completed_steps_count: 4,
          completed_on_time_steps_count: 3,
          completed_exercise_count: 4,
          completed_on_time_exercise_steps_count: 3,
          correct_exercise_count: 2,
          ungraded_step_count: 1,
          withdrawn?: true
        ),
        OpenStruct.new(
          id: 37,
          title: 'Reading 1',
          auto_grading_feedback_available?: false,
          manual_grading_feedback_available?: false,
          opens_at: opens_at,
          due_at: due_at,
          closes_at: closes_at,
          last_worked_at: last_worked_at,
          task_type: :reading,
          completed?: false,
          past_due?: false,
          extended?: false,
          steps_count: 8,
          actual_and_placeholder_exercise_count: 7,
          completed_steps_count: 6,
          completed_on_time_steps_count: 5,
          completed_exercise_count: 6,
          completed_on_time_exercise_steps_count: 5,
          correct_exercise_count: 4,
          ungraded_step_count: 3,
          withdrawn?: false
        ),
        OpenStruct.new(
          id: 89,
          title: 'HW3',
          auto_grading_feedback_available?: true,
          manual_grading_feedback_available?: false,
          opens_at: opens_at,
          due_at: due_at,
          closes_at: closes_at,
          last_worked_at: last_worked_at,
          task_type: :homework,
          completed?: true,
          past_due?: true,
          extended?: false,
          steps_count: 8,
          actual_and_placeholder_exercise_count: 8,
          completed_steps_count: 8,
          completed_on_time_steps_count: 7,
          completed_exercise_count: 8,
          completed_on_time_exercise_steps_count: 7,
          correct_exercise_count: 6,
          ungraded_step_count: 5,
          withdrawn?: false
        ),
        OpenStruct.new(
          id: 99,
          title: 'Ext1',
          opens_at: opens_at,
          due_at: due_at,
          closes_at: closes_at,
          last_worked_at: last_worked_at,
          task_type: :external,
          completed?: true,
          past_due?: true,
          extended?: false,
          withdrawn?: false
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
        ]
      ),
      role: OpenStruct.new(
        id: 34,
        type: 'teacher'
      )
    )
  end

  it 'represents dashboard output' do
    representation = described_class.new(data).as_json

    expect(representation).to include(
      'plans' => [
        a_hash_including(
          'id' => '23',
          'title' => 'HW1',
          'is_trouble' => false,
          'type' => 'homework',
          'is_draft' => false,
          'is_publishing' => true,
          'is_published' => true,
          'first_published_at' => be_kind_of(String),
          'last_published_at' => be_kind_of(String),
          'publish_last_requested_at' => be_kind_of(String),
          'publish_job' => publish_job_representation.deep_stringify_keys,
          'tasking_plans' => [
            {
              'target_id' => '42',
              'target_type' => 'period',
              'opens_at' => api_opens_at,
              'due_at' => api_due_at,
              'closes_at' => api_closes_at
            }
          ]
        )
      ],
      'tasks' => a_collection_containing_exactly(
        a_hash_including(
          'id' => '34',
          'title' => 'HW2',
          'opens_at' => api_opens_at,
          'due_at' => api_due_at,
          'closes_at' => api_closes_at,
          'last_worked_at' => api_last_worked_at,
          'type' => 'homework',
          'complete' => false,
          'is_past_due' => false,
          'is_extended' => false,
          'steps_count' => 5,
          'exercise_count' => 5,
          'completed_steps_count' => 4,
          'completed_on_time_steps_count' => 3,
          'complete_exercise_count' => 4,
          'completed_on_time_exercise_steps_count' => 3,
          'correct_exercise_count' => 2,
          'ungraded_step_count' => 1,
          'is_deleted' => true
        ),
        a_hash_including(
          'id' => '37',
          'title' => 'Reading 1',
          'opens_at' => api_opens_at,
          'due_at' => api_due_at,
          'closes_at' => api_closes_at,
          'last_worked_at' => api_last_worked_at,
          'type' => 'reading',
          'complete' => false,
          'is_past_due' => false,
          'is_extended' => false,
          'steps_count' => 8,
          'exercise_count' => 7,
          'completed_steps_count' => 6,
          'completed_on_time_steps_count' => 5,
          'complete_exercise_count' => 6,
          'completed_on_time_exercise_steps_count' => 5,
          'ungraded_step_count' => 3,
          'is_deleted' => false
        ),
        a_hash_including(
          'id' => '89',
          'title' => 'HW3',
          'opens_at' => api_opens_at,
          'due_at' => api_due_at,
          'last_worked_at' => api_last_worked_at,
          'type' => 'homework',
          'complete' => true,
          'is_past_due' => true,
          'is_extended' => false,
          'steps_count' => 8,
          'exercise_count' => 8,
          'completed_steps_count' => 8,
          'completed_on_time_steps_count' => 7,
          'complete_exercise_count' => 8,
          'completed_on_time_exercise_steps_count' => 7,
          'correct_exercise_count' => 6,
          'ungraded_step_count' => 5,
          'is_deleted' => false
        ),
        a_hash_including(
          'id' => '99',
          'title' => 'Ext1',
          'opens_at' => api_opens_at,
          'due_at' => api_due_at,
          'closes_at' => api_closes_at,
          'last_worked_at' => api_last_worked_at,
          'type' => 'external',
          'complete' => true,
          'is_past_due' => true,
          'is_extended' => false,
          'is_deleted' => false
        )
      ),
      'role' => {
        'id' => '34',
        'type' => 'teacher'
      },
      'course' => {
        'name' => 'Physics 101',
        'teachers' => [
          {
            'id' => '42',
            'role_id' => '43',
            'first_name' => 'Andrew',
            'last_name' => 'Garcia'
          },
          {
            'id' => '44',
            'role_id' => '45',
            'first_name' => 'Bob',
            'last_name' => 'Newhart'
          }
        ]
      }
    )

    expect(representation['tasks'][1]).to_not have_key 'correct_exercise_count'
    expect(representation['tasks'][2]).to     have_key 'correct_exercise_count'
  end
end
