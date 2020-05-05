# frozen_string_literal: true

class Devise::SmsConfirmationsController < DeviseController

  # GET /resource/sms_confirmation/new
  def new
    self.resource = resource_class.new
  end

  # POST /resource/sms_confirmation
  def create
    self.resource = resource_class.send_confirmation_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_resending_confirmation_instructions_path_for(resource_name))
    else
      respond_with(resource)
    end
  end

  # GET /resource/sms_confirmation/edit?phone=abcdef
  def edit
    self.resource = resource_class.find_by_phone(confirmation_params[:phone])

    if resource.blank?
      redirect_to sms_confirmation_path and return
    end
  end

  def update
    self.resource = resource_class.sms_confirm_by_token(confirmation_params[:phone], confirmation_params[:sms_confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :sms_confirmed)
      respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      respond_with_navigational(resource.errors, status: :unprocessable_entity){ render :show }
    end
  end

  protected

  # The path used after resending confirmation instructions.
  def after_resending_confirmation_instructions_path_for(resource_name)
    is_navigational_format? ? sms_confirmation_path(resource_name) : '/'
  end

  # The path used after confirmation.
  def after_confirmation_path_for(resource_name, resource)
    if signed_in?(resource_name)
      signed_in_root_path(resource)
    else
      new_session_path(resource_name)
    end
  end

  def translation_scope
    'devise.sms_confirmations'
  end

  def confirmation_params
    params.require(resource_name).permit(:phone, :sms_confirmation_token)
  end
end
