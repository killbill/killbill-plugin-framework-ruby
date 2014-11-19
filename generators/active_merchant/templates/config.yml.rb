:<%= identifier %>:
  :test: true

:database:
# SQLite (development)
  :adapter: sqlite3
  :database: test.db
# For MySQL
#  :adapter: mysql
#  :username: 'killbill'
#  :password: 'killbill'
#  :database: 'killbill' # or set the URL :
#  #:url: jdbc:mysql://127.0.0.1:3306/killbill
#  :pool: 100 # AR's default is 5
# In Kill Bill
#  :adapter: mysql
#  :jndi: 'killbill/osgi/jdbc'
#  :connection_alive_sql: 'select 1'
#  :pool: false # false-pool (JNDI pool's max)
#  # MySQL adapter #configure_connection defaults :
#  #    @@SESSION.sql_auto_is_null = 0,
#  #    @@SESSION.wait_timeout = 2147483,
#  #    @@SESSION.sql_mode = 'STRICT_ALL_TABLES'
#  # this can be disabled since AR-JDBC 1.4 using :
#  #:configure_connection: false
