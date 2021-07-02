# frozen_string_literal: true

require "active_support/concern"

module InitiativesFilterFormBuilderExtend
  extend ActiveSupport::Concern

  included do
    # def initiative_types_select(name, collection, options = {})
    #   selected = object.send(name)
    #
    #   if selected.present? && selected != "all"
    #     selected = selected.values if selected.is_a?(Hash)
    #     selected = [selected] unless selected.is_a?(Array)
    #   end
    #
    #   types = collection.all.map do |type|
    #     [type.title[I18n.locale.to_s], type.id]
    #   end
    #
    #   prompt = options.delete(:prompt)
    #   remote_path = options.delete(:remote_path) || false
    #   multiple = options.delete(:multiple) || false
    #   html_options = {
    #     multiple: multiple,
    #     class: "select2",
    #     "data-remote-path" => remote_path,
    #     "data-placeholder" => prompt
    #   }
    #
    #   select(name, @template.options_for_select(types, selected: selected), options, html_options)
    # end
  end
end

Decidim::Initiatives::InitiativesFilterFormBuilder.send(:include, InitiativesFilterFormBuilderExtend)
