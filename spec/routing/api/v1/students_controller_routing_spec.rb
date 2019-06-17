require "rails_helper"

RSpec.describe Api::V1::StudentsController, type: :routing, api: true, version: :v1 do

  context 'PATCH /api/user/courses/:course_id/student(/role/:role_id)' do
    context 'no role_id' do
      it 'routes to #update_self' do
        expect(patch '/api/user/courses/42/student').to(
          route_to('api/v1/students#update_self', format: 'json', course_id: '42')
        )
      end
    end

    context 'role_id in path' do
      it 'routes to #update_self' do
        expect(patch '/api/user/courses/21/student/role/42').to(
          route_to('api/v1/students#update_self', format: 'json', course_id: '21', role_id: '42')
        )
      end
    end

    context 'role_id in query params' do
      it 'routes to #update_self' do
        expect(patch '/api/user/courses/21/student?role_id=42').to(
          route_to('api/v1/students#update_self', format: 'json', course_id: '21', role_id: '42')
        )
      end
    end
  end

  context 'PATCH /api/students/:student_id' do
    it 'routes to #update' do
      expect(patch '/api/students/42').to route_to('api/v1/students#update',
                                                   format: 'json', id: '42')
    end
  end

  context 'DELETE /api/students/:student_id' do
    it 'routes to #destroy' do
      expect(delete '/api/students/42').to route_to('api/v1/students#destroy',
                                                    format: 'json', id: '42')
    end
  end

  context 'PUT /api/students/:student_id/restore' do
    it 'routes to #restore' do
      expect(put '/api/students/42/restore').to route_to('api/v1/students#restore',
                                                         format: 'json', id: '42')
    end
  end

  context 'PUT /api/students/:student_id/undrop' do
    it 'routes to #restore' do
      expect(put '/api/students/42/undrop').to route_to('api/v1/students#restore',
                                                        format: 'json', id: '42')
    end
  end

end
