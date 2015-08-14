require 'rails_helper'

RSpec.describe Api::V1::NewStudentRepresenter, type: :representer do
  let(:student) { { id: 1,
                    course_membership_period_id: 2,
                    entity_role_id: 3,
                    email: 'new@student.com',
                    username: 'student',
                    password: 'secret',
                    first_name: 'Bob',
                    last_name: 'Student',
                    full_name: 'Bob A. Student',
                    deidentifier: 'uhhhhhh',
                    'active?' => true } }

  subject(:represented) { described_class.new(Hashie::Mash.new(student)).to_hash }

  it 'renames course_membership_period_id to period_id' do
    expect(represented['period_id']).to eq('2')
  end

  it 'renames entity_role_id to role_id' do
    expect(represented['role_id']).to eq('3')
  end

  it 'renames active? to is_active' do
    expect(represented['is_active']).to eq(true)
  end
end
