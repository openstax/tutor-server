require_relative 'demo_base'
require_relative 'demo/content_configuration'

# Adds students to the course periods, assigns Sets up the periods and students for a course
# and then generates activity for them

class Demo002 < DemoBase

  lev_routine

  protected

  def exec(book: :all, print_logs: true, random_seed: nil)
    set_print_logs(print_logs)
    set_random_seed(random_seed)

    ContentConfiguration[book.to_sym].each do | content |
      content.assignments.each do | assignment |

        log("Creating #{assignment.type} #{assignment.title} for course #{content.course_name} (#{assignment.step_types.length} steps)")

        task_plan = if assignment.type == 'reading'
                 assign_ireading(course: content.course,
                                 chapter_sections: assignment.chapter_sections,
                                 title: assignment.title)
               else
                 assign_homework(course: content.course,
                                 chapter_sections: assignment.chapter_sections,
                                 title: assignment.title,
                                 num_exercises: assignment.num_exercises)
               end

        assignment.periods.each do | period |
          log("  Adding tasking plan for period #{period[:index]}")

          add_tasking_plan(task_plan: task_plan,
                           to: content.course.periods.order(:created_at).at(period[:index]),
                           opens_at: period.opens_at,
                           due_at: period.due_at)

        end

        log("  Distributing tasks")
        tasks = distribute_tasks(task_plan:task_plan)

        responses_list = new_responses_list(
          students: assignment.periods.map{|period| period.students.map(&:to_a) }.flatten(1),
          assignment_type: assignment.type.to_sym,
          step_types: assignment.step_types,
        )

        tasks.each_with_index do | task, index |
          user = task.taskings.first.role.user.user
          responses = responses_list[ user.profile.id ]
          unless responses
            raise "#{assignment.title} period index #{period['index']} has no responses for task #{index} for user #{user.profile.id} #{user.username}"
          end
          log("    Working task # #{index}")
          work_task(task: task, responses: responses)
        end

      end
    end

    Timecop.return_all
  end


end
