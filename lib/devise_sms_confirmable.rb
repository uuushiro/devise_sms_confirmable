require 'devise'
require 'textris'
require "devise_sms_confirmable/version"
require "devise_sms_confirmable/rails/routes"
require 'devise_sms_confirmable/models/sms_confirmable'
require 'devise_sms_confirmable/engine'

module Devise
  mattr_accessor :sms_confirm_within
  @@sms_confirm_within = nil

  mattr_accessor :sms_confirmation_keys
  @@sms_confirmation_keys = [:phone]

  # Used to send notification to the original user phone when their phone is changed.
  mattr_accessor :send_phone_changed_notification
  @@send_phone_changed_notification = false

  mattr_accessor :parent_texter
  @@parent_texter = "Textris::Base"

  # Phone number which sends Devise SMS.
  mattr_accessor :sms_sender
  @@sms_sender = nil

  mattr_accessor :e164_phone_regexp
  @@e164_phone_regexp = /\A\+?[1-9]\d{1,14}\z/

  # Defines if email should be sms_reconfirmable.
  mattr_accessor :sms_reconfirmable
  @@sms_reconfirmable = true

  # Time interval you can access your account before confirming your account.
  # nil - allows unconfirmed access for unlimited time
  mattr_accessor :allow_sms_unconfirmed_access_for
  @@allow_sms_unconfirmed_access_for = 0.days

  mattr_accessor :sms_reset_password_within
  @@sms_reset_password_within = 10.minutes

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

require_relative '../app/texters/devise/texter'