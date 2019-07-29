require 'devise'
require 'textris'
require "devise_sms_confirmable/version"
require "devise_sms_confirmable/rails/routes"
require 'devise_sms_confirmable/models/sms_confirmable'
require 'devise_sms_confirmable/engine'
require_relative '../app/texters/devise/texter'

module Devise
  mattr_accessor :sms_confirm_within
  @@sms_confirm_within = 2.days

  mattr_accessor :sms_confirmation_keys
  @@sms_confirmation_keys = [:phone_number]

  mattr_accessor :parent_texter
  @@parent_texter = "Textris::Base"

  # Phone number which sends Devise SMS.
  mattr_accessor :sms_sender
  @@sms_sender = nil

  # Get the sms sender class from the texter reference object.
  def self.texter
    @@texter_ref.get
  end

  # Set the smser reference object to access the smser.
  def self.texter=(class_name)
    @@texter_ref = ref(class_name)
  end

  self.texter = "Devise::Texter"
end

routes = [nil, :new]
Devise.add_module :sms_confirmable, controller: :sms_confirmations, route: { sms_confirmation: routes }