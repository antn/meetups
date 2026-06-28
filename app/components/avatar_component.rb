# frozen_string_literal: true

# Renders a user's avatar: their profile picture when present, otherwise a
# colored circle with their initials (deterministic color per name).
class AvatarComponent < ApplicationComponent
  # Darker brand/accent tones so white initials stay readable.
  PALETTE = %w[bg-brand-purple bg-brand-pink bg-brand-orange bg-sky-600 bg-emerald-600].freeze

  SIZES = {
    sm: "h-6 w-6 text-[10px]",
    md: "h-9 w-9 text-xs",
    lg: "h-12 w-12 text-sm"
  }.freeze

  def initialize(name:, url: nil, size: :md)
    @name = name.to_s
    @url = url
    @size = size.to_sym
  end

  private

  attr_reader :name, :url, :size

  def size_class
    SIZES.fetch(size, SIZES[:md])
  end

  def color_class
    PALETTE[name.bytes.sum % PALETTE.size]
  end

  def initials
    cleaned = name.delete("@").strip
    parts = cleaned.split(/[\s_\-.]+/).reject(&:empty?)
    if parts.size >= 2
      "#{parts[0][0]}#{parts[1][0]}".upcase
    else
      cleaned[0, 2].upcase
    end
  end
end
