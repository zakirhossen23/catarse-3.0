# frozen_string_literal: true

class ContributionPolicy < ApplicationPolicy
  self::UserScope = Struct.new(:current_user, :user, :scope) do
    def resolve
      if current_user.try(:admin?)
        scope.available_to_display
      elsif current_user == user
        scope.where('contributions.is_confirmed')
      else
        scope.not_anonymous.where('contributions.is_confirmed')
      end
    end
  end

  def new?
    record.project.open_for_contributions? && !record.project.is_sub?
  end

  def create?
    done_by_owner_or_admin? && record.project.open_for_contributions? && !record.project.is_sub?
  end

  def update?
    done_by_owner_or_admin?
  end

  def receipt?
    done_by_owner_or_admin?
  end

  def second_slip?
    done_by_owner_or_admin?
  end

  def toggle_anonymous?
    done_by_owner_or_admin?
  end

  def toggle_delivery?
    done_by_owner_or_admin?
  end

  def show?
    done_by_owner_or_admin?
  end

  def credits_checkout?
    done_by_owner_or_admin?
  end

  def request_refund?
    done_by_owner_or_admin?
  end

  def permitted_attributes
    (record.attribute_names.map(&:to_sym) << [address_attributes: %i[address_street id country_id state_id address_number address_complement address_neighbourhood address_city address_state address_zip_code phone_number]]) - %i[user_attributes user_id user payment_service_fee payment_id]
  end
end
