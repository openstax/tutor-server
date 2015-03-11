class CalculateTaskPlanStatistics

  lev_routine

  protected

  def generate_page_data( min:10, include_previous: false )
    stat = {
      page: {
        id: rand(1000)+100,
        number: "#{rand(5)+1}.#{rand(5)+1}",
        title: Faker::Company.bs
      },
      correct_count: rand(10)+min,
      incorrect_count: rand(4),
      student_count: rand(14)+min
    }
    if include_previous
      stat[:previous_attempt] = generate_page_data
    end
    stat
  end

  def generate_period_stat_data(min:10)
    {
     total_count: rand(20)+min,
     complete_count: rand(15)+min,
     partially_complete_count: rand(4)+min,
     current_pages: 0.upto(rand(2)+2).map{ generate_page_data(min:min) },
     spaced_pages:  0.upto(rand(1)+1).map{ generate_page_data(min:min, include_previous:true) }
    }
  end

  def exec(plan:nil)
    outputs[:statistics] = Hashie::Mash.new({
      course: generate_period_stat_data(min:20),
      periods: 0.upto(rand(3)+2).map do {
        id: rand(1000)+100,
        title: Faker::Company.bs
      }.merge( generate_period_stat_data(min:10) )
      end
    })
  end

end
