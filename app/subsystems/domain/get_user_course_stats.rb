class Domain::GetUserCourseStats
  lev_routine express_output: :course_stats

  uses_routine CourseProfile::GetProfile,
    translations: { outputs: { type: :verbatim } },
    as: :get_course_profile

  uses_routine CourseContent::GetCourseBooks,
    translations: { outputs: { type: :verbatim } },
    as: :get_course_books

  uses_routine Content::VisitBook,
    translations: { outputs: { type: :verbatim } },
    as: :get_book_toc

  protected
  def exec(user:, course:)
    compile_course_stats
  end

  private
  def compile_course_stats
    outputs[:course_stats] = {
      title: 'Physics',
      topics: [
        { id: 123,
          title: 'Kinematics',
          number: '5',
          questions_answered_count: 48,
          current_level: 0.5,
          page_ids: [ 234, 345 ],
          practice_count: 12
        },
        { id: 456,
          title: 'Other Physics',
          number: '5.1',
          questions_answered_count: 38,
          current_level: 0.4,
          page_ids: [ 231, 897 ],
          practice_count: 8
        },
        { id: 789,
          title: 'Excellent Topics',
          number: '5.2',
          questions_answered_count: 42,
          current_level: 0.8,
          page_ids: [ 28, 89 ],
          practice_count: 15
        }
      ]
    }
  end

  def collect_book_parts
    outputs.book_parts.collect do |book_part|
      { id: book_part.id,
        title: book_part.title,
        number: book_part.path,
        page_ids: book_part.page_ids }
    end
  end
end
