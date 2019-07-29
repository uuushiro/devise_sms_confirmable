# frozen_string_literal: true

module Devise
  module Models
    module SMSAuthenticatable
      extend ActiveSupport::Concern

      BLACKLIST_FOR_SERIALIZATION = [:sms_confirmed_at, :sms_confirmation_sent_at, :unconfirmed_phone_number]

      # Redefine inspect using serializable_hash, to ensure we don't accidentally
      # leak passwords into exceptions.
      def inspect
        inspection = serializable_hash.collect do |k,v|
          "#{k}: #{respond_to?(:attribute_for_inspect) ? attribute_for_inspect(k) : v.inspect}"
        end
        "#<#{self.class} #{inspection.join(", ")}>"
      end

      protected

      def devise_texter
        Devise.texter
      end

      def send_sms_devise_notification(notification, *args)
        message = devise_texter.send(notification, self, *args)
        message.deliver_now
      end
    end
  end
end
