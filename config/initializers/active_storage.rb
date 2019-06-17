# Disable ActiveStorage routes since we currently do not use it
# https://stackoverflow.com/a/53159319
Rails.application.routes_reloader.paths.delete_if { |path| path =~ /activestorage/ }
