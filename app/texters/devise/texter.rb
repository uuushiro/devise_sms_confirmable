# frozen_string_literal: true

if defined?(Textris)
  class Devise::Texter < Textris::Base
    default from: Devise.sms_sender

    def confirmation_instructions(record, token, opts={})
      @token = token
      @resource = record

      text :to => record.phone_number
    end

    def reset_password_instructions(record, token, opts={})
      @token = token
      @resource = record

      text :to => record.phone_number
    end

    def unlock_instructions(record, token, opts={})
      @token = token
      @resource = record

      text :to => record.phone_number
    end

    def email_changed(record, token, opts={})
      @token = token
      @resource = record

      text :to => record.phone_number
    end

    def password_change(record, token, opts={})
      @token = token
      @resource = record

      text :to => record.phone_number
    end
  end
end