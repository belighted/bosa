# frozen_string_literal: true
require "active_support/concern"

module AdminMenuHelperExtend
  extend ActiveSupport::Concern

  included do

    # Public: Returns the main menu presenter object
    def main_menu
      @main_menu ||= ::Decidim::MenuPresenter.new(
        :admin_menu,
        self,
        "main-nav",
        active_class: "is-active"
      )
    end

    # Public: Returns the settings menu presenter object
    def settings_menu
      @settings_menu ||= ::Decidim::MenuPresenter.new(
        :admin_settings_menu,
        self,
        "settings-nav",
        active_class: "is-active"
      )
    end

  end
end

Decidim::Admin::MenuHelper.send(:include, AdminMenuHelperExtend)
