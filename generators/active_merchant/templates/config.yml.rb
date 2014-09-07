:<%= identifier %>:
  :test: true
  :log_file: /var/tmp/<%= identifier %>.log

:database:
  :adapter: sqlite3
  :database: test.db
# For MySQL
#  :adapter: 'jdbcmysql'
#  :username: 'killbill'
#  :password: 'killbill'
#  :driver: 'com.mysql.jdbc.Driver'
#  :url: 'jdbc:mysql://127.0.0.1:3306/killbill'
# In Kill Bill
#  :adapter: 'jdbcmysql'
#  :jndi: 'killbill/osgi/jdbc'
#  :driver: 'com.mysql.jdbc.Driver'
#  :connection_alive_sql: 'select 1'
#  :pool: 250
