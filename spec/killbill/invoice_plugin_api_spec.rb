require 'spec_helper'

describe Killbill::Plugin::Api::InvoicePluginApi do

  before(:all) do
    logger            = ::Logger.new(STDOUT)
    @invoicePluginApi = Killbill::Plugin::Api::InvoicePluginApi.new('Killbill::Plugin::InvoiceTest', {'logger' => logger, "root" => "/a/b/plugin_name/1.2.3"})
  end

  it 'should add items' do
    invoice = create_invoice

    items = @invoicePluginApi.get_additional_invoice_items(invoice, java.lang.Boolean::FALSE, java.util.ArrayList.new, nil)
    items.size.should == 2

    items.get(0).invoice_id.should == invoice.id
    items.get(0).amount.compareTo(java.math.BigDecimal.new('7')).should == 0
    items.get(0).invoice_item_type.should == org.killbill.billing.invoice.api.InvoiceItemType::TAX

    items.get(1).invoice_id.should == invoice.id
    items.get(1).amount.compareTo(java.math.BigDecimal.new('200')).should == 0
    items.get(1).invoice_item_type.should == org.killbill.billing.invoice.api.InvoiceItemType::EXTERNAL_CHARGE
  end

  private

  def create_invoice
    invoice_id = java.util.UUID.random_uuid

    invoice = org.mockito.Mockito.mock(org.killbill.billing.invoice.api.Invoice.java_class)
    org.mockito.Mockito.when(invoice.getId).thenReturn(invoice_id)

    item = org.mockito.Mockito.mock(org.killbill.billing.invoice.api.InvoiceItem.java_class)
    org.mockito.Mockito.when(item.getInvoiceId).thenReturn(invoice_id)
    org.mockito.Mockito.when(item.getAmount).thenReturn(java.math.BigDecimal.new('100'))

    items = java.util.ArrayList.new
    items.add(item)
    org.mockito.Mockito.when(invoice.getInvoiceItems).thenReturn(items)

    invoice
  end
end
