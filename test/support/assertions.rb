# frozen_string_literal: true

require 'active_support/test_case'

class ActiveSupport::TestCase
  def assert_blank(assertion)
    assert assertion.blank?
  end

  def assert_present(assertion)
    assert assertion.present?
  end

  def assert_phone_sent(address = nil, &block)
    assert_difference('Textris::Base.deliveries.size', &block)
    if address.present?
      assert_equal address, Textris::Base.deliveries.last.to.first.insert(0, '+')
    end
  end

  def assert_phone_not_sent(&block)
    assert_no_difference('Textris::Base.deliveries.size', &block)
  end

  def assert_raise_with_message(exception_klass, message, &block)
    exception = assert_raise exception_klass, &block
    assert_equal exception.message, message,
      "The expected message was #{message} but your exception throwed #{exception.message}"
  end
end
