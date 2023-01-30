# frozen_string_literal: true

CatarsePagarme.configure do |config|
  config.api_key = CatarseSettings.get_without_cache(Rails.env.production? ? :pagarme_api_key : :pagarme_test_api_key)
  config.konduto_api_key = CatarseSettings.get_without_cache(Rails.env.production? ? :konduto_api_key : :konduto_test_api_key)
  config.ecr_key = CatarseSettings.get_without_cache(Rails.env.production? ? :pagarme_encryption_key : :pagarme_test_encryption_key)
  config.slip_tax = CatarseSettings.get_without_cache(:pagarme_slip_tax)
  config.credit_card_tax = CatarseSettings.get_without_cache(:pagarme_credit_card_tax)
  config.interest_rate = CatarseSettings.get_without_cache(:pagarme_interest_rate)
  config.credit_card_cents_fee = CatarseSettings.get_without_cache(:pagarme_cents_fee)
  config.host = CatarseSettings.get_without_cache(:host)
  config.subdomain = Rails.env.production? ? 'www' : 'sandbox'
  config.protocol = 'https'
  config.max_installments = CatarseSettings.get_without_cache(:pagarme_max_installments)
  config.minimum_value_for_installment = CatarseSettings.get_without_cache(:pagarme_minimum_value_for_installment)
  config.use_simility = false

  config.pagarme_tax = CatarseSettings.get_without_cache(:pagarme_tax)
  config.cielo_tax = CatarseSettings.get_without_cache(:cielo_tax)
  config.antifraud_tax = CatarseSettings.get_without_cache(:antifraud_tax)
  config.stone_tax = CatarseSettings.get_without_cache(:stone_tax)
  config.stone_installment_tax = CatarseSettings.get_without_cache(:stone_installment_tax)
  config.cielo_installment_diners_tax = CatarseSettings.get_without_cache(:cielo_installment_diners_tax)
  config.cielo_installment_not_diners_tax = CatarseSettings.get_without_cache(:cielo_installment_not_diners_tax)
  config.cielo_installment_amex_tax = CatarseSettings.get_without_cache(:cielo_installment_amex_tax)
  config.cielo_installment_not_amex_tax = CatarseSettings.get_without_cache(:cielo_installment_not_amex_tax)
end
