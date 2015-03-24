require 'rails_helper'
require 'tasks/sprint/sprint_008/main'

RSpec.describe Sprint008::Main, type: :request, :api => true, :version => :v1 do

  let!(:debug)           { false }
  let!(:application)     { FactoryGirl.create :doorkeeper_application }

  it "works" do

    outputs = Sprint008::Main.call.outputs

    teacher_token             = token_for(outputs[:teacher])
    student_token             = token_for(outputs[:student])
    teacher_and_student_token = token_for(outputs[:teacher_and_student])             

    route = '/api/courses'
    api_get(route, teacher_token)
    print_response(outputs[:teacher], route, response)

    route = "/api/courses/#{outputs[:course1].id}/plans"
    api_get(route, teacher_token)
    print_response(outputs[:teacher], route, response)

    route = "/api/courses/#{outputs[:course1].id}/tasks"
    api_get(route, student_token)
    print_response(outputs[:student], route, response)

    route = "/api/courses/#{outputs[:course1].id}/events"
    api_get(route, student_token)
    print_response(outputs[:student], route, response)

    route = "/api/courses/#{outputs[:course1].id}/events"
    api_get(route, teacher_token)
    print_response(outputs[:teacher], route, response)

    route = "/api/courses/#{outputs[:course1].id}/practice"
    api_get(route, student_token)
    print_response(outputs[:student], route, response)    

    first_task_plan = TaskPlan.where(owner: outputs.course1).first
    route = "/api/plans/#{first_task_plan.id}"
    api_get(route, teacher_token)
    print_response(outputs[:teacher], route, response)
  end

  def token_for(user)
    FactoryGirl.create :doorkeeper_access_token,
                       application: application,
                       resource_owner_id: user.id
  end

  def print_response(user, route, response)
    return if !debug

    puts "The user `#{user.account.username}` accessed `#{route}` and got:\n\n"

    puts "```json"
    puts JSON.pretty_generate(response.body_as_hash)
    puts "```"
  end

end
