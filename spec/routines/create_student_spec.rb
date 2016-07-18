require 'rails_helper'

describe CreateStudent, type: :routine do
  let(:course) { CreateCourse[name: 'A good course'] }
  let(:period) { CreatePeriod[course: course] }

  it 'creates a new student in the given period with a username and a password' do
    result = nil
    expect {
      result = CreateStudent.call(period: period, username: 'dummyuser', password: 'pass',
                                  first_name: 'Dummy', last_name: 'User', full_name: 'Dummy User')
    }.to change{ User::Models::Profile.count }.by(1)
    expect(result.errors).to be_empty

    student = result.outputs.student
    expect(student.username).to eq 'dummyuser'
    expect(student.first_name).to eq 'Dummy'
    expect(student.last_name).to eq 'User'
    expect(student.full_name).to eq 'Dummy User'
    expect(student.period).to eq period.to_model
  end

  it 'creates a new student in the given period with an email address' do
    result = nil
    expect {
      result = CreateStudent.call(period: period, email: 'dummy@example.com',
                                  first_name: 'Dummy', last_name: 'User', full_name: 'Dummy User')
    }.to change{ User::Models::Profile.count }.by(1)
    expect(result.errors).to be_empty

    student = result.outputs.student
    expect(student.first_name).to eq 'Dummy'
    expect(student.last_name).to eq 'User'
    expect(student.full_name).to eq 'Dummy User'
    expect(student.period).to eq period.to_model
  end
end
