require 'spec_helper'

class DummyInvoicePlugin < Killbill::Plugin::Invoice
end

describe Killbill::Plugin::Invoice do

  it 'should not raise exceptions by default' do
    plugin = DummyInvoicePlugin.new
    plugin.get_additional_invoice_items(nil, false, nil, nil).size.should == 0
  end

  it 'should be able to build items' do
    model                   = Killbill::Plugin::Model::InvoiceItem.new
    model.created_date      = SecureRandom.uuid
    model.updated_date      = SecureRandom.uuid
    model.invoice_id        = SecureRandom.uuid
    model.account_id        = SecureRandom.uuid
    model.currency          = SecureRandom.uuid
    model.bundle_id         = SecureRandom.uuid
    model.subscription_id   = SecureRandom.uuid
    model.start_date        = SecureRandom.uuid
    model.end_date          = SecureRandom.uuid
    model.plan_name         = SecureRandom.uuid
    model.phase_name        = SecureRandom.uuid
    model.usage_name        = SecureRandom.uuid
    model.linked_item_id    = SecureRandom.uuid
    model.id                = SecureRandom.uuid
    model.invoice_item_type = SecureRandom.uuid
    model.amount            = SecureRandom.uuid
    model.description       = SecureRandom.uuid
    model.rate              = SecureRandom.uuid

    amount      = 123
    description = 'Toto'
    type        = :TAX

    plugin = DummyInvoicePlugin.new
    item   = plugin.build_item(model, amount, description, type)

    item.created_date.should == model.created_date
    item.updated_date.should == model.updated_date
    item.invoice_id.should == model.invoice_id
    item.account_id.should == model.account_id
    item.currency.should == model.currency
    item.bundle_id.should == model.bundle_id
    item.subscription_id.should == model.subscription_id
    item.start_date.should == model.start_date
    item.end_date.should == model.end_date
    item.plan_name.should == model.plan_name
    item.phase_name.should == model.phase_name
    item.usage_name.should == model.usage_name
    item.linked_item_id.should == model.id

    item.id.should_not == model.id
    item.amount.should == amount
    item.description.should == description
    item.invoice_item_type.should == type
    item.rate.should be_nil
  end
end
