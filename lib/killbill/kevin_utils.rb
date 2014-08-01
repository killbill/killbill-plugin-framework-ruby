module Killbill
  module Plugin
    class Utils
      def self.combine_trx_infos(t1, t2)
        # TODO: test correctly

        # Nothing to do if both are nil, need to swap if only t1 is nil
        if t1.nil?
          return nil if t2.nil?
          temp=t2
          t2=t1
          t1=temp
        end

        # Create the combined transaction info and set the values
        t3=Killbill::Plugin::Model::PaymentTransactionInfoPlugin.new
        t3.kb_payment_id=t1.kb_payment_id
        t3.kb_transaction_payment_id=t1.kb_transaction_payment_id
        t3.transaction_type=t1.transaction_type
        t3.amount=t1.amount
        t3.currency=t1.currency
        t3.created_date=t1.created_date
        t3.effective_date=t1.effective_date
        t3.status=t1.status==:PROCESSED && t2.status==:PROCESSED ? :PROCESSED : :ERROR
        t3.gateway_error=t1.gateway_error
        t3.gateway_error_code=t1.gateway_error_code
        t3.first_payment_reference_id=t1.first_payment_reference_id
        t3.second_payment_reference_id=t1.second_payment_reference_id
        t3.properties=t1.properties.clone

        # Nothing more to do if the other transaction info is nil, we intentionally to not update transaction count
        return t3 if t2.nil?

        # We keep a count of the number of transactions represented, partly so we can easily uniqueify the property names
        trx_count=nil

        # Find the transaction count if it exists
        t3.properties.each do |property|
          if property.key=='transaction_count'
            property.value+=1
            trx_count==property.value
          end
        end

        # If transaction_count property doesn't exist, we'll need to it. This also implies we need to add all the values from t1 into properties
        if trx_count.nil?
          # p=Killbill::Plugin::Model::PluginProperty.new
          p=Killbill::Plugin:Util::KevinTest::PluginProperty.new # TODO: reference correct version (workaround for testing)
          p.is_updatable=true
          p.key='transaction_count'
          trx_count=2
          p.value=trx_count
          t3.properties << p

          set_trx_info_props(t1,t3,1)

        end

        # Now add the values from t2 into properties
        set_trx_info_props(t2,t3,trx_count)

        return t3
      end

      def self.set_trx_info_props(source,dest,trx_count)
        ["amount","currency","status","gateway_error","gateway_error_code","first_payment_reference_id","second_payment_reference_id"].each do |inst_var|
          # p=Killbill::Plugin::Model::PluginProperty.new
          p=Killbill::Plugin:Util::KevinTest::PluginProperty.new # TODO: reference correct version (workaround for testing)
          p.key="transaction_#{trx_count}_" + inst_var
          p.value=source.instance_variable_set("@#{inst_var}")
          p.is_updatable=false
          dest.properties<<p
        end
      end

    end

    module KevinTest

      def self.check
        "yep5"
      end

      def self.test
        self.test_combine_nil_and_nil

      end

      def self.test_combine_nil_and_nil
        puts "test_combine_nil_and_nil"
        result=Killbill::Plugin::Utils.combine_trx_infos(nil,nil)
        if result.nil?
          puts "pass"
        else
          puts "fail"
        end
      end




      class PaymentTransactionInfoPlugin
        attr_accessor :kb_payment_id, :kb_transaction_payment_id, :transaction_type, :amount, :currency, :created_date, :effective_date, :status, :gateway_error, :gateway_error_code, :first_payment_reference_id, :second_payment_reference_id, :properties
      end

      class PluginProperty
        attr_accessor :key, :value, :is_updatable
      end

      def self.compare_trx_infos(t1,t2) # except properties
        ["kb_payment_id","kb_transaction_payment_id","transaction_type","amount","currency","created_date","effective_date","status","gateway_error","gateway_error_code","first_payment_reference_id","second_payment_reference_id"].each do |inst_var|
          if t1.instance_variable_get("@#{inst_var}") != t2.instance_variable_get("@#{inst_var}")
            puts "instances don't match for variable: {inst_var}"
          end
        end
      end

    end
  end
end

Killbill::Plugin::KevinTest::test
puts $: