gem 'rack'
require 'rack'
require 'rack/rewindable_input'

require 'singleton'

module Killbill
  module Plugin
    java_package 'org.killbill.billing.osgi.api.http'
    class RackHandler < Java::javax.servlet.http.HttpServlet
      include Singleton

      # A bit convoluted but the Rack API doesn't seem to let you
      # configure these things out of the command line
      class KillBillOptions < Rack::Server::Options
        def parse!(args)
          super.merge(default_options)
        end

        def default_options
          {
              # Make sure plugins are started in production mode by default
              :environment => :production
          }
        end
      end

      def configure(logger, config_ru)
        @logger = logger
        @app    = Rack::Builder.parse_file(config_ru, KillBillOptions.new).first
      end

      def unconfigure
        @app = nil
      end

      def configured?
        !@app.nil?
      end

      java_signature 'void service(HttpServletRequest, HttpServletResponse)'
      def service(servlet_request, servlet_response)
        input = Rack::RewindableInput.new(servlet_request.input_stream.to_io)
        scheme = servlet_request.scheme
        method = servlet_request.method
        request_uri = servlet_request.request_uri
        query_string = servlet_request.query_string
        server_name = servlet_request.server_name
        server_port = servlet_request.server_port
        content_type = servlet_request.content_type
        content_length = servlet_request.content_length

        headers = {}
        servlet_request.header_names.reject { |name| name =~ /^Content-(Type|Length)$/i }.each do |name|
          headers[name] = servlet_request.get_headers(name).to_a
        end

        # Pass original attributes (e.g. to get access to killbill_tenant)
        attributes = {}
        servlet_request.attribute_names.each do |name|
          value = servlet_request.get_attribute(name)
          attributes[name] = value
        end

        response_status, response_headers, response_body = rack_service(request_uri, method, query_string, input, scheme, server_name, server_port, content_type, content_length, headers, attributes)

        # Set status
        servlet_response.status = response_status

        # Set headers
        response_headers.each do |header_name, header_value|
          case header_name
            when /^Content-Type$/i
              servlet_response.content_type = header_value.to_s
            when /^Content-Length$/i
              servlet_response.content_length = header_value.to_i
            else
              servlet_response.add_header(header_name.to_s, header_value.to_s)
          end
        end

        # Write output
        response_stream = servlet_response.output_stream
        response_body.each { |part| response_stream.write(part.to_java_bytes) }
        response_stream.flush rescue nil
      ensure
        response_body.close if response_body.respond_to? :close
      end

      def rack_service(request_uri = '/', method = 'GET', query_string = '', input = '', scheme = 'http', server_name = 'localhost', server_port = 4567, content_type = 'text/plain', content_length = 0, headers = {}, attributes = {})
        return 503, {}, [] if @app.nil?

        rack_env = attributes.merge({
                'rack.version' => Rack::VERSION,
                'rack.multithread' => true,
                'rack.multiprocess' => false,
                'rack.input' => input,
                # Don't use java::lang::System::err.to_io here!
                # JRuby ChannelStream's finalize() may close it
                'rack.errors' => @logger,
                'rack.logger' => @logger,
                'rack.url_scheme' => scheme,
                'REQUEST_METHOD' => method,
                'SCRIPT_NAME' => '',
                'PATH_INFO' => request_uri,
                'QUERY_STRING' => (query_string || ""),
                'SERVER_NAME' => server_name,
                'SERVER_PORT' => server_port.to_s
        })

        rack_env['CONTENT_TYPE'] = content_type unless content_type.nil?
        rack_env['CONTENT_LENGTH']  = content_length unless content_length.nil?
        headers.each do |name, values|
          rack_env["HTTP_#{name.to_s.upcase.gsub(/-/,'_')}"] = values.join(',')
        end

        @app.call(rack_env)
      end
    end
  end
end

# Fix bug in JRuby's handling of gems in jars (JRUBY-3986)
class File
  def self.mtime(path)
    stat(path).mtime
  end
end
