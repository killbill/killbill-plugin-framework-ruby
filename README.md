killbill-plugin-framework-ruby
==============================

Framework to write Kill Bill plugins in Ruby.

There are various types of plugins one can write for Killbill:

* notifications plugins, which listen to external bus events and can react to it
* payment plugins, which issue payments against a payment gateway
* payment routing plugins, which modify the behavior of payments
* invoice plugins, which add line items during the creation of an invoice
* currency plugins, which return currency conversion information

All plugin types can interact with Kill Bill directly via APIs and expose HTTP endpoints.

Kill Bill compatibility
-----------------------

| OSS parent version | Kill Bill version |
| -----------------: | ----------------: |
| 7.x.y              | 0.16.z            |
| 8.3.y              | 0.18.z            |


How to write a Notification plugin
----------------------------------

```ruby
require 'killbill'

class MyNotificationPlugin < Killbill::Plugin::Notification
  # Overriding this method is optional, only if you need to do some initialization work
  def start_plugin
    puts "MyNotificationPlugin plugin starting"
    super
    puts "MyNotificationPlugin plugin started"
  end

  # Invoked each time an event is received
  def on_event(event)
    puts "Received Killbill event #{event}"
  end

  # Overriding this method is optional, only if you need to do some tear down work
  def stop_plugin
    puts "MyNotificationPlugin plugin stopping"
    super
    puts "MyNotificationPlugin plugin stopped"
  end
end
```

Make sure to create the corresponding killbill.properties file:

```ini
mainClass=MyNotificationPlugin
pluginType=NOTIFICATION
```

How to write a Payment plugin
-----------------------------

```ruby
require 'killbill'

class MyPaymentPlugin < Killbill::Plugin::Payment
  def start_plugin
    puts "MyPaymentPlugin plugin starting"
    super
    puts "MyPaymentPlugin plugin started"
  end

  def authorize_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
  end

  def capture_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
  end

  def purchase_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
  end

  def void_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, properties, context)
  end

  def credit_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
  end

  def refund_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
  end

  def get_payment_info(kb_account_id, kb_payment_id, properties, context)
  end

  def search_payments(search_key, offset, limit, properties, context)
  end

  def add_payment_method(kb_account_id, kb_payment_method_id, payment_method_props, set_default, properties, context)
  end

  def delete_payment_method(kb_account_id, kb_payment_method_id, properties, context)
  end

  def get_payment_method_detail(kb_account_id, kb_payment_method_id, properties, context)
  end

  def set_default_payment_method(kb_account_id, kb_payment_method_id, properties, context)
  end

  def get_payment_methods(kb_account_id, refresh_from_gateway, properties, context)
  end

  def search_payment_methods(search_key, offset, limit, properties, context)
  end

  def reset_payment_methods(kb_account_id, payment_methods, properties, context)
  end

  def build_form_descriptor(kb_account_id, descriptor_fields, properties, context)
  end

  def process_notification(notification, properties, context)
  end

  # Overriding this method is optional, only if you need to do some tear down work
  def stop_plugin
    puts "MyPaymentPlugin plugin stopping"
    super
    puts "MyPaymentPlugin plugin stopped"
  end
end
```

Make sure to create the corresponding killbill.properties file:

```ini
mainClass=MyPaymentPlugin
pluginType=PAYMENT
```

How to write a Payment plugin integrated with ActiveMerchant
------------------------------------------------------------

Use the plugin generator:

```bash
./script/generate active_merchant gateway_name /path/to/dir
cd /path/to/dir
git init .
git add .
git commit -m 'Initial'
```

Replace `gateway_name` with the snake case of your ActiveMerchant gateway (e.g. `yandex`, `stripe`, `paypal`, etc.).

The newly generated plugin is in a git repository due to the way that the gemspec file resolves the files to include in the `killbill:package` rake task.  The above will add the generated files to a git repository, the handling of which is left to the reader.

This will generate a tree of files ready to be plugged into Kill Bill. To package the plugin, run:

```bash
rake killbill:clean ; rake build ; rake killbill:package
```

Most of the work consists of filling in the blank in `api.rb` (payment plugin API for ActiveMerchant gateways) and `application.rb` (sinatra application for ActiveMerchant integrations). Check the [Stripe plugin](https://github.com/killbill/killbill-stripe-plugin) for an example.

In case the templates behind the generator change and you want to upgrade your plugin, you can re-run the above
generate command on top of your existing code. For each file, you'll be prompted whether you want to overwrite it, show a
diff, etc.

How to write an Invoice plugin
------------------------------

See the [killbill-invoice-test-plugin](https://github.com/killbill/killbill-invoice-test-plugin).

How to write a Currency plugin
------------------------------

See the [killbill-currency-plugin](https://github.com/killbill/killbill-currency-plugin).

How to expose HTTP endpoints
----------------------------

Killbill exports a Rack handler that interfaces directly with the container in which killbill-server runs (e.g. Jetty).

This basically means that Killbill will understand native Rack config.ru files placed in the root of your plugin, e.g. (using Sinatra):

```ruby
require 'sinatra'

get "/plugins/myPlugin/ping" do
  status 200
  "pong"
end
run Sinatra::Application
```

Rake tasks
----------

The killbill gem also ships helpful Rake tasks to package Killbill-ready plugins.

To access these tasks, add the following to your Rakefile:

```ruby
# Install tasks to package the plugin for Killbill
require 'killbill/rake_task'
Killbill::PluginHelper.install_tasks

# (Optional) Install tasks to build and release your plugin gem
require 'bundler/setup'
Bundler::GemHelper.install_tasks
```

You can verify these tasks are available by running `rake -T`.

To build the artifacts into pkg/:

```bash
# Cleanup output directories
rake killbill:clean
# Build your plugin gem in the pkg/ directory
rake build
# Build the Killbill plugin in the pkg/ directory
# The <plugin_name>-<plugin-version>/ directory is used as a staging directory
rake killbill:package
```

For quick testing of your plugin, you can use the `deploy` task:

```bash
# Deploy the plugin in /var/tmp/bundles
rake killbill:deploy
# Deploy the plugin and clobber a previous version if needed
rake killbill:deploy[true]
# You can also specify a custom plugins directory as such
rake killbill:deploy[false,/path/to/bundles]
```

To debug packaging issues, pass `true` as the third (optional) parameter:

```bash
rake killbill:deploy[false,/path/to/bundles,true]
```

Development
-----------

To run unit and remote tests:

```bash
rake
rake test:remote:spec
```

To change the database driver:

```bash
AR_ADAPTER=mariadb AR_USERNAME=root AR_PASSWORD=root AR_DATABASE=kbtest rake
AR_ADAPTER=postgresql AR_DATABASE=kbtest rake
```
