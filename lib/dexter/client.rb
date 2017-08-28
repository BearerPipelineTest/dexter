module Dexter
  class Client
    attr_reader :arguments, :options

    def initialize(args)
      @arguments, @options = parse_args(args)
    end

    def perform
      STDOUT.sync = true
      STDERR.sync = true

      if options[:statement]
        query = Query.new(options[:statement])
        Indexer.new(options).process_queries([query])
      elsif options[:pg_stat_statements]
        Indexer.new(options).process_stat_statements
      elsif arguments.any?
        ARGV.replace(arguments)
        Processor.new(ARGF, options).perform
      else
        Processor.new(STDIN, options).perform
      end
    end

    def parse_args(args)
      opts = Slop.parse(args) do |o|
        o.banner = %(Usage:
    dexter [options]

Options:)
        o.boolean "--create", "create indexes", default: false
        o.array "--exclude", "prevent specific tables from being indexed"
        o.string "--include", "only include specific tables"
        o.integer "--interval", "time to wait between processing queries, in seconds", default: 60
        o.float "--min-time", "only process queries that have consumed a certain amount of DB time, in minutes", default: 0
        o.boolean "--pg-stat-statements", "use pg_stat_statements", default: false, help: false
        o.boolean "--log-explain", "log explain", default: false, help: false
        o.string "--log-level", "log level", default: "info"
        o.boolean "--log-sql", "log sql", default: false
        o.string "-s", "--statement", "process a single statement"
        o.separator ""
        o.separator "Connection options:"
        o.on "-v", "--version", "print the version" do
          log Dexter::VERSION
          exit
        end
        o.on "--help", "prints help" do
          log o
          exit
        end
        o.string "-U", "--username"
        o.string "-d", "--dbname"
        o.string "-h", "--host"
        o.integer "-p", "--port"
      end

      arguments = opts.arguments
      options = opts.to_hash

      options[:dbname] = arguments.shift unless options[:dbname]

      abort "Unknown log level" unless ["info", "debug", "debug2"].include?(options[:log_level].to_s.downcase)

      [arguments, options]
    rescue Slop::Error => e
      abort e.message
    end

    def log(message)
      $stderr.puts message
    end
  end
end
