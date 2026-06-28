# frozen_string_literal: true

# Full-width hero banner with the brand gradient. The title sits on the left and
# the login control on the right, both inside a centered max-width container that
# also holds the right-aligned SamJoe artwork.
class HeaderComponent < ApplicationComponent
  def initialize(current_user: nil)
    @current_user = current_user
  end

  private

  attr_reader :current_user

  def signed_in?
    current_user.present?
  end
end
