# frozen_string_literal: true

require "active_support/concern"

module AdminUpdateParticipatoryProcessExtend
  extend ActiveSupport::Concern

  included do

    private

    def attributes
      {
        title: form.title,
        subtitle: form.subtitle,
        weight: form.weight,
        slug: form.slug,
        hashtag: form.hashtag,
        promoted: form.promoted,
        description: form.description,
        short_description: form.short_description,
        scopes_enabled: form.scopes_enabled,
        scope: form.scope,
        scope_type_max_depth: form.scope_type_max_depth,
        private_space: form.private_space,
        developer_group: form.developer_group,
        local_area: form.local_area,
        area: form.area,
        area_ids: form.area_ids.reject(&:blank?),
        target: form.target,
        participatory_scope: form.participatory_scope,
        participatory_structure: form.participatory_structure,
        meta_scope: form.meta_scope,
        start_date: form.start_date,
        end_date: form.end_date,
        participatory_process_group: form.participatory_process_group,
        show_metrics: form.show_metrics,
        show_statistics: form.show_statistics,
        announcement: form.announcement
      }.merge(uploader_attributes)
    end

  end
end

Decidim::ParticipatoryProcesses::Admin::UpdateParticipatoryProcess.send(:include, AdminUpdateParticipatoryProcessExtend)
