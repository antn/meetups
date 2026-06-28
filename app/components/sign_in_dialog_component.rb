# frozen_string_literal: true

# Shared "sign in to continue" modal. Rendered once in the layout for signed-out
# visitors and opened by any sign-in trigger (claiming a slot, RSVPing) via the
# `sign-in:open` event — see app/javascript/components/sign_in_dialog_element.js.
class SignInDialogComponent < ApplicationComponent
  def initialize(current_user: nil)
    @current_user = current_user
  end

  def render?
    @current_user.nil?
  end
end
