require 'rails_helper'

RSpec.describe Tasks::GetPerformanceBookExports do
  it 'returns the export info related to courses' do
    AddUserAsCourseTeacher[course: Entity::Course.create!,
                           user: Entity::User.create!]

    course = Entity::Course.last
    role = Entity::Role.last

    physics_file = File.open('./tmp/Physics_I_Performance.xlsx', 'w+')
    biology_file = File.open('./tmp/Biology_I_Performance.xlsx', 'w+')

    physics_export = FactoryGirl.create(:performance_book_export,
                                        export: physics_file,
                                        course: course,
                                        role: role)
    biology_export = FactoryGirl.create(:performance_book_export,
                                        export: biology_file,
                                        course: course,
                                        role: role)

    export = described_class[course: course, role: role]

    # newest on top

    expect(export.length).to eq 2

    expect(export[0].filename).to eq 'Biology_I_Performance.xlsx'
    expect(export[0].url).to eq biology_export.url
    expect(export[0].created_at).to be_the_same_time_as biology_export.created_at

    expect(export[1].filename).to eq 'Physics_I_Performance.xlsx'
    expect(export[1].url).to eq physics_export.url
    expect(export[1].created_at).to be_the_same_time_as physics_export.created_at

  end
end
