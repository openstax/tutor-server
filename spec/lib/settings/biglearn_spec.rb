require 'rails_helper'

RSpec.describe Settings::Biglearn, type: :lib do
  it 'can get the client_name' do
    expect(described_class.client_name).to eq 'fake'
  end

  it 'can set the client_name' do
    expect(described_class.client_name).to eq 'fake'

    described_class.client_name = 'real'
    Settings::Db.store.object('biglearn_client_name').try!(:expire_cache)
    expect(described_class.client_name).to eq 'real'

    described_class.client_name = 'fake'
    Settings::Db.store.object('biglearn_client_name').try!(:expire_cache)
    expect(described_class.client_name).to eq 'fake'
  end

  it 'can get the student_clues_algorithm_name' do
    expect(described_class.student_clues_algorithm_name).to eq 'local_query'
  end

  it 'can get the teacher_clues_algorithm_name' do
    expect(described_class.teacher_clues_algorithm_name).to eq 'local_query'
  end

  it 'can get the assignment_spes_algorithm_name' do
    expect(described_class.assignment_spes_algorithm_name).to eq 'student_driven_local_query'
  end

  it 'can get the assignment_pes_algorithm_name' do
    expect(described_class.assignment_pes_algorithm_name).to eq 'local_query'
  end

  it 'can get the practice_worst_areas_algorithm_name' do
    expect(described_class.practice_worst_areas_algorithm_name).to eq 'local_query'
  end
end
