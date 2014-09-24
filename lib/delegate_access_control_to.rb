# Copyright 2011-2014 Rice University. Licensed under the Affero General Public 
# License version 3 or later.  See the COPYRIGHT file for details.

module DelegateAccessControlTo

  def delegate_access_control_to(klass, options={})
    delegate_access_control options.merge({to: klass})
  end
   
end

ActiveRecord::Base.extend DelegateAccessControlTo
