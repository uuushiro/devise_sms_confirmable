module ActionDispatch::Routing
  class Mapper
    protected

    def devise_sms_confirmation(mapping, controllers)
      resource :sms_confirmation, only: [:new, :create, :show, :edit, :update], path: mapping.path_names[:sms_confirmation], controller: controllers[:sms_confirmations]
    end
  end
end