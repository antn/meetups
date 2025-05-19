# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  private

  def class_names(*args)
    [].tap do |classes|
      args.each do |class_name|
        case class_name
        when String
          classes << class_name if class_name.present?
        when Hash
          class_name.each do |key, val|
            classes << key if val
          end
        when Array
          classes << class_names(*class_name).presence
        end
      end

      classes.compact!
      classes.uniq!
    end.join(" ")
  end
end
