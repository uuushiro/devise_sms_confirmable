# frozen_string_literal: true

require 'shared_admin'

class Admin < ActiveRecord::Base
  include SharedAdmin
end
