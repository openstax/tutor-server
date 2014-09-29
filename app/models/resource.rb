class Resource < ActiveRecord::Base
  # TODO don't allow direction deletion, instead 
  # delete when no longer referred to (reference counted)
end
