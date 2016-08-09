module WebviewHelper

  # Generates data for the FE to read as it boots up
  def bootstrap_data
    Api::V1::BootstrapDataRepresenter.new(current_user).to_json(
      user_options: {
        tutor_api_url: api_root_url,
        flash: flash.to_hash
      }
    )
  end

end
