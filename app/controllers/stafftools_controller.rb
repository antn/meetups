# frozen_string_literal: true

class StafftoolsController < ApplicationController
  before_action :ensure_staff_only

  def index
    render "stafftools/index"
  end

  private

  def ensure_staff_only
    return render_404 unless current_user&.site_admin?
  end
end
