:<%= identifier %>:
  :test: true
  :log_file: /var/tmp/<%= identifier %>.log

:database:
  :adapter: sqlite3
  :database: test.db
# For MySQL
#  :adapter: 'jdbc'
#  :username: 'killbill'
#  :password: 'killbill'
#  :driver: 'com.mysql.jdbc.Driver'
#  :url: 'jdbc:mysql://127.0.0.1:3306/killbill'
