require 'rails_helper'

RSpec.describe Demo::Course, type: :routine do
  let!(:catalog_offering) { FactoryBot.create :catalog_offering, title: 'AP US History' }
  let(:config_base_dir)   { File.join Rails.root, 'spec', 'fixtures', 'demo' }
  let(:user_config)       do
    {
      users: Api::V1::Demo::Users::Representer.new(Hashie::Mash.new).from_hash(
        YAML.load_file File.join(config_base_dir, 'users', 'review', 'apush.yml')
      ).deep_symbolize_keys
    }
  end
  let(:course_config)     do
    {
      course: Api::V1::Demo::Course::Representer.new(Hashie::Mash.new).from_hash(
        YAML.load_file File.join(config_base_dir, 'course', 'review', 'apush.yml')
      ).deep_symbolize_keys
    }
  end
  let(:result)            { described_class.call course_config }

  before                  { Demo::Users.call user_config }

  it 'creates a demo course with demo teachers and students' do
    course = nil
    expect do
      expect(result.errors).to be_empty
      course = result.outputs.course
    end.to  change { CourseProfile::Models::Course.count }.by(1)
       .and change { CourseMembership::Models::Period.count }.by(2)
       .and change { CourseMembership::Models::Teacher.count }.by(1)
       .and change { CourseMembership::Models::Student.count }.by(6)

    expect(course.name).to eq 'AP US History Review'
    expect(course.offering).to eq catalog_offering
    expect(course.ecosystems).to eq [catalog_offering.ecosystem]
    expect(course.is_college).to eq true

    teachers = course.teachers
    expect(teachers.map(&:username)).to eq [ 'reviewteacher' ]

    periods = course.periods
    expect(periods.size).to eq 2
    periods.each do |period|
      expect(period.name).to be_in ['1st', '2nd']

      students = period.students
      expect(students.size).to eq 3
      students.each { |student| expect(student.username).to match /reviewstudent\d/ }
    end
  end
end
