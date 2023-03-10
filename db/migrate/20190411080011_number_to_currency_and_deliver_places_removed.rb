class NumberToCurrencyAndDeliverPlacesRemoved < ActiveRecord::Migration[4.2]

  def up
    execute <<-SQL

    CREATE OR REPLACE FUNCTION public.numberToCurrency(number numeric)
    RETURNS text
    LANGUAGE sql
    STABLE
   AS $function$
           SELECT replace(round(number, 2)::text, '.'::text, ','::text)
       $function$
   ;;

   CREATE OR REPLACE VIEW "public"."contribution_reports_for_project_owners" AS
 SELECT b.project_id,
    COALESCE(r.id, 0) AS reward_id,
    p.user_id AS project_owner_id,
    r.description AS reward_description,
    (zone_timestamp(r.deliver_at))::date AS deliver_at,
    (zone_timestamp(pa.paid_at))::date AS confirmed_at,
    (zone_timestamp(b.created_at))::date AS created_at,
    numberToCurrency(pa.value) AS contribution_value,
    numberToCurrency((pa.value * p.service_fee) - pa.gateway_fee) AS service_fee,
    numberToCurrency(pa.gateway_fee) AS payment_method_fee,
    numberToCurrency(pa.value * ((1)::numeric - p.service_fee)) AS contribution_value_net,
    u.email AS user_email,
    COALESCE(u.cpf, b.payer_document) AS cpf,
    u.name AS user_name,
    u.public_name,
    pa.payment_method AS gateway,
    b.anonymous,
    pa.state,
    waiting_payment(pa.*) AS waiting_payment,
        CASE
            WHEN (su.address IS NOT NULL) THEN (su.address ->> 'address_street'::text)
            ELSE add.address_street
        END AS street,
        CASE
            WHEN (su.address IS NOT NULL) THEN (su.address ->> 'address_complement'::text)
            ELSE add.address_complement
        END AS complement,
        CASE
            WHEN (su.address IS NOT NULL) THEN (su.address ->> 'address_number'::text)
            ELSE add.address_number
        END AS address_number,
        CASE
            WHEN (su.address IS NOT NULL) THEN (su.address ->> 'address_neighbourhood'::text)
            ELSE add.address_neighbourhood
        END AS neighbourhood,
        CASE
            WHEN (su.address IS NOT NULL) THEN (su.address ->> 'address_city'::text)
            ELSE add.address_city
        END AS city,
        CASE
            WHEN (su.address IS NOT NULL) THEN (su.state_name)::text
            ELSE add.address_state
        END AS address_state,
        CASE
            WHEN (su.address IS NOT NULL) THEN (su.address ->> 'address_zip_code'::text)
            ELSE add.address_zip_code
        END AS zip_code,
        CASE
            WHEN (sf.id IS NULL) THEN ''::text
            ELSE (st.acronym)::text
        END AS shipping_choice,
        CASE
            WHEN (sf.id IS NULL) THEN ''::text
            ELSE (' R$ '::text || numberToCurrency(sf.value))
        END AS shipping_amount,
    COALESCE(
        CASE
            WHEN (r.shipping_options = 'free'::text) THEN 'Sem frete envolvido'::text
            WHEN (r.shipping_options = 'presential'::text) THEN 'Retirada presencial'::text
            WHEN (r.shipping_options = 'international'::text) THEN 'Frete Nacional e Internacional'::text
            WHEN (r.shipping_options = 'national'::text) THEN 'Frete Nacional'::text
            ELSE NULL::text
        END, ''::text) AS shipping_option,
    su.open_questions,
    su.multiple_choice_questions,
    r.title,
        CASE
            WHEN (su.address IS NOT NULL) THEN 'Entrega'::text
            ELSE 'Pagamento - S?? use esse endere??o se n??o conseguir confirmar o endere??o de entrega! Para confirmar o endere??o de entrega, envie um question??rio. Saiba como aqui: http://catar.se/quest'::text
        END AS address_type,
    u.id AS user_id,
    pa.gateway_id AS contribution_id
   FROM ((((((((contributions b
     JOIN users u ON ((u.id = b.user_id)))
     JOIN projects p ON ((b.project_id = p.id)))
     JOIN payments pa ON ((pa.contribution_id = b.id)))
     LEFT JOIN rewards r ON ((r.id = b.reward_id)))
     LEFT JOIN shipping_fees sf ON ((sf.id = b.shipping_fee_id)))
     LEFT JOIN "1".surveys su ON ((su.contribution_id = pa.contribution_id)))
     LEFT JOIN addresses add ON ((add.id = b.address_id)))
     LEFT JOIN states st ON ((st.id = add.state_id)))
  WHERE (pa.state = ANY (ARRAY['paid'::text, 'pending'::text, 'pending_refund'::text, 'refunded'::text, 'chargeback'::text]));
  ;;

    SQL
  end

  def down
    execute <<-SQL

    CREATE OR REPLACE VIEW "public"."contribution_reports_for_project_owners" AS
    SELECT b.project_id,
       COALESCE(r.id, 0) AS reward_id,
       p.user_id AS project_owner_id,
       r.description AS reward_description,
       (zone_timestamp(r.deliver_at))::date AS deliver_at,
       (zone_timestamp(pa.paid_at))::date AS confirmed_at,
       (zone_timestamp(b.created_at))::date AS created_at,
       replace((pa.value)::text, '.'::text, ','::text) AS contribution_value,
       replace((round(((pa.value * p.service_fee) - pa.gateway_fee), 2))::text, '.'::text, ','::text) AS service_fee,
       replace((round(pa.gateway_fee, 2))::text, '.'::text, ','::text) AS payment_method_fee,
       replace((round((pa.value * ((1)::numeric - p.service_fee)), 2))::text, '.'::text, ','::text) AS contribution_value_net,
       u.email AS user_email,
       COALESCE(u.cpf, b.payer_document) AS cpf,
       u.name AS user_name,
       u.public_name,
       pa.payment_method AS gateway,
       b.anonymous,
       pa.state,
       waiting_payment(pa.*) AS waiting_payment,
           CASE
               WHEN (su.address IS NOT NULL) THEN (su.address ->> 'address_street'::text)
               ELSE add.address_street
           END AS street,
           CASE
               WHEN (su.address IS NOT NULL) THEN (su.address ->> 'address_complement'::text)
               ELSE add.address_complement
           END AS complement,
           CASE
               WHEN (su.address IS NOT NULL) THEN (su.address ->> 'address_number'::text)
               ELSE add.address_number
           END AS address_number,
           CASE
               WHEN (su.address IS NOT NULL) THEN (su.address ->> 'address_neighbourhood'::text)
               ELSE add.address_neighbourhood
           END AS neighbourhood,
           CASE
               WHEN (su.address IS NOT NULL) THEN (su.address ->> 'address_city'::text)
               ELSE add.address_city
           END AS city,
           CASE
               WHEN (su.address IS NOT NULL) THEN (su.state_name)::text
               ELSE add.address_state
           END AS address_state,
           CASE
               WHEN (su.address IS NOT NULL) THEN (su.address ->> 'address_zip_code'::text)
               ELSE add.address_zip_code
           END AS zip_code,
           CASE
               WHEN (sf.id IS NULL) THEN ''::text
               ELSE st.acronym::text
           END AS shipping_choice,
           CASE
               WHEN (sf.id IS NULL) THEN ''::text
               ELSE (' R$ '::text || sf.value)
           END AS shipping_amount,
       COALESCE(
           CASE
               WHEN (r.shipping_options = 'free'::text) THEN 'Sem frete envolvido'::text
               WHEN (r.shipping_options = 'presential'::text) THEN 'Retirada presencial'::text
               WHEN (r.shipping_options = 'international'::text) THEN 'Frete Nacional e Internacional'::text
               WHEN (r.shipping_options = 'national'::text) THEN 'Frete Nacional'::text
               ELSE NULL::text
           END, ''::text) AS shipping_option,
       su.open_questions,
       su.multiple_choice_questions,
       r.title,
           CASE
               WHEN (su.address IS NOT NULL) THEN 'Entrega'::text
               ELSE 'Pagamento - S?? use esse endere??o se n??o conseguir confirmar o endere??o de entrega! Para confirmar o endere??o de entrega, envie um question??rio. Saiba como aqui: http://catar.se/quest'::text
           END AS address_type,
       u.id AS user_id,
       pa.gateway_id AS contribution_id
      FROM ((((((((contributions b
        JOIN users u ON ((u.id = b.user_id)))
        JOIN projects p ON ((b.project_id = p.id)))
        JOIN payments pa ON ((pa.contribution_id = b.id)))
        LEFT JOIN rewards r ON ((r.id = b.reward_id)))
        LEFT JOIN shipping_fees sf ON ((sf.id = b.shipping_fee_id)))
        LEFT JOIN "1".surveys su ON ((su.contribution_id = pa.contribution_id)))
        LEFT JOIN addresses add ON ((add.id = b.address_id)))
        LEFT JOIN states st ON (st.id = add.state_id))
     WHERE (pa.state = ANY (ARRAY['paid'::text, 'pending'::text, 'pending_refund'::text, 'refunded'::text, 'chargeback'::text]));
     ;

    SQL
  end
end
