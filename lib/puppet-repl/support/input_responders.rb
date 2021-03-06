module PuppetRepl
  module Support
    module InputResponders

      def static_responder_list
        ["exit", "functions", "classification","vars", 'facterdb_filter', "krt", "facts",
         "resources", "classes", "play","reset", "help"
        ]
      end

      def facterdb_filter(args=[])
        dynamic_facterdb_filter.ai
      end

      def help(args=[])
        PuppetRepl::Cli.print_repl_desc
      end

      def handle_set(input)
        output = ''
        args = input.split(' ')
        args.shift # throw away the set
        case args.shift
        when /node/
          if name = args.shift
            output = "Resetting to use node #{name}"
            reset
            set_remote_node_name(name)
          else
            out_buffer.puts "Must supply a valid node name"
          end
        when /loglevel/
          if level = args.shift
            @log_level = level
            set_log_level(level)
            output = "loglevel #{Puppet::Util::Log.level} is set"
          end
        end
        output
      end

      def facts(args=[])
        variables = node.facts.values
        variables.ai({:sort_keys => true, :indent => -1})
      end

      def functions(args=[])
        filter = args.first || ''
        function_map.keys.sort.grep(/^#{Regexp.escape(filter)}/)
      end

      def vars(args=[])
        # remove duplicate variables that are also in the facts hash
        variables = scope.to_hash.delete_if {| key, value | node.facts.values.key?(key) }
        variables['facts'] = 'removed by the puppet-repl' if variables.key?('facts')
        output = "Facts were removed for easier viewing".ai + "\n"
        output += variables.ai({:sort_keys => true, :indent => -1})
      end

      def environment(args=[])
        "Puppet Environment: #{puppet_env_name}"
      end

      def reset(args=[])
        set_scope(nil)
        set_remote_node_name(nil)
        set_node(nil)
        set_facts(nil)
        set_environment(nil)
        set_log_level(log_level)
      end

      def set_log_level(level)
        Puppet::Util::Log.level = level.to_sym
        buffer_log = Puppet::Util::Log.newdestination(:buffer)
        if buffer_log
          # if this is already set the buffer_log is nil
          buffer_log.out_buffer = out_buffer
          buffer_log.err_buffer = out_buffer
        end
        nil
      end

      def krt(args=[])
        known_resource_types.ai({:sort_keys => true, :indent => -1})
      end

      def play(args=[])
        config = {}
        config[:play] = args.first
        play_back(config)
        return nil  # we don't want to return anything
      end

      def classification(args=[])
        node.classes.ai
      end

      def resources(args=[])
        res = scope.compiler.catalog.resources.map do |res|
          res.to_s.gsub(/\[/, "['").gsub(/\]/, "']") # ensure the title has quotes
        end
        if !args.first.nil?
          res[args.first.to_i].ai
        else
          output = "Resources not shown in any specific order\n".warning
          output += res.ai
        end
      end

      def classes(args=[])
        scope.compiler.catalog.classes.ai
      end

    end
  end
end
