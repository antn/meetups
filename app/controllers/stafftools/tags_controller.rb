# frozen_string_literal: true

module Stafftools
  class TagsController < ApplicationController
    before_action :require_current_event
    before_action :set_tag, only: %i[edit update destroy]

    def index
      @tags = current_event.tags.order(:name)
    end

    def new
      @tag = current_event.tags.new
    end

    def create
      @tag = current_event.tags.new(tag_params)

      if @tag.save
        redirect_to stafftools_tags_path, notice: "Tag added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @tag.update(tag_params)
        redirect_to stafftools_tags_path, notice: "Tag updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @tag.destroy
      redirect_to stafftools_tags_path, notice: "Tag removed."
    end

    private

    def set_tag
      @tag = current_event.tags.find(params[:id])
    end

    def tag_params
      params.require(:tag).permit(:name, :color)
    end
  end
end
