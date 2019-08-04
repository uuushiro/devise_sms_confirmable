# frozen_string_literal: true

if defined?(Textris)
  class Devise::Texter < Textris::Base
    
    def confirmation_instructions(record, token, opts={})
      @token = token
      @resource = record

      headers = { to: @resource.phone }.merge(opts)

      send_sms(headers)
    end

    def reset_password_instructions(record, token, opts={})
      @token = token
      @resource = record

      headers = { to: @resource.phone }.merge(opts)

      send_sms(headers)
    end

    def unlock_instructions(record, token, opts={})
      @token = token
      @resource = record

      headers = { to: @resource.phone }.merge(opts)

      send_sms(headers)
    end

    def phone_changed(record, token, opts={})
      @token = token
      @resource = record

      headers = { to: @resource.phone }.merge(opts)

      send_sms(headers)
    end

    def password_change(record, token, opts={})
      @token = token
      @resource = record

      headers = { to: @resource.phone }.merge(opts)

      send_sms(headers)
    end

    def send_sms(headers)
      text(to: headers[:to], from: Devise.sms_sender)
    end
  end
end