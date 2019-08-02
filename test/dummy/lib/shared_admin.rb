# frozen_string_literal: true

module SharedAdmin
  extend ActiveSupport::Concern

  included do
    devise :database_authenticatable, :registerable,
           :timeoutable, :recoverable, :lockable, :sms_confirmable,
           unlock_strategy: :time, lock_strategy: :none,
           allow_sms_unconfirmed_access_for: 2.weeks, sms_reconfirmable: true

  end

  def raw_sms_confirmation_token
    @raw_sms_confirmation_token
  end
end
