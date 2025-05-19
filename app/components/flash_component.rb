# frozen_string_literal: true

class FlashComponent < ApplicationComponent
  DEFAULT_CLASSES = "max-w-4xl"

  def initialize(scheme: :notice, icon: nil, classes: nil)
    @scheme = scheme
    @icon = icon
    @classes = classes || DEFAULT_CLASSES
  end

  private

  attr_reader :scheme

  attr_reader :classes

  def scheme_color
    case scheme
    when :notice
      "bg-blue-500"
    when :success
      "bg-emerald-500"
    when :warning
      "bg-yellow-500"
    when :error
      "bg-rose-500"
    end
  end

  def icon
    return @icon if @icon.present?

    case scheme
    when :notice
      "information-circle"
    when :success
      "check-circle"
    when :warning
      "exclamation-triangle"
    when :error
      "exclamation-circle"
    end
  end
end
