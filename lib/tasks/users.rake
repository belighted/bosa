# frozen_string_literal: true

namespace :users do
  desc "Remove personal data"
  task remove_personal_data: :environment do

    if Rails.env.production?
      puts "---------------DANGER---------------"
      puts "This script cannot run on production"
      puts "---------------DANGER---------------"
      return
    end
    # Remove information on user
    Decidim::User.find_in_batches do |users|
      users.each do |u|
        attributes = {
          name: Faker::Name.name.gsub("'", ""),
          last_sign_in_ip: "127.0.0.1",
          nickname: Faker::Crypto.sha256[0..15],
          email:Faker::Internet.email
        }

        u.update_columns attributes

      end
    end

    # Remove encrypted data in authorization
    empty_authorization = "UPDATE decidim_authorizations SET encrypted_metadata = NULL"
    ActiveRecord::Base.connection.execute(empty_authorization)

    # Remove all identities
    empty_identities = "TRUNCATE TABLE decidim_identities"
    ActiveRecord::Base.connection.execute(empty_identities)

  end
end
