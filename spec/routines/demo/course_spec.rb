require 'rails_helper'

RSpec.describe Demo::Course, type: :routine do
  let!(:catalog_offering)  { FactoryBot.create :catalog_offering, title: 'AP US History' }
  let(:config_base_dir)    { File.join Rails.root, 'spec', 'fixtures', 'demo' }
  let(:user_config)        do
    {
      users: Api::V1::Demo::Users::Representer.new(Demo::Mash.new).from_hash(
        YAML.load_file File.join(config_base_dir, 'users', 'review', 'apush.yml')
      ).deep_symbolize_keys
    }
  end
  let(:course_config_base) do
    {
      course: Api::V1::Demo::Course::Representer.new(Demo::Mash.new).from_hash(
        YAML.load_file File.join(config_base_dir, 'course', 'review', 'apush.yml')
      ).deep_symbolize_keys
    }
  end
  let(:result)             { described_class.call course_config }

  before                   { Demo::Users.call user_config }

  context 'course does not exist' do
    let(:course_config) { course_config_base }

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
      expect(course.grading_templates.size).to eq 2
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

  context 'course already exists' do
    let!(:course)       { FactoryBot.create :course_profile_course }
    let(:course_config) do
      course_config_base.dup.tap { |config| config[:course][:course][:id] = course.id }
    end

    it 'updates the demo course with the given attributes and demo teachers and students' do
      expect do
        expect(result.errors).to be_empty
        expect(result.outputs.course).to eq course
      end.to  not_change { CourseProfile::Models::Course.count }
         .and change     { CourseMembership::Models::Period.count }.by(2)
         .and change     { CourseMembership::Models::Teacher.count }.by(1)
         .and change     { CourseMembership::Models::Student.count }.by(6)
         .and not_change { course.reload.is_college }

      expect(course.name).to eq 'AP US History Review'
      expect(course.offering).to eq catalog_offering
      expect(course.ecosystems.first).to eq catalog_offering.ecosystem

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
end
