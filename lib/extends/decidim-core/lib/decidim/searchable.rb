# # frozen_string_literal: true
# require "active_support/concern"
#
# module FixedSearchableOrganizationScope
#   extend ActiveSupport::Concern
#
#   included do
#     # Always access to this association scoping by_organization
#     clazz = self
#     has_many :searchable_resources, -> {where(resource_type: clazz.name)},
#              class_name: "Decidim::SearchableResource",
#              inverse_of: :resource,
#              foreign_key: :resource_id do
#       def by_organization(org_id)
#         where(decidim_organization_id: org_id, locale: Decidim::Organization.find_by(id: org_id)&.available_locales)
#       end
#     end
#   end
#
# end
#
# Decidim::Searchable.searchable_resources.values.each do |klass|
#   klass.send(:include, FixedSearchableOrganizationScope)
# end
