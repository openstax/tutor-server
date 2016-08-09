class Admin::SchoolsDestroy
  lev_handler

  uses_routine SchoolDistrict::DeleteSchool, as: :delete_school,
                                             translations: { outputs: { type: :verbatim } }

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    run(:delete_school, school: options[:school])
  end
end
