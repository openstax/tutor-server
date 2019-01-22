require 'rails_helper'
require_relative 'course_representer_shared_examples'

RSpec.describe Api::V1::CourseEnrollmentsRepresenter, type: :representer do

    let(:course) do
      FactoryBot.create :course_profile_course, name: 'Test course'
    end

    let(:period) {
        FactoryBot.create :course_membership_period, course: course, name: '1st'
    }

    subject(:represented) { described_class.new(course).as_json }

    it 'shows the course name' do
      expect(represented['name']).to eq course.name
    end


    it 'hides archived periods' do
        period_name = period.name
        archived = FactoryBot.create :course_membership_period, course: course, name: 'Deleted!'
        archived.destroy
        periods = represented['periods'].map{|p|p['name']}
        expect(periods).to eq [period_name]
    end

end
