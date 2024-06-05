require 'find'

class Survey
  EXCLUDED_DIRECTORIES = %w[assets config images stylesheets channels application_cable views].freeze

  def initialize(rails_root = '.', logging = false)
    @directory = File.join(rails_root, 'app')
    @files_and_methods = {}
    @logging = logging
  end

  def list_files_and_methods
    puts "Starting survey in directory: #{@directory}" if @logging
    
    current_directory = nil

    Find.find(@directory) do |path|
      if File.directory?(path)
        new_directory = path.split('/').last.downcase
        if EXCLUDED_DIRECTORIES.include?(new_directory)
          Find.prune # Skip this directory and its subdirectories
        else
          if new_directory != current_directory
            current_directory = new_directory.capitalize
            puts "\nProcessing directory: #{current_directory}" if @logging
          end
        end
      elsif File.file?(path) && path.end_with?('.rb')
        file_name = File.basename(path)
        puts "File: #{file_name}" if @logging
        
        file_content = File.read(path)
        methods = file_content.scan(/def\s+([a-zA-Z0-9_]+)/).flatten
        class_name_match = file_content.match(/class\s+([A-Za-z0-9_:]+)/)
        class_name = class_name_match ? class_name_match[1] : "Unknown"

        if methods.any?
          puts "  Found methods: #{methods.join(', ')}" if @logging

          relative_path = path.sub(Dir.pwd + '/', '')
          @files_and_methods[relative_path] = { class_name: class_name, methods: methods }
        end
      end
    end
  end

  def print_files_and_methods
    current_directory = nil
    
    puts "\nSurvey results:"
    @files_and_methods.each do |file, info|
      directory = File.dirname(file).split('/').last.capitalize
      if directory != current_directory
        current_directory = directory
        puts "\n#{current_directory}"
      end
      puts "#{info[:class_name]} (File: #{File.basename(file)})"
      info[:methods].each do |method|
        puts "  - #{method}"
      end
      puts "" # Add a new line between each class
    end
  end

  def run
    list_files_and_methods
    print_files_and_methods
  end
end

# Script entry point
if __FILE__ == $PROGRAM_NAME
  rails_root = ARGV[0] || '.'
  logging = ARGV[1] == 'true' # Optional logging parameter, default to false
  survey = Survey.new(rails_root, logging)
  survey.run
end
