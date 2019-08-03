# DeviseSmsConfirmable

DeviseSmsConfirmable is a module provide SMS confirmation. The user will receive an SMS with a token that can be entered on the site to activate the account. You can handle SMS's Message template as Devise handles ActionMailer's template.

## Installation
Installation for Rails ~> 5.1.4 and Devise ~> 4.6.2
Add this line to your application's Gemfile (and Devise and TwilioRuby if you weren't using them):

```ruby
gem 'devise'
gem 'devise_sms_confirmable'
gem 'twilio-ruby'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install devise_sms_confirmable

## Usage
To use it, simply specify your DeviseSmsConfirmable configuration in ```config/initializers/devise.rb```:

```ruby
# Load the module for SMS confirmation
require 'devise_sms_confirmable'
# Default source phone number
config.sms_sender = 'some_e164_phone_number'
```

### Configuring Models
Add :sms_confirmable option to The Devise method in your models.

```ruby
devise :database_authenticatable, :sms_confirmable

``` 

### Allow models to sign in using their phone number

```ruby
  config.authentication_keys = [:phone]
```

## Configuring twilio-ruby 

config/initializers/twilio.rb

### Choosing and chaining delivery methods
devise_sms_confirmable use [textris](https://github.com/visualitypl/textris) for the delivery system. See textris for details.
The following is a sample (quoted from textris) using twilio.

```ruby
# Send messages via the Twilio REST API
config.textris_delivery_method = :twilio

# Don't send anything, log messages into Rails logger
config.textris_delivery_method = :log

# Don't send anything, access your messages via Textris::Base.deliveries
config.textris_delivery_method = :test
```

### Twilio
textris connects with the Twilio API using twilio-ruby gem. It does not, however, install the gem for you. If you don't have it yet, add the twilio-ruby gem to Gemfile:

```ruby
gem 'twilio-ruby'
```

Then, pre-configure the twilio-ruby settings by creating the config/initializers/twilio.rb file:

```ruby

Twilio.configure do |config|
  config.account_sid = 'some_sid'
  config.auth_token  = 'some_auth_token'
end
```

To use Twilio's Copilot use twilio_messaging_service_sid in place of from when sending a text or setting defaults.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/devise_sms_confirmable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DeviseSmsConfirmable project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/devise_sms_confirmable/blob/master/CODE_OF_CONDUCT.md).
