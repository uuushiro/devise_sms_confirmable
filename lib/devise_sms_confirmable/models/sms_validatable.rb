# frozen_string_literal: true

module Devise
  module Models
    # Validatable creates all needed validations for a user phone and password.
    # It's optional, given you may want to create the validations by yourself.
    # Automatically validate if the phone is present, unique and its format is
    # valid. Also tests presence of password, confirmation and length.
    #
    # == Options
    #
    # Validatable adds the following options to devise_for:
    #
    #   * +email_regexp+: the regular expression used to validate e164 format;
    #
    #
    module SmsValidatable
      # All validations used by this module.
      VALIDATIONS = [:validates_presence_of, :validates_uniqueness_of, :validates_format_of,
                     :validates_confirmation_of, :validates_length_of].freeze

      def self.required_fields(klass)
        []
      end

      def self.included(base)
        base.extend ClassMethods
        assert_validations_api!(base)

        base.class_eval do
          validates_presence_of   :phone, if: :phone_required?
          validates_uniqueness_of :phone, allow_blank: true,  if: :will_save_change_to_phone?
          validates_format_of     :phone, with: e164_phone_regexp, allow_blank: true, if: :will_save_change_to_phone?
        end
      end

      def self.assert_validations_api!(base) #:nodoc:
        unavailable_validations = VALIDATIONS.select { |v| !base.respond_to?(v) }

        unless unavailable_validations.empty?
          raise "Could not use :validatable module since #{base} does not respond " <<
                    "to the following methods: #{unavailable_validations.to_sentence}."
        end
      end

      protected

      # Checks whether a password is needed or not. For validations only.
      # Passwords are always required if it's a new record, or if the password
      # or confirmation are being set somewhere.
      def phone_required?
        true
      end

      module ClassMethods
        Devise::Models.config(self, :e164_phone_regexp)
      end
    end
  end
end
