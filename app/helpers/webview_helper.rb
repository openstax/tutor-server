module WebviewHelper


  # Generates data for the FE to read as it boots up
  def bootstrap_data
    json_escape({
      user: Api::V1::UserProfileRepresenter.new(current_user),
      courses: Api::V1::CoursesRepresenter.new(
        CollectCourseInfo[user: current_user, with: [:roles, :periods, :ecosystem]]
      )
    }.to_json)
  end

  # Returns the script/stylesheet tags needed to load the front-end app
  def tutor_app_tags
    path =
      Rails.application.secrets[:app_assets_base_url] +
      (request.path =~ %r{^/exercises} ? 'exercises' : 'tutor')
    %(
    <link rel='stylesheet' href='#{path}.css' />
    <script type='text/javascript' src='#{path}.js' async></script>
    <script src="//cdn.mathjax.org/mathjax/2.5-latest/MathJax.js?config=TeX-MML-AM_HTMLorMML-full&amp;delayStartupUntil=configured" async></script>
    <script id="tutor-boostrap-data" type="application/json">#{bootstrap_data}</script>
    ).html_safe
  end

end
