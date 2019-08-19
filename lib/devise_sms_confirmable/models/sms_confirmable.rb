require_relative 'sms_authenticatable'
require_relative 'sms_validatable'

module Devise
  module Models
    module SmsConfirmable
      extend ActiveSupport::Concern
      include Devise::Models::SmsAuthenticatable

      included do
        before_create :generate_sms_confirmation_token, if: :sms_confirmation_required?
        after_create :skip_sms_reconfirmation_in_callback!, if: :send_sms_confirmation_notification?
        before_update :postpone_phone_change_until_confirmation_and_regenerate_sms_confirmation_token, if: :postpone_phone_change?
        after_update :send_phone_changed_notification, if: :send_phone_changed_notification?

        after_commit :send_on_create_sms_confirmation_instructions, on: :create, if: :send_sms_confirmation_notification?
        after_commit :send_sms_reconfirmation_instructions, on: :update, if: :sms_reconfirmation_required?
      end

      def initialize(*args, &block)
        @bypass_sms_confirmation_postpone = false
        @skip_sms_reconfirmation_in_callback = false
        @sms_reconfirmation_required = false
        @skip_sms_confirmation_notification = false
        @raw_sms_confirmation_token = nil
        super
      end

      def self.required_fields(klass)
        required_methods = [:sms_confirmed_at, :sms_confirmation_sent_at, :sms_confirmation_token]
        required_methods << :unconfirmed_phone if klass.sms_reconfirmable
        required_methods
      end

      def sms_confirm(args={})
        pending_any_sms_confirmation do
          if sms_confirmation_period_expired?
            self.errors.add(:phone, :sms_confirmation_period_expired,
                            period: Devise::TimeInflector.time_ago_in_words(self.class.sms_confirm_within.ago))
            return false
          end

          self.sms_confirmed_at = Time.now.utc

          saved = if pending_sms_reconfirmation?
                    skip_sms_reconfirmation!
                    self.phone = unconfirmed_phone
                    self.unconfirmed_phone = nil

                    save(validate: true)
                  else
                    save(validate: args[:ensure_valid] == true)
                  end

          after_sms_confirmation if saved
          saved
        end
      end

      # Verifies whether a user is sms-confirmed or not
      def sms_confirmed?
        !!sms_confirmed_at
      end

      def send_sms_reconfirmation_instructions
        @sms_reconfirmation_required = false

        unless @skip_confirmation_notification
          send_sms_confirmation_instructions
        end
      end

      def skip_sms_confirmation_notification!
        @skip_confirmation_notification = true
      end

      def send_sms_confirmation_instructions
        unless @raw_sms_confirmation_token
          generate_sms_confirmation_token!
        end

        opts = pending_sms_reconfirmation? ? { to: unconfirmed_phone } : { }
        send_sms_devise_notification(:confirmation_instructions, @raw_sms_confirmation_token, opts)
      end

      # Resend confirmation token.
      # Regenerates the token if the period is expired.
      def resend_sms_confirmation_instructions
        pending_any_sms_confirmation do
          send_sms_confirmation_instructions
        end
      end

      def active_for_authentication?

        super && (!sms_confirmation_required? || sms_confirmed? || sms_confirmation_period_valid?)
      end

      def send_phone_changed_notification
        send_sms_devise_notification(:phone_changed, to: phone_before_last_save)
      end

      def generate_sms_confirmation_token!
        generate_sms_confirmation_token && save(validate: false)
      end

      # override Devise::Models::Confirmable#pending_sms_reconfirmation?
      def pending_sms_reconfirmation?
        self.class.sms_reconfirmable && unconfirmed_phone.present?
      end

      # If you don't want confirmation to be sent on create, neither a code
      # to be generated, call skip_sms_confirmation!
      def skip_sms_confirmation!
        self.sms_confirmed_at = Time.now.utc
      end

      def skip_sms_reconfirmation!
        @bypass_sms_confirmation_postpone = true
      end

      protected

      def skip_sms_reconfirmation_in_callback!
        @skip_sms_reconfirmation_in_callback = true
      end

      def sms_confirmation_period_valid?
        return true if self.class.allow_sms_unconfirmed_access_for.nil?
        return false if self.class.allow_sms_unconfirmed_access_for == 0.days

        sms_confirmation_sent_at && sms_confirmation_sent_at.utc >= self.class.allow_sms_unconfirmed_access_for.ago
      end

      # A callback initiated after successfully confirming. This can be
      # used to insert your own logic that is only run after the user successfully
      # confirms.
      #
      # Example:
      #
      #   def after_sms_confirmation
      #     self.update_attribute(:invite_code, nil)
      #   end
      #
      def after_sms_confirmation
      end

      def send_on_create_sms_confirmation_instructions
        send_sms_confirmation_instructions
      end

      def sms_confirmation_required?
        !sms_confirmed?
      end

      def sms_confirmation_period_expired?
        self.class.sms_confirm_within && self.sms_confirmation_sent_at && (Time.now.utc > self.sms_confirmation_sent_at.utc + self.class.sms_confirm_within)
      end

      # Generates a new random token for confirmation, and stores
      # the time this token is being generated in sms_confirmation_sent_at
      def generate_sms_confirmation_token
        if self.sms_confirmation_token && !sms_confirmation_period_expired?
          @raw_sms_confirmation_token = self.sms_confirmation_token
        else
          self.sms_confirmation_token = @raw_sms_confirmation_token = Devise.friendly_token
          self.sms_confirmation_sent_at = Time.now.utc
        end
      end

      # Checks whether the record requires any confirmation.
      def pending_any_sms_confirmation
        if (!sms_confirmed? || pending_sms_reconfirmation?)
          yield
        else
          self.errors.add(:phone, :already_confirmed)
          false
        end
      end

      def postpone_phone_change?
        postpone = self.class.sms_reconfirmable &&
            will_save_change_to_phone? &&
            !@bypass_sms_confirmation_postpone &&
            self.phone.present? &&
            (!@skip_sms_reconfirmation_in_callback || !self.phone_in_database.nil?)
        @bypass_sms_confirmation_postpone = false

        postpone
      end

      def send_sms_confirmation_notification?
        sms_confirmation_required? && !@skip_confirmation_notification && self.phone.present?
      end

      def sms_reconfirmation_required?
        self.class.sms_reconfirmable && @sms_reconfirmation_required && (self.phone.present? || self.unconfirmed_phone.present?)
      end

      def postpone_phone_change_until_confirmation_and_regenerate_sms_confirmation_token
        @sms_reconfirmation_required = true
        self.unconfirmed_phone = self.phone
        self.phone = self.phone_in_database
        self.sms_confirmation_token = nil
        generate_sms_confirmation_token
      end

      # With reconfirmable, notify the original email when the user first
      # requests the email change, instead of when the change is confirmed.
      def send_phone_changed_notification?
        self.class.sms_reconfirmable && self.class.send_phone_changed_notification && sms_reconfirmation_required?
      end

      module ClassMethods
        def send_sms_confirmation_instructions(attributes={})
          confirmable = find_by_unconfirmed_phone_with_errors(attributes) if sms_reconfirmable
          unless confirmable.try(:persisted?)
            confirmable = find_or_initialize_with_errors(sms_confirmation_keys, attributes, :not_found)
          end
          confirmable.resend_sms_confirmation_instructions if confirmable.persisted?
          confirmable
        end

        def sms_confirm_by_token(sms_confirmation_token)
          confirmable = find_first_by_auth_conditions(sms_confirmation_token: sms_confirmation_token)
          unless confirmable
            confirmation_digest = Devise.token_generator.digest(self, :sms_confirmation_token, sms_confirmation_token)
            confirmable = find_or_initialize_with_error_by(:sms_confirmation_token, confirmation_digest)
          end

          # TODO: replace above lines with
          # confirmable = find_or_initialize_with_error_by(:sms_confirmation_token, sms_confirmation_token)
          # after enough time has passed that Devise clients do not use digested tokens

          confirmable.sms_confirm if confirmable.persisted?
          confirmable
        end

        def find_by_unconfirmed_phone_with_errors(attributes = {})
          attributes = attributes.slice(*sms_confirmation_keys).permit!.to_h if attributes.respond_to? :permit
          unconfirmed_required_attributes = sms_confirmation_keys.map { |k| k == :phone ? :unconfirmed_phone : k }
          unconfirmed_attributes = attributes.symbolize_keys
          unconfirmed_attributes[:unconfirmed_phone] = unconfirmed_attributes.delete(:phone)
          find_or_initialize_with_errors(unconfirmed_required_attributes, unconfirmed_attributes, :not_found)
        end

        Devise::Models.config(self, :allow_sms_unconfirmed_access_for, :send_phone_changed_notification, :sms_confirmation_keys, :sms_reconfirmable, :sms_confirm_within, :sms_reset_password_within)
      end
    end
  end
end