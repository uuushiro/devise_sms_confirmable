# frozen_string_literal: true

module Devise
  module Models
    module SMSAuthenticatable
      extend ActiveSupport::Concern

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
