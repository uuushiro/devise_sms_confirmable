# frozen_string_literal: true

if defined?(Textris)
  class Devise::Texter < Textris::Base
    default from: "+48666777888"

    def confirmation_instructions(record, token, opts={})
      @token = token
      @resource = record

      headers = { to: @resource.phone }.merge(opts)

      text to: headers[:to]
    end

    def reset_password_instructions(record, token, opts={})
      @token = token
      @resource = record

      headers = { to: @resource.phone }.merge(opts)

      text to: headers[:to]
    end

    def unlock_instructions(record, token, opts={})
      @token = token
      @resource = record

      headers = { to: @resource.phone }.merge(opts)

      text to: headers[:to]
    end

    def phone_changed(record, token, opts={})
      @token = token
      @resource = record

      headers = { to: @resource.phone }.merge(opts)

      text to: headers[:to]
    end

    def password_change(record, token, opts={})
      @token = token
      @resource = record

      headers = { to: @resource.phone }.merge(opts)

      text to: headers[:to]
    end
  end
end