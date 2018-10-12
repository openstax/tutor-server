module Pgdb
  extend self

  def name
    ActiveRecord::Base.connection_config[:database]
  end

  def cmd_line_flags
    flags = []
    config = ActiveRecord::Base.connection_config
    %i{host username port}.each do|flag|
      flags.push("--#{flag}", config[flag]) if config[flag]
    end
    flags

  end

  def env
    { 'PGPASSWORD' => ActiveRecord::Base.connection_config[:password] }
  end

end
