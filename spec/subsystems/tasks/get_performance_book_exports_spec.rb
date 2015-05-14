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

    exports = described_class[course: course, role: role]

    exports = exports.collect{|export| HashWithIndifferentAccess.new(export.to_hash)}

    # newest on top
    expect(exports).to eq([
      { 'filename' => 'Biology_I_Performance.xlsx',
        'url' => biology_export.url,
        'created_at' => biology_export.created_at },
      { 'filename' => 'Physics_I_Performance.xlsx',
        'url' => physics_export.url,
        'created_at' => physics_export.created_at }
    ])
  end
end
