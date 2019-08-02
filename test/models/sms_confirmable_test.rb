# frozen_string_literal: true
require 'test_helper'

class SmsConfirmableTest < ActiveSupport::TestCase

  test 'should set callbacks to send the mail' do
    defined_callbacks = User._commit_callbacks.map(&:filter)
    assert_includes defined_callbacks, :send_on_create_sms_confirmation_instructions
    assert_includes defined_callbacks, :send_sms_reconfirmation_instructions
  end

  test 'should generate confirmation token after creating a record' do
    assert_nil new_user.sms_confirmation_token
    assert_not_nil create_user.sms_confirmation_token
  end

  test 'should never generate the same confirmation token for different users' do
    confirmation_tokens = []
    3.times do
      token = create_user.sms_confirmation_token
      assert !confirmation_tokens.include?(token)
      confirmation_tokens << token
    end
  end

  test 'should confirm a user by updating confirmed at' do
    user = create_user
    assert_nil user.sms_confirmed_at
    assert user.sms_confirm
    assert_not_nil user.sms_confirmed_at
  end

  test 'should verify whether a user is confirmed or not' do
    refute new_user.sms_confirmed?
    user = create_user
    refute user.sms_confirmed?
    user.sms_confirm
    assert user.sms_confirmed?
  end

  test 'should not confirm a user already confirmed' do
    user = create_user
    assert user.sms_confirm
    assert_blank user.errors[:phone]

    refute user.sms_confirm
    assert_equal "was already confirmed, please try signing in", user.errors[:phone].join
  end

  test 'should find and confirm a user automatically based on the raw token' do
    user = create_user
    raw  = user.raw_sms_confirmation_token
    confirmed_user = User.sms_confirm_by_token(raw)
    assert_equal confirmed_user, user
    assert user.reload.sms_confirmed?
  end

  test 'should return a new record with errors when a invalid token is given' do
    confirmed_user = User.sms_confirm_by_token('invalid_confirmation_token')
    refute confirmed_user.persisted?
    assert_equal "is invalid", confirmed_user.errors[:sms_confirmation_token].join
  end

  test 'should return a new record with errors when a blank token is given' do
    confirmed_user = User.sms_confirm_by_token('')
    refute confirmed_user.persisted?
    assert_equal "can't be blank", confirmed_user.errors[:sms_confirmation_token].join
  end

  test 'should generate errors for a user phone if user is already confirmed' do
    user = create_user
    user.sms_confirmed_at = Time.now
    user.save
    confirmed_user = User.sms_confirm_by_token(user.raw_sms_confirmation_token)
    assert confirmed_user.sms_confirmed?
    assert_equal "was already confirmed, please try signing in", confirmed_user.errors[:phone].join
  end

  test 'should show error when a token has already been used' do
    user = create_user
    raw  = user.raw_sms_confirmation_token
    User.sms_confirm_by_token(raw)
    assert user.reload.sms_confirmed?

    confirmed_user = User.sms_confirm_by_token(raw)
    assert_equal "was already confirmed, please try signing in", confirmed_user.errors[:phone].join
  end

  test 'should send confirmation instructions by phone' do
    assert_phone_sent "+819076533333" do
      create_user phone: "+819076533333"
    end
  end

  test 'should not send confirmation when trying to save an invalid user' do
    assert_phone_not_sent do
      user = new_user
      user.stubs(:valid?).returns(false)
      user.save
    end
  end

  test 'should not generate a new token neither send e-mail if skip_sms_confirmation! is invoked' do
    user = new_user
    user.skip_sms_confirmation!

    assert_phone_not_sent do
      user.save!
      assert_nil user.sms_confirmation_token
      assert_not_nil user.sms_confirmed_at
    end
  end

  test 'should skip confirmation e-mail without confirming if skip_sms_confirmation_notification! is invoked' do
    user = new_user
    user.skip_sms_confirmation_notification!

    assert_phone_not_sent do
      user.save!
      refute user.sms_confirmed?
    end
  end

  test 'should not send confirmation when no phone is provided' do
    assert_phone_not_sent do
      user = new_user
      user.phone = ''
      user.save(validate: false)
    end
  end

  test 'should find a user to send confirmation instructions' do
    user = create_user
    confirmation_user = User.send_sms_confirmation_instructions(phone: user.phone)
    assert_equal confirmation_user, user
  end

  test 'should return a new user if no phone was found' do
    confirmation_user = User.send_sms_confirmation_instructions(phone: "invalid@example.com")
    refute confirmation_user.persisted?
  end

  test 'should add error to new user phone if no phone was found' do
    confirmation_user = User.send_sms_confirmation_instructions(phone: "invalid@example.com")
    assert confirmation_user.errors[:phone]
    assert_equal "not found", confirmation_user.errors[:phone].join
  end

  test 'should send phone instructions for the user confirm its phone' do
    user = create_user
    assert_phone_sent user.phone do
      User.send_sms_confirmation_instructions(phone: user.phone)
    end
  end

  test 'should always have confirmation token when phone is sent' do
    user = new_user
    user.instance_eval { def sms_confirmation_required?; false end }
    user.save
    user.send_sms_confirmation_instructions
    assert_not_nil user.reload.sms_confirmation_token
  end

  test 'should not resend phone instructions if the user change their phone' do
    user = create_user
    user.phone = '+819076543212'
    assert_phone_not_sent do
      user.save!
    end
  end

  test 'should not reset confirmation status or token when updating phone' do
    user = create_user
    original_token = user.sms_confirmation_token
    user.sms_confirm
    user.phone = '+819076543212'
    user.save!

    user.reload
    assert user.sms_confirmed?
    assert_equal original_token, user.sms_confirmation_token
  end

  test 'should not be able to send instructions if the user is already confirmed' do
    user = create_user
    user.sms_confirm
    refute user.resend_sms_confirmation_instructions
    assert user.sms_confirmed?
    assert_equal 'was already confirmed, please try signing in', user.errors[:phone].join
  end

  test 'confirm time should fallback to devise confirm in default configuration' do
    swap Devise, allow_sms_unconfirmed_access_for: 1.day do
      user = create_user
      user.sms_confirmation_sent_at = 2.days.ago
      refute user.active_for_authentication?

      Devise.allow_sms_unconfirmed_access_for = 3.days
      assert user.active_for_authentication?
    end
  end

  test 'should be active when confirmation sent at is not overpast' do
    swap Devise, allow_sms_unconfirmed_access_for: 5.days do
      Devise.allow_sms_unconfirmed_access_for = 5.days
      user = create_user

      user.sms_confirmation_sent_at = 4.days.ago
      assert user.active_for_authentication?

      user.sms_confirmation_sent_at = 5.days.ago
      refute user.active_for_authentication?
    end
  end

  test 'should be active when already confirmed' do
    user = create_user
    refute user.sms_confirmed?
    refute user.active_for_authentication?

    user.sms_confirm
    assert user.sms_confirmed?
    assert user.active_for_authentication?
  end

  test 'should not be active when confirm in is zero' do
    Devise.allow_sms_unconfirmed_access_for = 0.days
    user = create_user
    user.sms_confirmation_sent_at = Time.zone.today
    refute user.active_for_authentication?
  end

  test 'should not be active when confirm period is set to 0 days' do
    Devise.allow_sms_unconfirmed_access_for = 0.days
    user = create_user

    Timecop.freeze(Time.zone.today) do
      user.sms_confirmation_sent_at = Time.zone.today
      refute user.active_for_authentication?
    end
  end

  test 'should be active when we set allow_sms_unconfirmed_access_for to nil' do
    swap Devise, allow_sms_unconfirmed_access_for: nil do
      user = create_user
      user.sms_confirmation_sent_at = Time.zone.today
      assert user.active_for_authentication?
    end
  end

  test 'should not be active without confirmation' do
    user = create_user
    user.sms_confirmation_sent_at = nil
    user.save
    refute user.reload.active_for_authentication?
  end

  test 'should be active without confirmation when confirmation is not required' do
    user = create_user
    user.instance_eval { def sms_confirmation_required?; false end }
    user.sms_confirmation_sent_at = nil
    user.save
    assert user.reload.active_for_authentication?
  end

  test 'should not break when a user tries to reset their password in the case where confirmation is not required and confirm_within is set' do
    swap Devise, confirm_within: 3.days do
      user = create_user
      user.instance_eval { def sms_confirmation_required?; false end }
      user.sms_confirmation_sent_at = nil
      user.save
      assert user.reload.sms_confirm
    end
  end

  test 'should find a user to send phone instructions for the user confirm its phone by authentication_keys' do
    swap Devise, authentication_keys: [:username, :phone] do
      user = create_user
      confirm_user = User.send_sms_confirmation_instructions(phone: user.phone, username: user.username)
      assert_equal confirm_user, user
    end
  end

  test 'should require all sms_confirmation_keys' do
    swap Devise, sms_confirmation_keys: [:username, :phone] do
      user = create_user
      confirm_user = User.send_sms_confirmation_instructions(phone: user.phone)
      refute confirm_user.persisted?
      assert_equal "can't be blank", confirm_user.errors[:username].join
    end
  end

  def sms_confirm_user_by_token_with_sms_confirmation_sent_at(sms_confirmation_sent_at)
    user = create_user
    user.update_attribute(:sms_confirmation_sent_at, sms_confirmation_sent_at)
    confirmed_user = User.sms_confirm_by_token(user.raw_sms_confirmation_token)
    assert_equal confirmed_user, user
    user.reload.sms_confirmed?
  end

  test 'should accept confirmation phone token even after 5 years when no expiration is set' do
    assert sms_confirm_user_by_token_with_sms_confirmation_sent_at(5.years.ago)
  end

  test 'should accept confirmation phone token after 2 days when expiration is set to 3 days' do
    swap Devise, sms_confirm_within: 3.days do
      assert sms_confirm_user_by_token_with_sms_confirmation_sent_at(2.days.ago)
    end
  end

  test 'should not accept confirmation phone token after 4 days when expiration is set to 3 days' do
    swap Devise, sms_confirm_within: 3.days do
      refute sms_confirm_user_by_token_with_sms_confirmation_sent_at(4.days.ago)
    end
  end

  test 'do not generate a new token on resend' do
    user = create_user
    old  = user.sms_confirmation_token
    user = User.find(user.id)
    user.resend_sms_confirmation_instructions
    assert_equal user.sms_confirmation_token, old
  end

  test 'generate a new token after first has expired' do
    swap Devise, sms_confirm_within: 3.days do
      user = create_user
      old = user.sms_confirmation_token
      user.update_attribute(:sms_confirmation_sent_at, 4.days.ago)
      user = User.find(user.id)
      user.resend_sms_confirmation_instructions
      assert_not_equal user.sms_confirmation_token, old
    end
  end

  test 'should call after_sms_confirmation if confirmed' do
    user = create_user
    user.define_singleton_method :after_sms_confirmation do
      self.username = self.username.to_s + 'updated'
    end
    old = user.username
    assert user.sms_confirm
    assert_not_equal user.username, old
  end

  test 'should not call after_sms_confirmation if not confirmed' do
    user = create_user
    assert user.sms_confirm
    user.define_singleton_method :after_sms_confirmation do
      self.username = self.username.to_s + 'updated'
    end
    old = user.username
    refute user.sms_confirm
    assert_equal user.username, old
  end

  test 'should always perform validations upon confirm when ensure valid true' do
    admin = create_admin
    admin.stubs(:valid?).returns(false)
    refute admin.sms_confirm(ensure_valid: true)
  end
end

class ReconfirmableTest < ActiveSupport::TestCase
  test 'should not worry about validations on confirm even with reconfirmable' do
    admin = create_admin
    admin.reset_password_token = "a"
    assert admin.sms_confirm
  end

  test 'should generate confirmation token after changing phone' do
    admin = create_admin
    assert admin.sms_confirm
    residual_token = admin.sms_confirmation_token
    assert admin.update(phone: '+819076543212')
    assert_not_equal residual_token, admin.sms_confirmation_token
  end

  test 'should not regenerate confirmation token or require reconfirmation if skipping reconfirmation after changing phone' do
    admin = create_admin
    original_token = admin.sms_confirmation_token
    assert admin.sms_confirm
    admin.skip_sms_reconfirmation!
    assert admin.update(phone: '+819076543212')
    assert admin.sms_confirmed?
    refute admin.pending_sms_reconfirmation?
    assert_equal original_token, admin.sms_confirmation_token
  end

  test 'should skip sending reconfirmation phone when phone is changed and skip_sms_confirmation_notification! is invoked' do
    admin = create_admin
    admin.skip_sms_confirmation_notification!

    assert_phone_not_sent do
      admin.update(phone: '+819076543212')
    end
  end

  test 'should regenerate confirmation token after changing phone' do
    admin = create_admin
    assert admin.sms_confirm
    assert admin.update(phone: '+819076542222')
    token = admin.sms_confirmation_token
    assert admin.update(phone: '+819076543212')
    assert_not_equal token, admin.sms_confirmation_token
  end

  test 'should send confirmation instructions by phone after changing phone' do
    Textris::Base.deliveries.clear

    admin = create_admin
    assert admin.sms_confirm
    assert_phone_sent "+819076543212" do
      assert admin.update(phone: '+819076543212')
    end
    assert_match "+819076543212", Textris::Base.deliveries.last.to.first
  end

  test 'should send confirmation instructions by phone after changing phone from nil' do
    admin = create_admin(phone: nil)
    assert_phone_sent "+819076543212" do
      assert admin.update(phone: '+819076543212')
    end
    assert_match "+819076543212", "+819076543212"
  end

  test 'should not send confirmation by phone after changing password' do
    admin = create_admin
    assert admin.sms_confirm
    assert_phone_not_sent do
      assert admin.update(password: 'newpass', password_confirmation: 'newpass')
    end
  end

  test 'should not send confirmation by phone after changing to a blank phone' do
    admin = create_admin
    assert admin.sms_confirm
    assert_phone_not_sent do
      admin.phone = ''
      admin.save(validate: false)
    end
  end

  test 'should stay confirmed when phone is changed' do
    admin = create_admin
    assert admin.sms_confirm
    assert admin.update(phone: '+819076543212')
    assert admin.sms_confirmed?
  end

  test 'should update phone only when it is confirmed' do
    admin = create_admin
    assert admin.sms_confirm
    assert admin.update(phone: '+819011111111')
    assert_not_equal '+819011111111', admin.phone
    assert admin.sms_confirm
    assert_equal '+819011111111', admin.phone
  end

  test 'should not allow admin to get past confirmation phone by resubmitting their new address' do
    admin = create_admin
    assert admin.sms_confirm
    assert admin.update(phone: '+819076543212')
    assert_not_equal '+819076543212', admin.phone
    assert admin.update(phone: '+819076543212')
    assert_not_equal '+819076543212', admin.phone
  end

  test 'should find a admin by send confirmation instructions with unconfirmed_phone' do
    admin = create_admin
    assert admin.sms_confirm
    assert admin.update(phone: '+819076543212')
    confirmation_admin = Admin.send_sms_confirmation_instructions(phone: admin.unconfirmed_phone)
    assert_equal confirmation_admin, admin
  end

  test 'should return a new admin if no phone or unconfirmed_phone was found' do
    confirmation_admin = Admin.send_sms_confirmation_instructions(phone: "invalid@phone.com")
    refute confirmation_admin.persisted?
  end

  test 'should add error to new admin phone if no phone or unconfirmed_phone was found' do
    confirmation_admin = Admin.send_sms_confirmation_instructions(phone: "invalid@phone.com")
    assert confirmation_admin.errors[:phone]
    assert_equal "not found", confirmation_admin.errors[:phone].join
  end

  test 'should find admin with phone in unconfirmed_phones' do
    admin = create_admin
    admin.unconfirmed_phone = "+819076543210"
    assert admin.save
    admin = Admin.find_by_unconfirmed_phone_with_errors(phone: "+819076543210")
    assert admin.persisted?
  end

  test 'required_fields should contain the fields that Devise uses' do
    assert_equal Devise::Models::SmsConfirmable.required_fields(User), [
        :sms_confirmed_at,
        :sms_confirmation_sent_at,
        :sms_confirmation_token
    ]
  end

  test 'required_fields should also contain unconfirmable when reconfirmable_phone is true' do
    assert_equal Devise::Models::SmsConfirmable.required_fields(Admin), [
        :sms_confirmed_at,
        :sms_confirmation_sent_at,
        :sms_confirmation_token,
        :unconfirmed_phone
    ]
  end

  test 'should not require reconfirmation after creating a record' do
    admin = create_admin
    assert !admin.pending_sms_reconfirmation?
  end

  test 'should not require reconfirmation after creating a record with #save called in callback' do
    class Admin::WithSaveInCallback < Admin
      after_create :save
    end

    admin = Admin::WithSaveInCallback.create(valid_attributes.except(:username))
    assert !admin.pending_sms_reconfirmation?
  end

  test 'should require reconfirmation after creating a record and updating the phone' do
    admin = create_admin
    assert !admin.instance_variable_get(:@bypass_confirmation_postpone)
    admin.phone = "+819076543210"
    admin.save
    assert admin.pending_sms_reconfirmation?
  end

  test 'should notify previous phone on phone change when configured' do
    Textris::Base.deliveries.clear

    swap Devise, send_phone_changed_notification: true do
      admin = create_admin
      original_phone = admin.phone

      assert_difference 'Textris::Base.deliveries.size', 2 do
        assert admin.update(phone: '+819076543211')
      end
      
      assert_equal original_phone, Textris::Base.deliveries[1].to.first.insert(0, '+')

      assert_equal '+819076543211', Textris::Base.deliveries[2].to.first.insert(0, '+')

      assert_phone_not_sent do
        assert admin.sms_confirm
      end
    end
  end
end