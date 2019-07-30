Rails.application.routes.draw do
  mount DeviseSmsConfirmable::Engine => "/devise_sms_confirmable"
end
