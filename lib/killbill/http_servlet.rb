require 'singleton'

module Killbill
  module Plugin
    java_package 'com.ning.billing.osgi.api.http'
    class RackHandler < Java::javax.servlet.http.HttpServlet
      include Singleton

      java_signature 'void service(HttpServletRequest, HttpServletResponse)'
      def service(req, res)
        puts "Received request: #{req.inspect} and response: #{res.inspect}"
        res.setStatus(200)
      end
    end
  end
end
