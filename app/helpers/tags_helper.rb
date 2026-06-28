# frozen_string_literal: true

module TagsHelper
  # Solid brand-colored chip classes per tag color. The class strings are spelled
  # out literally so Tailwind's source scanner generates them (dynamically built
  # names like "bg-brand-#{color}" would be missed).
  TAG_CHIP_CLASSES = {
    "purple" => "bg-brand-purple text-white",
    "pink" => "bg-brand-pink text-white",
    "orange" => "bg-brand-orange text-white",
    "blue" => "bg-brand-blue text-gray-900",
    "yellow" => "bg-brand-yellow text-gray-900"
  }.freeze

  # Background-only swatch classes for the color picker.
  TAG_SWATCH_CLASSES = {
    "purple" => "bg-brand-purple",
    "pink" => "bg-brand-pink",
    "orange" => "bg-brand-orange",
    "blue" => "bg-brand-blue",
    "yellow" => "bg-brand-yellow"
  }.freeze

  def tag_chip_classes(color)
    TAG_CHIP_CLASSES.fetch(color.to_s, TAG_CHIP_CLASSES["purple"])
  end

  def tag_swatch_class(color)
    TAG_SWATCH_CLASSES.fetch(color.to_s, TAG_SWATCH_CLASSES["purple"])
  end
end
