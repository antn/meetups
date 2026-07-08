# frozen_string_literal: true

class StaffbarComponent < ApplicationComponent
  # stafftools_url: optional page-specific stafftools destination (set via
  # `content_for :stafftools_url` in views); falls back to the stafftools root.
  def initialize(current_user:, stafftools_url: nil)
    @current_user = current_user
    @stafftools_url = stafftools_url
  end

  private

  attr_reader :current_user

  def stafftools_link
    @stafftools_url.presence || helpers.stafftools_root_path
  end

  def render?
    current_user&.site_admin?
  end

  def background_color
    Rails.env.development? ? "bg-red-950" : "bg-zinc-900"
  end

  def branch_name
    return @branch_name if defined?(@branch_name)
    return @branch_name = ENV["GIT_BRANCH"] if ENV["GIT_BRANCH"].present?

    @branch_name = git("rev-parse --abbrev-ref HEAD")
  end

  def sha
    return @sha if defined?(@sha)
    return @sha = ENV["GIT_SHA"] if ENV["GIT_SHA"].present?

    @sha = git("rev-parse HEAD")
  end

  def short_sha
    return if sha.blank?

    sha[0..6]
  end

  # Run a git command, returning its trimmed output or nil when git is
  # unavailable or the repo has no commits yet (e.g. a fresh checkout).
  def git(args)
    output = `git #{args} 2>/dev/null`.chomp
    output.presence
  rescue StandardError
    nil
  end
end
