Rails.application.routes.draw do
  # mount DeviseSmsConfirmable::Engine => "/devise_sms_confirmable"
  devise_for :users, controllers: {
      sms_confirmations: 'users/sms_confirmations',
  }

  devise_for :admins, controllers: {
      sms_confirmations: 'admins/sms_confirmations',
  }

  devise_scope :user do
    patch 'users/sms_confirmation', to: 'users/sms_confirmations#confirm'
  end
end
