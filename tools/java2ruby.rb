require 'rubygems'
require 'optparse'


# Relative path from Killbill repo
API_DIR_SRC="api/src/main/java"

# Interfaces to consider
INTERFACES = ["Account",
              "AccountData",
              "AccountEmail",
              "BlockingState",
              "ExtBusEvent",
              "ExtBusEventType",
              "ObjectType",
              "Subscription",
              "SubscriptionState",
              "SubscriptionSourceType",
              "SubscriptionBundle",
              "Invoice",
              "InvoiceItem",
              "InvoicePayment",
              "InvoicePaymentType",
              "Payment",
              "PaymentAttempt",
              "Refund",
              "AuditLog",
              "CallContext",
              "CallOrigin",
              "UserType",
              "TenantContext",
              "CustomField",
              "Tag",
              "TagDefinition",
              "Currency",
              "PaymentInfoPlugin",
              "PaymentPluginStatus",
              "RefundInfoPlugin",
              "RefundPluginStatus",
              "PaymentMethodKVInfo",
              "PaymentMethodPlugin",
              "PaymentMethodInfoPlugin"]


class String
   def snake_case
     return downcase if match(/\A[A-Z]+\z/)
     gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
     gsub(/([a-z])([A-Z])/, '\1_\2').
     downcase
   end
end

class Pojo

  attr_accessor :name, :package,  :fields

  def initialize(dummy=nil)
     @name = nil
     @package = nil
     @fields = []
  end
end


class PojoEnum < Pojo

  def initialize
    super
  end

  def generate(out)
    out.write("\n")
    out.write("\#\n")
    out.write("\# Ruby classes automatically generated from java classes-- don't edit\n")
    out.write("\#\n")
    out.write("module Killbill\n")
    out.write("  module Plugin\n")
    out.write("    module Model\n")
    out.write("\n")
    out.write("      module #{name}\n")
    out.write("\n")
    fields.each_with_index do |f, i|
      out.write("        #{f} = #{i}\n")
    end
    out.write("      end\n")
    out.write("    end\n")
    out.write("  end\n")
    out.write("end\n")
    out.flush
  end

  def export(output_dir, parents_pojo)
    @fields.uniq!
    File.open("#{output_dir}/#{name.snake_case}.rb", "w+") do |f|
      generate(f)
    end
  end



end

class PojoIfceOrClass < Pojo

  attr_accessor :interface, :parents

  def initialize(is_interface)
    super
    @interface = is_interface
    @parents = []
  end

  def generate(out)
    out.write("\n")
    out.write("\#\n")
    out.write("\# Ruby classes automatically generated from java classes-- don't edit\n")
    out.write("\#\n")
    out.write("module Killbill\n")
    out.write("  module Plugin\n")
    out.write("    module Model\n")
    out.write("\n")
    out.write("      class #{name}\n")
    out.write("\n")
    if @interface
      out.write("        include #{@package}.#{@name}\n")
      out.write("\n")
    end
    out.write("        attr_reader #{fields.collect { |i| ":#{i}"}.join(", ")}\n")
    out.write("\n")
    out.write("        def initialize(#{@fields.join(", ")})\n")
    fields.each do |f|
      out.write("          @#{f} = #{f}\n")
    end
    out.write("        end\n")
    out.write("      end\n")
    out.write("    end\n")
    out.write("  end\n")
    out.write("end\n")
    out.flush
  end

  def export(output_dir, parents_pojo)
    parents.each do |p|
      if ! parents_pojo[p].nil?
        (@fields.unshift(parents_pojo[p].fields)).flatten!
      end
    end
    @fields.uniq!
    File.open("#{output_dir}/#{name.snake_case}.rb", "w+") do |f|
      generate(f)
    end
  end

  def to_s
    "#{@name} : #{@fields.join(",")}"
  end


end


class Visitor

  attr_reader :pojo

  def initialize
    @pojo = nil
  end

  def create_interface(name, package)
    @pojo = PojoIfceOrClass.new(true)
    @pojo.name = name
    @pojo.package = package
  end

  def create_class(name, package)
    @pojo = PojoIfceOrClass.new(false)
    @pojo.name = name
    @pojo.package = package
  end

  def create_enum(name, package)
    @pojo = PojoEnum.new
    @pojo.name = name
    @pojo.package = package
  end

  def add_parents(parents)
    (@pojo.parents << parents).flatten!
  end

  def add_getter(getter)
    @pojo.fields << getter.snake_case
  end

  def add_enum_field(enum_field)
    @pojo.fields << enum_field
  end
end

class Generator

  attr_reader :output_dir, :finder, :files

  def initialize(output_dir, interfaces, finder)
    @output_dir = output_dir
    @finder = finder
    @files = finder.search(interfaces)
  end

  def generate_all

    pojos = []
    @files.each do |i|
      generate_file(i) do |pojo|
        pojos << pojo
      end
    end

    parent_pojos = {}

    parent_ifces = []
    pojos.each do |pojo|
      if pojo.is_a? PojoIfceOrClass
        (parent_ifces << pojo.parents).flatten!
      end
    end
    parent_ifces.uniq!

    puts "UNIQ PARENTS = #{parent_ifces.to_s}"

    parent_files = finder.search(parent_ifces)
    puts "PARENT FILES  = #{parent_files}"
    parent_files.each do |i|
      puts "Starting processing parent file #{i}"
      generate_file(i) do |pojo|
        parent_pojos[pojo.name] = pojo
      end
    end

    pojos.each do |pojo|
      puts "Starting processing file #{pojo.name}"

      pojo.export(@output_dir, parent_pojos)

      File.open("#{output_dir}/require_gen.rb", "w+") do |f|
        pojos.each do |pojo|
          f.write("require \'killbill/gen/#{pojo.name.snake_case}\'\n")
        end
      end
      puts "Completing processing file #{pojo.name}"
    end
  end

  private


  def generate_file(file)
    visitor = Visitor.new
    File.open(file, "r") do |f|

      is_enum = false
      is_interface = false
      is_class = false
      package = nil
      while (line = f.gets)

        # Package
        re = /\s*package\s+((?:\w|\.)+)\s*;/
        if re.match(line)
          package = $1
        end

        # Interface
        re = /public\s+(interface|class)\s+(\w+)\s+(extends(?:\w|,|\s|<|>)+){0,1}\s*{\s*/
        if re.match(line)
          is_interface = ($1 == "interface")
          is_class = ($1 == "class")
          name = $2
          visitor.create_interface(name, package) if is_interface
          visitor.create_class(name, package) if is_class
          if ! $3.nil?
            re = /\s*extends\s+(.*)/
            extends_ifces = $3
            if re.match(extends_ifces)
              # extract each parent and remove trailing, leading space
              parents = $1.split(",").collect { |e| e.strip}
              # remove generics
              re = /(\w+)(?:<\w+>){0,1}/
              parents.collect! { |e| re.match(e); $1 }
              visitor.add_parents(parents)
            end
          end
        end

        # Enum
        re = /public\s+enum\s+(\w+)\s+/
        if re.match(line)
          enum_name = $1
          visitor.create_enum(enum_name, package)
          is_enum = true
          is_enum_complete = false
        end

        # Non static getters for interfaces
        re = /(?:public){0,1}\s+(?:static\s+(?:\w|<|>)+)\s+(?:get|is).*/
        if (is_interface || is_class) && !re.match(line)
          re = /(?:public){0,1}\s+(?:(?:\w|<|>)+)\s+get(\w+)()\s*/
          if re.match(line)
            visitor.add_getter($1)
          end
          re = /(?:public){0,1}\s+(?:(?:\w|<|>)+)\s+(is\w+)()\s*/
          if re.match(line)
            visitor.add_getter($1)
          end
        end

        # Enum fields
        re = /\s+((?:\w|_)+)(?:\((?:\w|\s|\")+\)){0,1}\s*(,|;){1}/
        if !is_enum_complete && is_enum && re.match(line)
          visitor.add_enum_field($1.strip)
          if $2 == ';'
            is_enum_complete = true
          end
        end
      end
    end
    yield(visitor.pojo)
  end
end


class Finder

  attr_reader :interfaces, :src_dir

  def initialize(src_dir)
    @interfaces = interfaces
    @src_dir = src_dir
  end

  def search(interfaces)
    res = []
    if !interfaces.nil? && interfaces.size > 0
      Dir.chdir(@src_dir)
      Dir.glob("**/*") do |e|
        if File.file?(e)
          basename = File.basename(e, ".java")
          if interfaces.include? basename
            res << e
          end
        end
      end
    end
    res
  end
end


class CommandParser

  attr_reader :options, :args, :interfaces, :src_relative_path

  def initialize(args, interfaces, src_relative_path)
    @options = {}
    @args = args
    @interfaces = interfaces
    @src_relative_path = src_relative_path
  end


  def run
    parse
    puts "Generating ruby classes under: #{@options[:output]}"
    finder = Finder.new("#{@options[:src]}/#{@src_relative_path}")
    gen = Generator.new(@options[:output], @interfaces, finder)
    gen.generate_all
  end

  private

  def parse()
    optparse = OptionParser.new do |opts|
      opts.banner = "Usage: java2ruby.rb [options]"

      opts.separator ""

      opts.on("-o", "--output OUTPUT",
      "Output directory") do |o|
        @options[:output] = o
      end

      opts.on("-s", "--src SRC",
      "Killbill source directory") do |s|
        @options[:src] = s
      end
    end
    optparse.parse!(@args)
  end

end

parser = CommandParser.new(ARGV, INTERFACES, API_DIR_SRC)
parser.run
