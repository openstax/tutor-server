require 'rails_helper'
require 'vcr_helper'

module Tasks
  RSpec.describe GetStudentActivity, vcr: VCR_OPTS do
    it 'returns all the student task step activity' do
      course = CreateCourse[name: 'Biology I']
      CreateStudentHistory[course: course]

      results = GetStudentActivity[course: course]

      expect(results).to include({
        headers: ['title', 'type', 'status', 'exercise count', 'recovered exercise count',
                 'due at', 'last worked', 'first name', 'last name']
      })
    end
        #period_id: course.periods.first.id.to_s,
        #data_headings: [
          #{ title: 'Homework task plan',
            #plan_id: resp[0][:data_headings][0][:plan_id],
            #type: 'homework',
            #due_at: resp[0][:data_headings][0][:due_at],
            #average: 70.0 },
          #{ title: 'Reading task plan',
            #plan_id: resp[0][:data_headings][1][:plan_id],
            #type: 'reading',
            #due_at: resp[0][:data_headings][1][:due_at] },
          #{ title: 'Homework 2 task plan',
            #plan_id: resp[0][:data_headings][2][:plan_id],
            #type: 'homework',
            #due_at: resp[0][:data_headings][2][:due_at],
            #average: within(0.01).of(54.16) }
        #],
        #students: [{
          #name: 'Student One',
          #first_name: 'Student',
          #last_name: 'One',
          #role: resp[0][:students][0][:role],
          #data: [
            #{
              #type: 'homework',
              #id: resp[0][:students][0][:data][0][:id],
              #status: 'completed',
              #exercise_count: 6,
              #correct_exercise_count: 6,
              #recovered_exercise_count: 0,
              #due_at: resp[0][:students][0][:data][0][:due_at],
              #last_worked_at: resp[0][:students][0][:data][0][:last_worked_at]
            #},
            #{
              #type: 'reading',
              #id: resp[0][:students][0][:data][1][:id],
              #status: 'completed',
              #due_at: resp[0][:students][0][:data][1][:due_at],
              #last_worked_at: resp[0][:students][0][:data][1][:last_worked_at]
            #},
            #{
              #type: 'homework',
              #id: resp[0][:students][0][:data][2][:id],
              #status: 'completed',
              #exercise_count: 4,
              #correct_exercise_count: 3,
              #recovered_exercise_count: 0,
              #due_at: resp[0][:students][0][:data][2][:due_at],
              #last_worked_at: resp[0][:students][0][:data][2][:last_worked_at]
            #}
          #]
        #}, {
          #name: 'Student Two',
          #first_name: 'Student',
          #last_name: 'Two',
          #role: resp[0][:students][1][:role],
          #data: [
            #{
              #type: 'homework',
              #id: resp[0][:students][1][:data][0][:id],
              #status: 'in_progress',
              #exercise_count: 6,
              #correct_exercise_count: 2,
              #recovered_exercise_count: 0,
              #due_at: resp[0][:students][1][:data][0][:due_at],
              #last_worked_at: resp[0][:students][1][:data][0][:last_worked_at]
            #},
            #{
              #type: 'reading',
              #id: resp[0][:students][1][:data][1][:id],
              #status: 'in_progress',
              #due_at: resp[0][:students][1][:data][1][:due_at],
              #last_worked_at: resp[0][:students][1][:data][1][:last_worked_at]
            #},
            #{
              #type: 'homework',
              #id: resp[0][:students][1][:data][2][:id],
              #status: 'in_progress',
              #exercise_count: 4,
              #correct_exercise_count: 1,
              #recovered_exercise_count: 0,
              #due_at: resp[0][:students][1][:data][2][:due_at],
              #last_worked_at: resp[0][:students][1][:data][2][:last_worked_at]
            #}
          #]
        #}]
      #}, {
        #period_id: course.periods.order(:id).last.id.to_s,
        #data_headings: [
          #{ title: 'Homework task plan',
            #plan_id: resp[1][:data_headings][0][:plan_id],
            #type: 'homework',
            #due_at: resp[1][:data_headings][0][:due_at],
            #average: 100.0
          #},
          #{ title: 'Reading task plan',
            #plan_id: resp[1][:data_headings][1][:plan_id],
            #type: 'reading',
            #due_at: resp[1][:data_headings][1][:due_at]
          #},
          #{ title: 'Homework 2 task plan',
            #plan_id: resp[1][:data_headings][2][:plan_id],
            #type: 'homework',
            #due_at: resp[1][:data_headings][2][:due_at]
          #}
        #],
        #students: [{
          #name: 'Student Four',
          #first_name: 'Student',
          #last_name: 'Four',
          #role: resp[1][:students][0][:role],
          #data: [
            #{
              #type: 'homework',
              #id: resp[1][:students][0][:data][0][:id],
              #status: 'not_started',
              #exercise_count: 6,
              #correct_exercise_count: 0,
              #recovered_exercise_count: 0,
              #due_at: resp[1][:students][0][:data][0][:due_at]
            #},
            #{
              #type: 'reading',
              #id: resp[1][:students][0][:data][1][:id],
              #status: 'not_started',
              #due_at: resp[1][:students][0][:data][1][:due_at]
            #},
            #{
              #type: 'homework',
              #id: resp[1][:students][0][:data][2][:id],
              #status: 'not_started',
              #exercise_count: 4,
              #correct_exercise_count: 0,
              #recovered_exercise_count: 0,
              #due_at: resp[1][:students][0][:data][2][:due_at]
            #}
          #]
        #},
        #{
          #name: 'Student Three',
          #first_name: 'Student',
          #last_name: 'Three',
          #role: resp[1][:students][1][:role],
          #data: [
            #{
              #type: 'homework',
              #id: resp[1][:students][1][:data][0][:id],
              #status: 'completed',
              #exercise_count: 6,
              #correct_exercise_count: 6,
              #recovered_exercise_count: 0,
              #due_at: resp[1][:students][1][:data][0][:due_at],
              #last_worked_at: resp[1][:students][1][:data][0][:last_worked_at]
            #},
            #{
              #type: 'reading',
              #id: resp[1][:students][1][:data][1][:id],
              #status: 'not_started',
              #due_at: resp[1][:students][1][:data][1][:due_at]
            #},
            #{
              #type: 'homework',
              #id: resp[1][:students][1][:data][2][:id],
              #status: 'not_started',
              #exercise_count: 4,
              #correct_exercise_count: 0,
              #recovered_exercise_count: 0,
              #due_at: resp[1][:students][1][:data][2][:due_at]
            #}
          #]
        #}]
      #})
    #end
  end
end
