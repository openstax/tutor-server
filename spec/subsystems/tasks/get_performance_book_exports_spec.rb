require 'rails_helper'

RSpec.describe Tasks::GetPerformanceBookExports do
  it 'returns the export info related to courses' do
    AddUserAsCourseTeacher[course: Entity::Course.create!,
                           user: Entity::User.create!]

    course = Entity::Course.last
    role = Entity::Role.last

    physics = FactoryGirl.create(:performance_book_export,
                                 filename: 'Physics_I_Performance',
                                 course: course,
                                 role: role)

    biology = FactoryGirl.create(:performance_book_export,
                                 filename: 'Biology_I_Performance',
                                 course: course,
                                 role: role)

    exports = described_class[course: course, role: role]

    # newest on top
    expect(exports).to eq([
      { 'filename' => 'Biology_I_Performance.xlsx',
        'url' => '/something/here/Biology_I_Performance.xlsx',
        'created_at' => biology.created_at },
      { 'filename' => 'Physics_I_Performance.xlsx',
        'url' => '/something/here/Physics_I_Performance.xlsx',
        'created_at' => physics.created_at }
    ])
  end
end
