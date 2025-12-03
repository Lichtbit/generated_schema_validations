# frozen_string_literal: true

namespace :generated_schema_validations do
  desc 'compare remove dump with local variant'
  task :compare_dumper do
    on roles(:app) do
      begin
        require 'diff/lcs'
        require 'diff/lcs/hunk'
        diff_lcs_available = true
      rescue LoadError
        diff_lcs_available = false
      end

      local_file = 'app/models/concerns/schema_validations.rb'
      local_content = File.read(local_file)

      within release_path do
        with(
          rails_env: fetch(:rails_env),
          rails_groups: fetch(:rails_assets_groups),
          disable_database_environment_check: 1
        ) do
          dump_output = capture :rake, 'db:validation_dump_direct'

          if dump_output != local_content
            warn '❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌'
            warn 'The online version of the automatically generated validations differs from the local version.'
            warn 'Please check immediately.'

            if diff_lcs_available
              old_lines = local_content.lines
              new_lines = dump_output.lines
              diffs = Diff::LCS.diff(old_lines, new_lines)

              if diffs.any?
                info '----- DIFF START -----'

                file_length_difference = 0

                diffs.each do |piece|
                  hunk = Diff::LCS::Hunk.new(
                    old_lines, new_lines, piece,
                    3,  # context lines
                    file_length_difference
                  )

                  file_length_difference = hunk.file_length_difference

                  info hunk.diff(:unified)
                end

                info '----- DIFF END -----'
              end
            end
            warn '❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌'
          else
            info '✔ Schema OK'
          end
        end
      end
    end
  end
end

after 'deploy:publishing', 'generated_schema_validations:compare_dumper'
