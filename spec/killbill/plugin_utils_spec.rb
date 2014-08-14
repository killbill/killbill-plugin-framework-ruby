require "spec/spec_helper"
require "killbill/helpers/utils"
require "killbill/gen/plugin-api/payment_transaction_info_plugin"
require "killbill/gen/api/plugin_property"

describe Killbill::Plugin::Utils do
  describe ".combine_trx_infos" do

    before do
      @t1=Killbill::Plugin::Model::PaymentTransactionInfoPlugin.new
      @t1.kb_payment_id=1
      @t1.kb_transaction_payment_id=2
      @t1.transaction_type=3
      @t1.amount=4
      @t1.currency=5
      @t1.created_date=6
      @t1.effective_date=7
      @t1.status=:PROCESSED
      @t1.gateway_error=9
      @t1.gateway_error_code=10
      @t1.first_payment_reference_id=11
      @t1.second_payment_reference_id=12

      @t1.properties=[]
      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_12_test"
      prop.value=20
      prop.is_updatable=false
      @t1.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="test_property_1"
      prop.value=21
      prop.is_updatable=true
      @t1.properties << prop


      @t2=Killbill::Plugin::Model::PaymentTransactionInfoPlugin.new
      @t2.kb_payment_id=101
      @t2.kb_transaction_payment_id=102
      @t2.transaction_type=103
      @t2.amount=104
      @t2.currency=105
      @t2.created_date=106
      @t2.effective_date=107
      @t2.status=:PROCESSED
      @t2.gateway_error=109
      @t2.gateway_error_code=1010
      @t2.first_payment_reference_id=1011
      @t2.second_payment_reference_id=1012

      @t2b=Killbill::Plugin::Model::PaymentTransactionInfoPlugin.new
      @t2b.kb_payment_id=201
      @t2b.kb_transaction_payment_id=202
      @t2b.transaction_type=203
      @t2b.amount=204
      @t2b.currency=205
      @t2b.created_date=206
      @t2b.effective_date=207
      @t2b.status=:PROCESSED
      @t2b.gateway_error=209
      @t2b.gateway_error_code=2010
      @t2b.first_payment_reference_id=2011
      @t2b.second_payment_reference_id=2012

      @t1e=Killbill::Plugin::Model::PaymentTransactionInfoPlugin.new
      @t1e.kb_payment_id=1
      @t1e.kb_transaction_payment_id=2
      @t1e.transaction_type=3
      @t1e.amount=4
      @t1e.currency=5
      @t1e.created_date=6
      @t1e.effective_date=7
      @t1e.status=:ERROR
      @t1e.gateway_error=9
      @t1e.gateway_error_code=10
      @t1e.first_payment_reference_id=11
      @t1e.second_payment_reference_id=12

      @t2e=Killbill::Plugin::Model::PaymentTransactionInfoPlugin.new
      @t2e.kb_payment_id=101
      @t2e.kb_transaction_payment_id=102
      @t2e.transaction_type=103
      @t2e.amount=104
      @t2e.currency=105
      @t2e.created_date=106
      @t2e.effective_date=107
      @t2e.status=:ERROR
      @t2e.gateway_error=109
      @t2e.gateway_error_code=1010
      @t2e.first_payment_reference_id=1011
      @t2e.second_payment_reference_id=1012

      @p1=Killbill::Plugin::Model::PluginProperty.new
      @p1.key=1
      @p1.value=2
      @p1.is_updatable=true

      @tc1=Killbill::Plugin::Model::PaymentTransactionInfoPlugin.new
      @tc1.kb_payment_id=301
      @tc1.kb_transaction_payment_id=302
      @tc1.transaction_type=303
      @tc1.amount=304
      @tc1.currency=305
      @tc1.created_date=306
      @tc1.effective_date=307
      @tc1.status=:PROCESSED
      @tc1.gateway_error=309
      @tc1.gateway_error_code=3010
      @tc1.first_payment_reference_id=3011
      @tc1.second_payment_reference_id=3012
      @tc1.properties=[]

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_count"
      prop.value=2
      prop.is_updatable=true
      @tc1.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_1_amount"
      prop.value=304
      prop.is_updatable=false
      @tc1.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_1_currency"
      prop.value=305
      prop.is_updatable=false
      @tc1.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_1_status"
      prop.value=:PROCESSED
      prop.is_updatable=false
      @tc1.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_1_gateway_error"
      prop.value=309
      prop.is_updatable=false
      @tc1.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_1_gateway_error_code"
      prop.value=3010
      prop.is_updatable=false
      @tc1.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_1_first_payment_reference_id"
      prop.value=3011
      prop.is_updatable=false
      @tc1.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_1_second_payment_reference_id"
      prop.value=3012
      prop.is_updatable=false
      @tc1.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_2_amount"
      prop.value=354
      prop.is_updatable=false
      @tc1.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_2_currency"
      prop.value=355
      prop.is_updatable=false
      @tc1.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_2_status"
      prop.value=:PROCESSED
      prop.is_updatable=false
      @tc1.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_2_gateway_error"
      prop.value=359
      prop.is_updatable=false
      @tc1.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_2_gateway_error_code"
      prop.value=3510
      prop.is_updatable=false
      @tc1.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_2_first_payment_reference_id"
      prop.value=3511
      prop.is_updatable=false
      @tc1.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_2_second_payment_reference_id"
      prop.value=3512
      prop.is_updatable=false
      @tc1.properties << prop

      @tc2=Killbill::Plugin::Model::PaymentTransactionInfoPlugin.new
      @tc2.kb_payment_id=401
      @tc2.kb_transaction_payment_id=402
      @tc2.transaction_type=403
      @tc2.amount=404
      @tc2.currency=405
      @tc2.created_date=406
      @tc2.effective_date=407
      @tc2.status=:PROCESSED
      @tc2.gateway_error=409
      @tc2.gateway_error_code=4010
      @tc2.first_payment_reference_id=4011
      @tc2.second_payment_reference_id=4012
      @tc2.properties=[]

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_count"
      prop.value=2
      prop.is_updatable=true
      @tc2.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_1_amount"
      prop.value=404
      prop.is_updatable=false
      @tc2.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_1_currency"
      prop.value=405
      prop.is_updatable=false
      @tc2.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_1_status"
      prop.value=:PROCESSED
      prop.is_updatable=false
      @tc2.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_1_gateway_error"
      prop.value=409
      prop.is_updatable=false
      @tc2.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_1_gateway_error_code"
      prop.value=4010
      prop.is_updatable=false
      @tc2.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_1_first_payment_reference_id"
      prop.value=4011
      prop.is_updatable=false
      @tc2.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_1_second_payment_reference_id"
      prop.value=4012
      prop.is_updatable=false
      @tc2.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_2_amount"
      prop.value=454
      prop.is_updatable=false
      @tc2.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_2_currency"
      prop.value=455
      prop.is_updatable=false
      @tc2.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_2_status"
      prop.value=:PROCESSED
      prop.is_updatable=false
      @tc2.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_2_gateway_error"
      prop.value=459
      prop.is_updatable=false
      @tc2.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_2_gateway_error_code"
      prop.value=4510
      prop.is_updatable=false
      @tc2.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_2_first_payment_reference_id"
      prop.value=4511
      prop.is_updatable=false
      @tc2.properties << prop

      prop=Killbill::Plugin::Model::PluginProperty.new
      prop.key="transaction_2_second_payment_reference_id"
      prop.value=4512
      prop.is_updatable=false
      @tc2.properties << prop
    end

    it "should work when combine two nils" do
      t3=Killbill::Plugin::Utils.combine_trx_infos(nil,nil)
      t3.should be_nil
    end

    it "should work when combine one one non-nil and one nil" do
      t3=Killbill::Plugin::Utils.combine_trx_infos(@t1, nil)

      t3.kb_payment_id.should eq(1)
      t3.kb_transaction_payment_id.should eq(2)
      t3.transaction_type.should eq(3)
      t3.amount.should eq(4)
      t3.currency.should eq(5)
      t3.created_date.should eq(6)
      t3.effective_date.should eq(7)
      t3.status.should eq(:PROCESSED)
      t3.gateway_error.should eq(9)
      t3.gateway_error_code.should eq(10)
      t3.first_payment_reference_id.should eq(11)
      t3.second_payment_reference_id.should eq(12)
      t3.properties.length.should eq(2)
      t3.properties.each do |p|
        if p.key=="transaction_12_test"
          p.value.should eq(20)
        elsif p.key=="test_property_1"
          p.value.should eq(21)
        else 1.should eq(0)
        end
      end

      t3=Killbill::Plugin::Utils.combine_trx_infos(nil, @t1)

      t3.kb_payment_id.should eq(1)
      t3.kb_transaction_payment_id.should eq(2)
      t3.transaction_type.should eq(3)
      t3.amount.should eq(4)
      t3.currency.should eq(5)
      t3.created_date.should eq(6)
      t3.effective_date.should eq(7)
      t3.status.should eq(:PROCESSED)
      t3.gateway_error.should eq(9)
      t3.gateway_error_code.should eq(10)
      t3.first_payment_reference_id.should eq(11)
      t3.second_payment_reference_id.should eq(12)
      t3.properties.length.should eq(2)
      t3.properties.each do |p|
        if p.key=="transaction_12_test"
          p.value.should eq(20)
        elsif p.key=="test_property_1"
          p.value.should eq(21)
        else 1.should eq(0)
        end
      end
    end

    it "status should be :PROCESSED when both are :PROCESSED" do

      t3=Killbill::Plugin::Utils.combine_trx_infos(@t1,@t2)
      t3.status.should eq(:PROCESSED)

    end

    it "should work when either is not :PROCESSED" do
      t3=Killbill::Plugin::Utils.combine_trx_infos(@t1,@t2e)
      t3.status.should eq(:ERROR)

      t3=Killbill::Plugin::Utils.combine_trx_infos(@t1e,@t2)
      t3.status.should eq(:ERROR)

    end

    it "should work when both are not :PROCESSED" do
      t3=Killbill::Plugin::Utils.combine_trx_infos(@t1e,@t2e)
      t3.status.should eq(:ERROR)

    end

    it "should take the left values for non-status fields" do
      t3=Killbill::Plugin::Utils.combine_trx_infos(@t1, @t2)

      t3.kb_payment_id.should eq(1)
      t3.kb_transaction_payment_id.should eq(2)
      t3.transaction_type.should eq(3)
      t3.amount.should eq(4)
      t3.currency.should eq(5)
      t3.created_date.should eq(6)
      t3.effective_date.should eq(7)
      t3.gateway_error.should eq(9)
      t3.gateway_error_code.should eq(10)
      t3.first_payment_reference_id.should eq(11)
      t3.second_payment_reference_id.should eq(12)

    end



    it "should aggregate properties correctly when starting with two non-combined objects" do
      t3=Killbill::Plugin::Utils.combine_trx_infos(@t2, @t2b)
      t3.properties.length.should eq(15)
      t3.properties.each do |prop|
        if prop.key=="transaction_1_amount"
          prop.value.should eq(104)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_1_currency"
          prop.value.should eq(105)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_1_status"
          prop.value.should eq(:PROCESSED)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_1_gateway_error"
          prop.value.should eq(109)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_1_gateway_error_code"
          prop.value.should eq(1010)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_1_first_payment_reference_id"
          prop.value.should eq(1011)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_1_second_payment_reference_id"
          prop.value.should eq(1012)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_2_amount"
          prop.value.should eq(204)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_2_currency"
          prop.value.should eq(205)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_2_status"
          prop.value.should eq(:PROCESSED)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_2_gateway_error"
          prop.value.should eq(209)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_2_gateway_error_code"
          prop.value.should eq(2010)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_2_first_payment_reference_id"
          prop.value.should eq(2011)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_2_second_payment_reference_id"
          prop.value.should eq(2012)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_count"
          prop.value.should eq(2)
          prop.is_updatable.should eq(true)
        else 1.should eq(0)
        end
      end
    end

    it "should aggregate properties correctly when starting with one previously combined object and one non-combined object" do
      #t3=Killbill::Plugin::Utils.combine_trx_infos(@t2, @tc2)
      #t3=Killbill::Plugin::Utils.combine_trx_infos(@t2, @tc1)
      t3=Killbill::Plugin::Utils.combine_trx_infos(@tc1, @t2)
      t3.properties.length.should eq(22)
      t3.properties.each do |prop|
        case prop.key
          when "transaction_1_amount"
            prop.value.should eq(304)
            prop.is_updatable.should eq(false)
          when "transaction_1_currency"
            prop.value.should eq(305)
            prop.is_updatable.should eq(false)
          when "transaction_1_status"
            prop.value.should eq(:PROCESSED)
            prop.is_updatable.should eq(false)
          when "transaction_1_gateway_error"
            prop.value.should eq(309)
            prop.is_updatable.should eq(false)
          when "transaction_1_gateway_error_code"
            prop.value.should eq(3010)
            prop.is_updatable.should eq(false)
          when "transaction_1_first_payment_reference_id"
            prop.value.should eq(3011)
            prop.is_updatable.should eq(false)
          when "transaction_1_second_payment_reference_id"
            prop.value.should eq(3012)
            prop.is_updatable.should eq(false)
          when "transaction_2_amount"
            prop.value.should eq(354)
            prop.is_updatable.should eq(false)
          when "transaction_2_currency"
            prop.value.should eq(355)
            prop.is_updatable.should eq(false)
          when "transaction_2_status"
            prop.value.should eq(:PROCESSED)
            prop.is_updatable.should eq(false)
          when "transaction_2_gateway_error"
            prop.value.should eq(359)
            prop.is_updatable.should eq(false)
          when "transaction_2_gateway_error_code"
            prop.value.should eq(3510)
            prop.is_updatable.should eq(false)
          when "transaction_2_first_payment_reference_id"
            prop.value.should eq(3511)
            prop.is_updatable.should eq(false)
          when "transaction_2_second_payment_reference_id"
            prop.value.should eq(3512)
            prop.is_updatable.should eq(false)
          when "transaction_3_amount"
            prop.value.should eq(104)
            prop.is_updatable.should eq(false)
          when "transaction_3_currency"
            prop.value.should eq(105)
            prop.is_updatable.should eq(false)
          when "transaction_3_status"
            prop.value.should eq(:PROCESSED)
            prop.is_updatable.should eq(false)
          when "transaction_3_gateway_error"
            prop.value.should eq(109)
            prop.is_updatable.should eq(false)
          when "transaction_3_gateway_error_code"
            prop.value.should eq(1010)
            prop.is_updatable.should eq(false)
          when "transaction_3_first_payment_reference_id"
            prop.value.should eq(1011)
            prop.is_updatable.should eq(false)
          when "transaction_3_second_payment_reference_id"
            prop.value.should eq(1012)
            prop.is_updatable.should eq(false)
          when "transaction_count"
            prop.value.should eq(3)
            prop.is_updatable.should eq(true)
          else 1.should eq(0)
        end
      end


      t3=Killbill::Plugin::Utils.combine_trx_infos(@t2, @tc1)
      t3.properties.each do |prop|
        case prop.key
          when "transaction_2_amount"
            prop.value.should eq(304)
            prop.is_updatable.should eq(false)
          when "transaction_2_currency"
            prop.value.should eq(305)
            prop.is_updatable.should eq(false)
          when "transaction_2_status"
            prop.value.should eq(:PROCESSED)
            prop.is_updatable.should eq(false)
          when "transaction_2_gateway_error"
            prop.value.should eq(309)
            prop.is_updatable.should eq(false)
          when "transaction_2_gateway_error_code"
            prop.value.should eq(3010)
            prop.is_updatable.should eq(false)
          when "transaction_2_first_payment_reference_id"
            prop.value.should eq(3011)
            prop.is_updatable.should eq(false)
          when "transaction_2_second_payment_reference_id"
            prop.value.should eq(3012)
            prop.is_updatable.should eq(false)
          when "transaction_3_amount"
            prop.value.should eq(354)
            prop.is_updatable.should eq(false)
          when "transaction_3_currency"
            prop.value.should eq(355)
            prop.is_updatable.should eq(false)
          when "transaction_3_status"
            prop.value.should eq(:PROCESSED)
            prop.is_updatable.should eq(false)
          when "transaction_3_gateway_error"
            prop.value.should eq(359)
            prop.is_updatable.should eq(false)
          when "transaction_3_gateway_error_code"
            prop.value.should eq(3510)
            prop.is_updatable.should eq(false)
          when "transaction_3_first_payment_reference_id"
            prop.value.should eq(3511)
            prop.is_updatable.should eq(false)
          when "transaction_3_second_payment_reference_id"
            prop.value.should eq(3512)
            prop.is_updatable.should eq(false)
          when "transaction_1_amount"
            prop.value.should eq(104)
            prop.is_updatable.should eq(false)
          when "transaction_1_currency"
            prop.value.should eq(105)
            prop.is_updatable.should eq(false)
          when "transaction_1_status"
            prop.value.should eq(:PROCESSED)
            prop.is_updatable.should eq(false)
          when "transaction_1_gateway_error"
            prop.value.should eq(109)
            prop.is_updatable.should eq(false)
          when "transaction_1_gateway_error_code"
            prop.value.should eq(1010)
            prop.is_updatable.should eq(false)
          when "transaction_1_first_payment_reference_id"
            prop.value.should eq(1011)
            prop.is_updatable.should eq(false)
          when "transaction_1_second_payment_reference_id"
            prop.value.should eq(1012)
            prop.is_updatable.should eq(false)
          when "transaction_count"
            prop.value.should eq(3)
            prop.is_updatable.should eq(true)
          else 1.should eq(0)
        end
      end
    end

    it "should aggregate properties correctly when starting with two previously combined objects" do
      t3=Killbill::Plugin::Utils.combine_trx_infos(@tc1, @tc2)
      t3.properties.length.should eq(29)

      t3.properties.each do |prop|
        case prop.key
          when "transaction_1_amount"
            prop.value.should eq(304)
            prop.is_updatable.should eq(false)
          when "transaction_1_currency"
            prop.value.should eq(305)
            prop.is_updatable.should eq(false)
          when "transaction_1_status"
            prop.value.should eq(:PROCESSED)
            prop.is_updatable.should eq(false)
          when "transaction_1_gateway_error"
            prop.value.should eq(309)
            prop.is_updatable.should eq(false)
          when "transaction_1_gateway_error_code"
            prop.value.should eq(3010)
            prop.is_updatable.should eq(false)
          when "transaction_1_first_payment_reference_id"
            prop.value.should eq(3011)
            prop.is_updatable.should eq(false)
          when "transaction_1_second_payment_reference_id"
            prop.value.should eq(3012)
            prop.is_updatable.should eq(false)
          when "transaction_2_amount"
            prop.value.should eq(354)
            prop.is_updatable.should eq(false)
          when "transaction_2_currency"
            prop.value.should eq(355)
            prop.is_updatable.should eq(false)
          when "transaction_2_status"
            prop.value.should eq(:PROCESSED)
            prop.is_updatable.should eq(false)
          when "transaction_2_gateway_error"
            prop.value.should eq(359)
            prop.is_updatable.should eq(false)
          when "transaction_2_gateway_error_code"
            prop.value.should eq(3510)
            prop.is_updatable.should eq(false)
          when "transaction_2_first_payment_reference_id"
            prop.value.should eq(3511)
            prop.is_updatable.should eq(false)
          when "transaction_2_second_payment_reference_id"
            prop.value.should eq(3512)
            prop.is_updatable.should eq(false)
          when "transaction_3_amount"
            prop.value.should eq(404)
            prop.is_updatable.should eq(false)
          when "transaction_3_currency"
            prop.value.should eq(405)
            prop.is_updatable.should eq(false)
          when "transaction_3_status"
            prop.value.should eq(:PROCESSED)
            prop.is_updatable.should eq(false)
          when "transaction_3_gateway_error"
            prop.value.should eq(409)
            prop.is_updatable.should eq(false)
          when "transaction_3_gateway_error_code"
            prop.value.should eq(4010)
            prop.is_updatable.should eq(false)
          when "transaction_3_first_payment_reference_id"
            prop.value.should eq(4011)
            prop.is_updatable.should eq(false)
          when "transaction_3_second_payment_reference_id"
            prop.value.should eq(4012)
            prop.is_updatable.should eq(false)
          when "transaction_4_amount"
            prop.value.should eq(454)
            prop.is_updatable.should eq(false)
          when "transaction_4_currency"
            prop.value.should eq(455)
            prop.is_updatable.should eq(false)
          when "transaction_4_status"
            prop.value.should eq(:PROCESSED)
            prop.is_updatable.should eq(false)
          when "transaction_4_gateway_error"
            prop.value.should eq(459)
            prop.is_updatable.should eq(false)
          when "transaction_4_gateway_error_code"
            prop.value.should eq(4510)
            prop.is_updatable.should eq(false)
          when "transaction_4_first_payment_reference_id"
            prop.value.should eq(4511)
            prop.is_updatable.should eq(false)
          when "transaction_4_second_payment_reference_id"
            prop.value.should eq(4512)
            prop.is_updatable.should eq(false)
          when "transaction_count"
            prop.value.should eq(4)
            prop.is_updatable.should eq(true)
          else 1.should eq(0)
        end
      end

    end

    it "should create correct properties" do
      props=Killbill::Plugin::Utils.make_trx_info_props(@t1,0)
      props.length.should eq(7)
      props.each do |prop|
        if prop.key=="transaction_1_amount"
          prop.value.should eq(4)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_1_currency"
          prop.value.should eq(5)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_1_status"
          prop.value.should eq(:PROCESSED)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_1_gateway_error"
          prop.value.should eq(9)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_1_gateway_error_code"
          prop.value.should eq(10)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_1_first_payment_reference_id"
          prop.value.should eq(11)
          prop.is_updatable.should eq(false)
        elsif prop.key=="transaction_1_second_payment_reference_id"
          prop.value.should eq(12)
          prop.is_updatable.should eq(false)
        else 1.should eq(0)
        end
      end

    end


  end
end


