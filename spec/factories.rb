# frozen_string_literal: true

FactoryGirl.define do
  sequence :name do |n|
    "Foo bar #{n}"
  end

  sequence :bank_number do |n|
    n.to_s.rjust(3, '0')
  end

  sequence :email do |n|
    "person#{n}@example.com"
  end

  sequence :uid do |n|
    n.to_s
  end

  sequence :serial do |n|
    n
  end

  sequence :permalink do |n|
    "foo_page_#{n}"
  end

  sequence :domain do |n|
    "foo#{n}lorem.com"
  end

  factory :category_follower do |f|
    f.association :user
    f.association :category
  end

  factory :country do |f|
    f.name 'Brasil'
  end

  factory :origin do |f|
    f.referral { generate(:permalink) }
    f.domain { generate(:domain) }
  end

  factory :project_reminder do |f|
    f.association :user
    f.association :project
  end

  factory :balance_transaction do |f|
    f.association :user
    f.association :project
    f.amount 100
    f.event_name 'foo'
  end

  factory :user do |f|
    f.association :bank_account
    f.association :address
    f.permalink { generate(:permalink) }
    f.name 'Foo bar'
    f.public_name 'Public bar'
    f.password '123456'
    f.cpf '97666238991'
    f.uploaded_image File.open("#{Rails.root}/spec/support/testimg.png")
    f.email { generate(:email) }
    f.about_html "This is Foo bar's biography."
    f.birth_date '10/10/1989'

    trait :without_bank_data do
      bank_account { nil }
    end
  end

  factory :category do |f|
    f.name_pt { generate(:name) }
  end

  factory :project do |f|
    # after(:create) do |project|
    #  create(:reward, project: project)
    #  if project.state == 'change_to_online_after_create'
    #    project.update_attributes(state: 'online')
    #  end
    # end
    f.name 'Foo bar'
    f.permalink { generate(:permalink) }
    f.association :user
    f.association :category
    f.association :city
    f.about_html 'Foo bar'
    f.headline 'Foo bar'
    f.mode 'aon'
    f.goal 10_000
    f.online_days 5
    f.more_links 'Ipsum dolor'
    f.video_url 'http://vimeo.com/17298435'
    f.state 'online'
    f.budget '1000'
    f.uploaded_image File.open("#{Rails.root}/spec/support/testimg.png")
    after :create do |project|
      unless project.project_transitions.where(to_state: project.state).present?
        FactoryGirl.create(:project_transition, to_state: project.state, project: project)
      end

      # should set expires_at when create a project in these states
      if %w[online waiting_funds failed successful].include?(project.state) && project.online_days.present? && project.online_at.present?
        project.expires_at = (project.online_at + project.online_days.days).end_of_day
        project.save
      end
    end
    after :build do |project|
      project.rewards.build(deliver_at: 1.year.from_now, minimum_value: 10, description: 'test', shipping_options: 'free')
    end
  end

  factory :balance_transfer do |f|
    f.amount 50
    f.association :project
    f.association :user
  end

  factory :flexible_project do |f|
    f.state 'draft'
    f.mode 'flex'
    f.name 'Foo bar'
    f.permalink { generate(:permalink) }
    f.association :user
    f.association :category
    f.association :city
    f.about_html 'Foo bar'
    f.headline 'Foo bar'
    f.goal 10_000
    f.online_days 5
    f.more_links 'Ipsum dolor'
    f.video_url 'http://vimeo.com/17298435'
    f.budget '1000'
    f.uploaded_image File.open("#{Rails.root}/spec/support/testimg.png")

    after :create do |flex_project|
      FactoryGirl.create(:project_transition, {
                           to_state: flex_project.state,
                           project: flex_project
                         })
    end
  end

  factory :project_transition do |f|
    f.association :project
    f.most_recent true
    f.to_state 'online'
    f.sort_key { generate(:serial) }
  end

  factory :user_link do |f|
    f.association :user
    f.link 'http://www.foo.com'
  end

  factory :project_budget do |f|
    f.association :project
    f.name 'Foo Bar'
    f.value '10'
  end

  factory :unsubscribe do |f|
    f.association :user, factory: :user
    f.association :project, factory: :project
  end

  factory :project_invite do |f|
    f.associations :project
    f.user_email { generate(:user_email) }
  end

  factory :notification do |f|
    f.template_name 'project_invite'
    f.user_email 'person@email.com'
    f.metadata do
      {
        associations: {
          project_id: 10
        },
        origin_name: 'Foo Bar',
        origin_email: 'foo@bar.com',
        locale: 'pt'
      }
    end
  end

  factory :project_notification do |f|
    f.association :user, factory: :user
    f.association :project, factory: :project
    f.template_name 'project_success'
    f.from_email 'from@email.com'
    f.from_name 'from_name'
    f.locale 'pt'
  end

  factory :reward do |f|
    f.association :project, factory: :project
    f.minimum_value 10.00
    f.description 'Foo bar'
    f.shipping_options 'free'
    f.deliver_at 1.year.from_now
  end

  factory :rewards, class: Reward do |f|
    f.minimum_value 10.00
    f.description 'Foo bar'
    f.shipping_options 'free'
    f.deliver_at 1.year.from_now
  end

  factory :donation do |f|
    f.amount 10
    f.association :user
  end

  factory :contribution do |f|
    f.association :project, factory: :project
    f.association :user, factory: :user
    f.association :address
    f.value 10.00
    f.payer_name 'Foo Bar'
    f.payer_email 'foo@bar.com'
    f.anonymous false
    factory :deleted_contribution do
      after :create do |contribution|
        create(:payment, state: 'deleted', value: contribution.value, contribution: contribution, created_at: contribution.created_at)
      end
    end
    factory :refused_contribution do
      after :create do |contribution|
        create(:payment, state: 'refused', value: contribution.value, contribution: contribution, created_at: contribution.created_at)
      end
    end
    factory :confirmed_contribution do
      after :create do |contribution|
        create(:payment, state: 'paid', gateway: 'Pagarme', value: contribution.value, contribution: contribution, created_at: contribution.created_at, payment_method: 'BoletoBancario')
      end
    end
    factory :pending_contribution do
      after :create do |contribution|
        create(:payment, state: 'pending', value: contribution.value, contribution: contribution, created_at: contribution.created_at)
      end
    end
    factory :pending_refund_contribution do
      after :create do |contribution|
        create(:payment, state: 'pending_refund', value: contribution.value, contribution: contribution, created_at: contribution.created_at)
      end
    end
    factory :refunded_contribution do
      after :create do |contribution|
        create(:payment, state: 'refunded', value: contribution.value, contribution: contribution, created_at: contribution.created_at)
      end
    end
    factory :contribution_with_credits do
      after :create do |contribution|
        create(:payment, state: 'paid', gateway: 'Credits', value: contribution.value, contribution: contribution)
      end
    end
  end

  factory :payment do |f|
    f.association :contribution
    f.gateway 'Pagarme'
    f.value 10.00
    f.installment_value 10.00
    f.payment_method 'CartaoDeCredito'
  end

  factory :user_follow do |f|
    f.association :user
    f.association :follow, factory: :user
  end

  factory :payment_notification do |f|
    f.association :contribution, factory: :contribution
    f.extra_data {}
  end

  factory :credit_card do |f|
    f.association :user
    f.last_digits '1234'
    f.card_brand 'Foo'
  end

  factory :authorization do |f|
    f.association :oauth_provider
    f.association :user
    f.uid 'Foo'
  end

  factory :oauth_provider do |f|
    f.name 'facebook'
    f.strategy 'GitHub'
    f.path 'github'
    f.key 'test_key'
    f.secret 'test_secret'
  end

  factory :configuration do |f|
    f.name 'Foo'
    f.value 'Bar'
  end

  factory :institutional_video do |f|
    f.title 'My title'
    f.description 'Some Description'
    f.video_url 'http://vimeo.com/35492726'
    f.visible false
  end

  factory :project_post do |f|
    f.association :project, factory: :project
    f.association :user, factory: :user
    f.title 'My title'
    f.comment_html '<p>This is a comment</p>'
  end

  factory :state do
    name { generate(:name) }
    acronym { generate(:name) }
  end

  factory :city do |f|
    f.association :state
    f.name 'foo'
  end

  factory :bank do
    name 'Foo'
    code { rand 900...18_000 }
  end

  factory :user_admin_role do |f|
    f.association :user, factory: user
    role_label 'balance'
  end

  factory :address do |f|
    f.association :country, factory: :country
    f.association :state, factory: :state
    f.address_street 'fooo'
    f.address_number '123'
    f.address_city 'fooo bar'
    f.address_neighbourhood 'bar'
    f.address_zip_code '123344333'
    f.phone_number '1233443355'
  end

  factory :bank_account do |f|
    # f.association :user, factory: :user
    f.association :bank, factory: :bank
    input_bank_number nil
    # owner_name "Foo Bar"
    # owner_document "97666238991"
    account_digit '1'
    agency '1234'
    agency_digit '1'
    account '12345'
  end

  factory :single_bank_account, class: BankAccount do |f|
    f.association :bank, factory: :bank
    owner_name 'Foo'
    owner_document '000'
    account_digit '1'
    agency '1234'
    account '1'
  end

  factory :shipping_fee do |f|
    f.association :reward
    destination 'all'
    value 20
  end

  factory :mail_marketing_list do |f|
    f.provider 'sendgrid'
    sequence :label do |n|
      "label_#{n}"
    end
    sequence :list_id do |n|
      "list_#{n}"
    end
  end

  factory :mail_marketing_user do |f|
    f.association :user
    f.association :mail_marketing_list
  end
end
