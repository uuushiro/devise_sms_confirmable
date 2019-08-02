# frozen_string_literal: true

module SharedUser
  extend ActiveSupport::Concern

  included do
    devise :database_authenticatable, :sms_confirmable, sms_reconfirmable: false

    attr_accessor :other_key

    # They need to be included after Devise is called.
    extend ExtendMethods
  end

  def raw_sms_confirmation_token
    @raw_sms_confirmation_token
  end

  module ExtendMethods
    def new_with_session(params, session)
      super.tap do |user|
        if data = session["devise.facebook_data"]
          user.phone = data["phone"]
          user.confirmed_at = Time.now
        end
      end
    end
  end
end