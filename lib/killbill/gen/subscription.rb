
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class Subscription

        attr_reader :bundle_id, :state, :source_type, :start_date, :end_date, :future_end_date, :current_plan, :last_active_plan, :current_price_list, :current_phase, :last_active_product_name, :last_active_price_list_name, :last_active_category_name, :last_active_billing_period, :charged_through_date, :paid_through_date, :category, :pending_transition, :previous_transition

        def initialize(bundle_id, state, source_type, start_date, end_date, future_end_date, current_plan, last_active_plan, current_price_list, current_phase, last_active_product_name, last_active_price_list_name, last_active_category_name, last_active_billing_period, charged_through_date, paid_through_date, category, pending_transition, previous_transition)
          @bundle_id = bundle_id
          @state = state
          @source_type = source_type
          @start_date = start_date
          @end_date = end_date
          @future_end_date = future_end_date
          @current_plan = current_plan
          @last_active_plan = last_active_plan
          @current_price_list = current_price_list
          @current_phase = current_phase
          @last_active_product_name = last_active_product_name
          @last_active_price_list_name = last_active_price_list_name
          @last_active_category_name = last_active_category_name
          @last_active_billing_period = last_active_billing_period
          @charged_through_date = charged_through_date
          @paid_through_date = paid_through_date
          @category = category
          @pending_transition = pending_transition
          @previous_transition = previous_transition
        end
      end
    end
  end
end
