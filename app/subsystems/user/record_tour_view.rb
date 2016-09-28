module User


  class RecordTourView
    lev_routine express_output: :view

    protected

    def exec(user:, tour_identifier: )

      tour = Models::Tour.find_or_create_by(identifier: tour_identifier)
      transfer_errors_from tour, {type: :verbatim}, true
      outputs[:tour] = tour
      if tour.errors.none?
        view = Models::TourView.find_or_initialize_by(tour: tour, user_profile_id: user.id)
        view.view_count += 1
        view.save
        transfer_errors_from view, {type: :verbatim}, true
        outputs[:view] = view
      end

    end

  end

end
