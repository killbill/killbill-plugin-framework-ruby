module Killbill
  module Plugin
    class Utils

      # This allows us to combine PaymentTransactionInfoPlugin objects to support multiple settlements in one payment
      def self.combine_trx_infos(t1, t2)

        # Nothing to do if both are nil, need to swap if only t1 is nil
        if t1.nil?
          return nil if t2.nil?
          t1=t2
          t2=nil
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
        t3.status=t1.status==:PROCESSED && ( t2.nil? || t2.status==:PROCESSED) ? :PROCESSED : :ERROR
        t3.gateway_error=t1.gateway_error
        t3.gateway_error_code=t1.gateway_error_code
        t3.first_payment_reference_id=t1.first_payment_reference_id
        t3.second_payment_reference_id=t1.second_payment_reference_id
        t3.test1=t1.status
        t3.test2=t1.status== :PROCESSED && ( t2.nil? || t2.status== :PROCESSED)

        # Now we need to combine the properties for the two objects. When we combine objects, we need to make sure
        # that we don't lose any information so the first time an object is combined with others its values need to
        # be stored as properties and we add a transaction_count property. Subsequently, when we combine such objects
        # we need to renumber the property keys to maintain uniqueness and update the transaction_count

        t3.properties=[]

        # Find the transaction count for t1 if it exists and clone the properties from t1 into t3
        t1_trx_count=nil
        unless defined?(t1.properties)==nil || t1.properties.nil?
          t1.properties.each do |property|
            if property.key=='transaction_count'
              t1_trx_count=property.value
           else
             t3.properties << property.clone
            end
          end
        end

        # If the other transaction info is nil, we intentionally to not update transaction count
        return t3 if t2.nil?

        # If we don't have a transaction_count this implies we never put the transaction info values into properties so we need to do that
        if t1_trx_count.nil?
          t3.properties+=make_trx_info_props(t1,0)
          t1_trx_count=1
        end

        # Find the transaction count for t2 if it exists
        t2_trx_count=nil
        unless defined?(t2.properties)==nil || t2.properties.nil?
          t2.properties.each do |property|
            if property.key=='transaction_count'
              t2_trx_count=property.value
            end
          end
        end

        # If we don't have a transaction_count this implies we never put the transaction info values into properties so we need to do that and clone the other properties
        if t2_trx_count.nil?
          t3.properties+=make_trx_info_props(t2,t1_trx_count)
          unless defined?(t2.properties)==nil || t2.properties.nil?
            t2.properties.each do |property|
              t3.properties << property.clone
            end
          end
          t2_trx_count=1

        # If there is a transaction_count, then we need to clone the properties and renumber the properties to maintain unique naming with respect to t1
        else
          t2_clone_properties=[]
          t2.properties.each do |property|
            next if property.key=="transaction_count"
            # Check to see if this is like "transaction_somenumber_some_instance_variable_name" so we can generate a unique property name
            keymatch=property.key.match(/^transaction_\d*_/)
            unless keymatch.nil?
              # split apart the key ["","transaction_{n}","some_property_name"]
              proppart=property.key.partition(keymatch.values_at(0)[0])
              # Get the transaction number by itself so we can calculate the new number
              prop_trx_num=proppart[1].partition("_")[2].rpartition("_")[0].to_i
              prop_trx_num+=t1_trx_count
              # Rebuild the property key
              property.key="transaction_#{prop_trx_num}_"+ proppart[2]
            end
            t2_clone_properties << property
          end
          t3.properties+=t2_clone_properties
        end

        # Store the new transaction count
        p=Killbill::Plugin::Model::PluginProperty.new
        p.key='transaction_count'
        p.value=t1_trx_count+t2_trx_count
        p.is_updatable=true
        t3.properties << p

        return t3
      end

      # This creates an array of properties so we can store the information from the instance variables as properties
      # used by combine_trx_infos
      def self.make_trx_info_props(t1, trx_count_offset)

        new_props=[]
        ["amount","currency","status","gateway_error","gateway_error_code","first_payment_reference_id","second_payment_reference_id"].each do |inst_var|
          p=Killbill::Plugin::Model::PluginProperty.new
          p.key="transaction_#{1+trx_count_offset}_" + inst_var
          p.value=t1.instance_variable_get("@#{inst_var}")
          p.is_updatable=false
          new_props << p
        end
        return new_props
      end


    end
  end
end

