module WebviewHelper

  # Generates data for the FE to read as it boots up
  def bootstrap_data

    Api::V1::BootstrapDataRepresenter.new(current_user).to_json(
      tutor_notices_url: api_notifications_url
    )
  end

end
