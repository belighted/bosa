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

        sql = <<-SQL
        UPDATE decidim_users
          SET name = '#{attributes[:name]}',
              last_sign_in_ip = '#{attributes[:last_sign_in_ip]}',
              nickname = '#{attributes[:nickname]}',
              email = '#{attributes[:email]}',
              unconfirmed_email = NULL,
              updated_at = LOCALTIMESTAMP
        WHERE id = #{u.id}
        SQL

        ActiveRecord::Base.connection.execute(Arel.sql(sql))
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
