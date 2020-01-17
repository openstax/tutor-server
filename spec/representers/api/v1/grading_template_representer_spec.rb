require 'rails_helper'

RSpec.describe Api::V1::GradingTemplateRepresenter, type: :representer do
  let(:represented)    { FactoryBot.create :tasks_grading_template }
  let(:representer)    { described_class.new represented }
  let(:representation) { representer.to_hash }

  context 'id' do
    it 'can be read' do
      expect(representation['id']).to eq represented.id.to_s
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect { representer.from_hash('id' => '42') }.not_to change { represented.id }
    end
  end

  context 'course_id' do
    it 'can be read' do
      expect(representation['course_id']).to eq represented.course_profile_course_id.to_s
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect do
        representer.from_hash('course_id' => '42')
      end.not_to change { represented.course_profile_course_id }
    end
  end

  context 'task_plan_type' do
    it 'can be read' do
      expect(representation['task_plan_type']).to eq represented.task_plan_type
    end

    it 'can be written' do
      value = ([ 'reading', 'homework' ] - [ represented.task_plan_type ]).sample

      expect do
        representer.from_hash('task_plan_type' => value)
      end.to change { represented.task_plan_type }.to(value)
    end
  end

  context 'name' do
    it 'can be read' do
      expect(representation['name']).to eq represented.name
    end

    it 'can be written' do
      expect { representer.from_hash('name' => 'Test') }.to change { represented.name }.to('Test')
    end
  end

  context 'completion_weight' do
    it 'can be read' do
      expect(representation['completion_weight']).to eq represented.completion_weight
    end

    it 'can be written' do
      expect do
        representer.from_hash('completion_weight' => 0.42)
      end.to change { represented.completion_weight }.to(0.42)
    end
  end

  context 'correctness_weight' do
    it 'can be read' do
      expect(representation['correctness_weight']).to eq represented.correctness_weight
    end

    it 'can be written' do
      expect do
        representer.from_hash('correctness_weight' => 0.42)
      end.to change { represented.correctness_weight }.to(0.42)
    end
  end

  context 'auto_grading_feedback_on' do
    it 'can be read' do
      expect(representation['auto_grading_feedback_on']).to eq represented.auto_grading_feedback_on
    end

    it 'can be written' do
      value = ([ 'answer', 'due', 'publish' ] - [ represented.auto_grading_feedback_on ]).sample

      expect do
        representer.from_hash('auto_grading_feedback_on' => value)
      end.to change { represented.auto_grading_feedback_on }.to(value)
    end
  end

  context 'manual_grading_feedback_on' do
    it 'can be read' do
      expect(representation['manual_grading_feedback_on']).to(
        eq represented.manual_grading_feedback_on
      )
    end

    it 'can be written' do
      value = ([ 'grade', 'publish' ] - [ represented.manual_grading_feedback_on ]).sample

      expect do
        representer.from_hash('manual_grading_feedback_on' => value)
      end.to change { represented.manual_grading_feedback_on }.to(value)
    end
  end

  context 'late_work_penalty_applied' do
    it 'can be read' do
      expect(representation['late_work_penalty_applied']).to(
        eq represented.late_work_penalty_applied
      )
    end

    it 'can be written' do
      val = ([ 'never', 'immediately', 'daily' ] - [ represented.late_work_penalty_applied ]).sample
      expect do
        representer.from_hash('late_work_penalty_applied' => val)
      end.to change { represented.late_work_penalty_applied }.to(val)
    end
  end

  context 'late_work_penalty' do
    it 'can be read' do
      expect(representation['late_work_penalty']).to eq represented.late_work_penalty
    end

    it 'can be written' do
      expect do
        representer.from_hash('late_work_penalty' => 0.42)
      end.to change { represented.late_work_penalty }.to(0.42)
    end
  end

  context 'default_open_time' do
    it 'can be read' do
      expect(representation['default_open_time']).to eq represented.default_open_time
    end

    it 'can be written' do
      expect do
        representer.from_hash('default_open_time' => '13:42')
      end.to change { represented.default_open_time }.to('13:42')
    end
  end

  context 'default_due_time' do
    it 'can be read' do
      expect(representation['default_due_time']).to eq represented.default_due_time
    end

    it 'can be written' do
      expect do
        representer.from_hash('default_due_time' => '13:42')
      end.to change { represented.default_due_time }.to('13:42')
    end
  end

  context 'default_due_date_offset_days' do
    it 'can be read' do
      expect(representation['default_due_date_offset_days']).to(
        eq represented.default_due_date_offset_days
      )
    end

    it 'can be written' do
      expect do
        representer.from_hash('default_due_date_offset_days' => 42)
      end.to change { represented.default_due_date_offset_days }.to(42)
    end
  end

  context 'default_close_date_offset_days' do
    it 'can be read' do
      expect(representation['default_close_date_offset_days']).to(
        eq represented.default_close_date_offset_days
      )
    end

    it 'can be written' do
      expect do
        representer.from_hash('default_close_date_offset_days' => 42)
      end.to change { represented.default_close_date_offset_days }.to(42)
    end
  end

  context 'created_at' do
    it 'can be read' do
      expect(representation['created_at']).to(
        eq DateTimeUtilities.to_api_s(represented.created_at)
      )
    end

    it 'cannot be written (attempts are silently ignored)' do
      expect do
        representer.from_hash('created_at' => DateTimeUtilities.to_api_s(Time.current))
      end.not_to change { represented.created_at }
    end
  end
end
