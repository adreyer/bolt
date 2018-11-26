# frozen_string_literal: true

module Bolt
  # Represents a Task.
  # @file and @files are mutually exclusive.
  # @name [String] name of the task
  # @file [Hash, nil] containing `filename` and `file_content`
  # @files [Array<Hash>] where each entry includes `name` and `path`
  # @metadata [Hash] task metadata
  Task = Struct.new(
    :name,
    :file,
    :files,
    :metadata
  ) do

    def initialize(task)
      super(nil, nil, [], {})

      task.reject { |k, _| k == 'parameters' }.each { |k, v| self[k] = v }
    end

    def description
      metadata['description']
    end

    def parameters
      metadata['parameters']
    end

    def supports_noop
      metadata['supports_noop']
    end

    def module_name
      name.split('::').first
    end

    def remote?
      !!metadata['remote']
    end

    def tasks_dir
      File.join(module_name, 'tasks')
    end

    def file_map
      @file_map ||= files.each_with_object({}) { |file, hsh| hsh[file['name']] = file }
    end
    private :file_map

    # This provides a method we can override in subclasses if the 'path' needs
    # to be fetched or computed.
    def file_path(file_name)
      file_map[file_name]['path']
    end

    # Returns a hash of implementation name, path to executable, input method (if defined),
    # and any additional files (name and path)
    def select_implementation(target, additional_features = [])
      impl = if (impls = metadata['implementations'])
               available_features = target.features + additional_features
               impl = impls.find { |imp| Set.new(imp['requirements']).subset?(available_features) }
               raise "No suitable implementation of #{name} for #{target.name}" unless impl
               impl = impl.dup
               impl['path'] = file_path(impl['name'])
               impl.delete('requirements')
               impl
             else
               name = files.first['name']
               { 'name' => name, 'path' => file_path(name) }
             end

      inmethod = impl['input_method'] || metadata['input_method']
      impl['input_method'] = inmethod unless inmethod.nil?

      mfiles = impl.fetch('files', []) + metadata.fetch('files', [])
      dirnames, filenames = mfiles.partition { |file| file.end_with?('/') }
      impl['files'] = filenames.map do |file|
        path = file_path(file)
        raise "No file found for reference #{file}" if path.nil?
        { 'name' => file, 'path' => path }
      end

      unless dirnames.empty?
        files.each do |file|
          name = file['name']
          if dirnames.any? { |dirname| name.start_with?(dirname) }
            impl['files'] << { 'name' => name, 'path' => file_path(name) }
          end
        end
      end

      impl
    end
  end
end
