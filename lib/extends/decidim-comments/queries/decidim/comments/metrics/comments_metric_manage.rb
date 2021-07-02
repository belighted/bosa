# frozen_string_literal: true

require "active_support/concern"

module CommentsMetricsCommentsMetricManageExtend
  extend ActiveSupport::Concern

  included do
    def save
      query.each do |key, results|
        cumulative_value = results[:cumulative]
        next if cumulative_value.zero?

        quantity_value = results[:quantity] || 0
        space_type, space_id, category_id, related_object_type, related_object_id = key
        record = Decidim::Metric.find_or_initialize_by(day: @day.to_s, metric_type: @metric_name,
                                                       participatory_space_type: space_type, participatory_space_id: space_id,
                                                       organization: @organization, decidim_category_id: category_id,
                                                       related_object_type: related_object_type, related_object_id: related_object_id)
        record.assign_attributes(cumulative: cumulative_value, quantity: quantity_value)
        record.save!
      rescue => e
        next
      end
    end
  end
end

Decidim::Comments::Metrics::CommentsMetricManage.send(:include, CommentsMetricsCommentsMetricManageExtend)
