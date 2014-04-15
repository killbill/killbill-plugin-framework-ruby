:<%= identifier %>:
  :test: true
  :log_file: /var/tmp/<%= identifier %>.log

:database:
  :adapter: sqlite3
  :database: test.db
# For MySQL
#  :adapter: 'jdbc'
#  :username: 'your-username'
#  :password: 'your-password'
#  :driver: 'com.mysql.jdbc.Driver'
#  :url: 'jdbc:mysql://127.0.0.1:3306/your-database'
