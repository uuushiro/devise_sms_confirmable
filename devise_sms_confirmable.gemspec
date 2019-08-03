lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "devise_sms_confirmable/version"

Gem::Specification.new do |spec|
  spec.name          = "devise_sms_confirmable"
  spec.version       = DeviseSmsConfirmable::VERSION
  spec.authors       = ["uuushiro"]
  spec.email         = ["yushiro.ma2ta2.21@gmail.com"]

  spec.summary       = %q{Module provide sms confirmation.You can handle SMS Message template  as Devise handles ActionMailer template.}
  spec.description   = %q{Module provide sms confirmation.You can handle SMS Message template  as Devise handles ActionMailer template.}
  spec.homepage      = "https://github.com/uuushiro/devise_sms_confirmable"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "devise", ">= 4.6.2"
  spec.add_dependency "rails", "~> 5.1.4"
  spec.add_dependency("textris", "~> 0.7")

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "devise", ">= 4.6.2"
  spec.add_development_dependency "twilio-ruby"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "timecop"
end
