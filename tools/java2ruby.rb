require 'rubygems'
require 'optparse'


# Relative path from Killbill repo
API_DIR_SRC="api/src/main/java"


# Interfaces to consider
INTERFACES = ["AccountData",
              "AccountEmail",
              "ExtBusEvent",
              "Subscription",
              "SubscriptionBundle",
              "Invoice",
              "InvoiceItem",
              "InvoicePayment",
              #"Payment",
              "Refund",
              "AuditLog",
              "CallContext",
              "TenantContext",
              "CustomField",
              "Tag",
              "TagDefinition"]

class String
   def snake_case
     return downcase if match(/\A[A-Z]+\z/)
     gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
     gsub(/([a-z])([A-Z])/, '\1_\2').
     downcase
   end
end


class PoJo

  attr_accessor :name, :fields

  def initialize
    @name = nil
    @fields = []
  end

  def generate(out)
    out.write("\n")
    out.write("\#\n")
    out.write("\# Ruby classes automatically generated from java classes-- don't edit\n")
    out.write("\#\n")
    out.write("module Killbill\n")
    out.write("  module Plugin\n")
    out.write("    module Gen\n")
    out.write("\n")
    out.write("      class #{name}\n")
    out.write("\n")
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

  def export(output_dir)
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
    @pojo = PoJo.new
  end

  def add_name(interface)
    @pojo.name = interface
  end

  def add_getter(getter)
    @pojo.fields << getter.snake_case
  end
end

class Generator

  attr_reader :output_dir, :files

  def initialize(output_dir, files)
    @output_dir = output_dir
    @files = files
  end

  def generate_all
    gen_files = []
    @files.each do |i|
      puts "Starting processing file #{i}"
      generate_file(i) do |pojo|
        gen_files << pojo.name.snake_case
        pojo.export(@output_dir)
      end

      File.open("#{output_dir}/require_gen.rb", "w+") do |f|
        gen_files.each do |r|
          f.write("require \'killbill/gen/#{r}\'\n")
        end
      end
      puts "Completing processing file #{i}"
    end
  end

  def generate_file(file)
    visitor = Visitor.new
    File.open(file, "r") do |f|
      while (line = f.gets)

        re = /public\s+interface\s+(\w+)\s*/
        if re.match(line)
          visitor.add_name($1)
        end
        re = /(?:public){0,1}\s+(?:\w+)\s+get(\w+)()\s*/
        if re.match(line)
          visitor.add_getter($1)
        end
        re = /(?:public){0,1}\s+(?:\w+)\s+(is\w+)()\s*/
        if re.match(line)
          visitor.add_getter($1)
        end
      end
    end
    yield(visitor.pojo)
  end
end


class Finder

  attr_reader :interfaces, :src_dir

  def initialize(interfaces, src_dir)
    @interfaces = interfaces
    @src_dir = src_dir
  end

  def search
    res = []
    Dir.chdir(@src_dir)
    Dir.glob("**/*") do |e|
      if File.file?(e)
        basename = File.basename(e, ".java")
        if @interfaces.include? basename
          res << e
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
    finder = Finder.new(@interfaces, "#{@options[:src]}/#{@src_relative_path}")
    gen = Generator.new(@options[:output], finder.search)
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
