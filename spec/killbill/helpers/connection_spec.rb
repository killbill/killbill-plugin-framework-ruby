require 'spec_helper'

describe Killbill::Plugin::ActiveMerchant::Utils do

  it 'should close pool' do
    # Rails' pooling is really just a glorified mapping between threads and connections
    pool = ::ActiveRecord::Base.connection_pool

    # Verify the reaper is a no-op. Management is in our hands
    pool.reaper.frequency.should be_nil

    # Check-out a new connection or retrieve the one associated with the thread
    ::ActiveRecord::Base.connection.should_not be_nil
    pool.active_connection?.should be_true
    pool.connections.size.should == 1

    # Fetch the underlying connection object. This shouldn't create any new connection.
    # See activerecord-4.1.5/lib/active_record/connection_handling.rb, which proxies to
    # the connection_handler from activerecord-4.1.5/lib/active_record/connection_adapters/abstract/connection_pool.rb
    connection = ::ActiveRecord::Base.connection
    pool.connections.size.should == 1
    pool.connections[0].should == connection

    # connection is an ActiveRecord::ConnectionAdapters::AbstractAdapter object, specific to the driver.
    # For both straight JDBC and JNDI, it is an ActiveRecord::ConnectionAdapters::MysqlAdapter,
    # subclass of ActiveRecord::ConnectionAdapters::JdbcAdapter (activerecord-jdbc-adapter-1.3.9/lib/arjdbc/jdbc/adapter.rb).
    # The underlying connection is managed by ActiveRecord::ConnectionAdapters::JdbcConnection, which does the JDBC or JNDI lookup
    # and proxies to Java (https://github.com/jruby/activerecord-jdbc-adapter/blob/master/src/java/arjdbc/jdbc/RubyJdbcConnection.java).
    connection.active?.should be_true

    # Tell Rails not to re-use this connection. We don't want them to stick in Rails hand.
    # Instead, we want to force a checkout next time (put into c3p0's hands).
    pool.remove(connection)
    pool.active_connection?.should be_false
    pool.connections.size.should == 0

    # ActiveRecord connection management interface is defined in
    # activerecord-4.1.5/lib/active_record/connection_adapters/abstract_adapter.rb
    # Don't use ::ActiveRecord::Base.connection.close, which put the connection back into the pool.
    connection.disconnect!

    connection.active?.should be_false
  end
end
