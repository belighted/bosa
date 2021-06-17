# frozen_string_literal: true

namespace :decidim_initiatives do
  desc "Check published initiatives and moves to accepted/rejected state depending on the votes collected when the signing period has finished"
  task check_published: :environment do
    Decidim::Initiatives::SupportPeriodFinishedInitiatives.new.each do |initiative|

      organization_admins = Decidim::User.where(organization: initiative.organization, admin: true)

      if initiative.supports_goal_reached?
        initiative.accepted!
      else
        initiative.rejected!
      end

      Decidim::EventsManager.publish(
        event: "decidim.events.initiatives.deadline_over",
        event_class: Decidim::Initiatives::DeadlineOverEvent,
        resource: initiative,
        affected_users: [initiative.author]
      )

      Decidim::EventsManager.publish(
        event: "decidim.events.initiatives.admin.deadline_over",
        event_class: Decidim::Initiatives::Admin::DeadlineOverEvent,
        resource: initiative,
        affected_users: organization_admins
      )
    end
  end
end
