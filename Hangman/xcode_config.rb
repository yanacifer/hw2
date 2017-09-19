#!/usr/bin/env ruby

require 'xcodeproj'
require 'find'

module Autograder

	# Shared instance of the xcodeproj object.
	@@project = nil
	# Main target of the project, usually the name of the project. This is also the target that will be tested.
	@@main_target = nil
	# Array of the .csv paths found within the Autograder directory.
	@@csv_paths = []
	# Whether to log output.
	@@debug = nil


	# Locates the .xcodeproj and .csv files. Aborts if cannot locate the .xcodeproj or a .swift/.csv test suite file pair.
	def self.locate_files
		project_path = nil
		Find.find('.') do |path|
			case path
				when /.*\/tmp.*/
					next
				when /.*\.csv$/
					@@csv_paths << Pathname.new(path)
					swift_path = path.sub('.csv', '.swift')
					unless Pathname.new(swift_path).exist?
						fatal_error("Missing swift test suite: #{swift_path}")
					end
				when /.*\.xcodeproj$/
					project_path = path
			end
		end

		fatal_error_if_nil(project_path, "Could not locate .xcodeproj within #{Dir.pwd}")

		return project_path
	end

	private_class_method :locate_files


	# Loads/initializes xcodeproj object and the main target. Assumes the project will have at most 2 targets: a main
	# target and the Autograder target. Also, finds relevant file paths. Aborts if cannot locate the .xcodeproj or a
	# .swift/.csv test suite file pair.
	def self.load_project
		@@project = Xcodeproj::Project.open(locate_files())
		@@main_target = @@project.native_targets.find {|target|
			target.display_name != 'Autograder'
		}
		log "Main target: #{@@main_target.pretty_print}"
	end


	# Saves the project. Must call before script termination, otherwise modifications will not persist.
	def self.save_project
		@@project.save
	end


	# Terminates execution. Writes error_message to STDERR.
	def self.fatal_error(error_message)
		if error_message.nil?
			abort('An unknown error occurred.')
		else
			abort(error_message)
		end
	end


	# Terminates execution and writes error_message to STDERR iff object is nil.
	def self.fatal_error_if_nil(object, error_message)
		fatal_error(error_message) if object.nil?
	end


	# Puts to STDOUT if '-debug' CL argument was given, otherwise does nothing.
	def self.log(obj='', *arg)
		puts(obj, arg) if @@debug || @@debug.nil?
	end


	# Parses the CL arguments. Currently supports '-storyboard', '-no-storyboard' and '-debug'. Requires a 'storyboard'
	# argument, aborts otherwise.
	def self.parse_arguments
		using_storyboard = nil
		ARGV.each do |arg|
			case arg
				when '-storyboard'
					using_storyboard = true
				when '-no-storyboard'
					using_storyboard = false
				when '-debug'
					@@debug = true
				else
					fatal_error("Invalid argument '#{arg}' given.")
			end
		end

		fatal_error_if_nil(using_storyboard, 'Invalid arguments given.')

		@@debug = false if @@debug.nil?

		return using_storyboard
	end


	# Adds a file located at file_path to the group and the target_build_phase.
	def self.add_file(file_path, target_build_phase, group)
		unless (file_ref = group.files.find {|file_reference|
			file_reference.path == file_path
		})
			log "Adding #{file_path} to group #{group.display_name}..."
			file_ref = group.new_file(file_path)
		end
		target_build_phase.add_file_reference(file_ref, true)
	end


	# Verifies/creates Autograder target and product, adds the main target as an dependency, and configures the build
	# settings.
	def self.create_autograder_target
		# Create target.
		unless (test_target = @@project.targets.find {|target|
			target.name == 'Autograder'
		})
			log 'Creating Autograder target...'
			test_target = @@project.new(Xcodeproj::Project::PBXNativeTarget)
			@@project.targets << test_target
			test_target.name = 'Autograder'
			test_target.product_name = 'Autograder'
			test_target.product_type = 'com.apple.product-type.bundle.unit-test'
			test_target.build_configuration_list = Xcodeproj::Project::ProjectHelper.configuration_list(@@project, :ios,
																																																	nil, :unit_test_bundle,
																																																	:swift)
		end

		# Create product.
		unless @@project.products_group.files.find {|file_ref|
			file_ref.display_name.downcase == 'autograder.xctest'
		}
			log 'Creating Autograder.xctest product...'
			product_ref = @@project.products_group.new_product_ref_for_target('Autograder', :unit_test_bundle)
			test_target.product_reference = product_ref
		end

		# Add target dependency.
		test_target.add_dependency(@@main_target)

		# Special build settings.
		bundle_loader = "$(BUILT_PRODUCTS_DIR)/#{@@main_target.name}.app/#{@@main_target.name}".sub("\n", '') # Sometimes
		# a newline gets in there. Weird...
		test_target.build_configuration_list.set_setting('BUNDLE_LOADER', bundle_loader)
		test_target.build_configuration_list.set_setting('SWIFT_VERSION', '4.0')
		test_target.build_configuration_list.set_setting('TEST_HOST', '$(BUNDLE_LOADER)')
		test_target.build_configuration_list.build_configurations.each do |bc|
			bc.build_settings['FRAMEWORK_SEARCH_PATHS'] = %w[$(inherited) $(PROJECT_DIR)/Autograder/Frameworks]
		end

		test_target
	end


	# Adds the Autograder.xcconfig to the Autograder group and sets it as the Autograder target's 'Debug' configuration.
	def self.add_configuration(autograder_group, autograder_target)
		unless (ref = autograder_group.find_file_by_path('Autograder.xcconfig'))
			log 'Adding Autograder.xcconfig to target...'
			ref = autograder_group.new_file('Autograder.xcconfig')
		end
		autograder_target.build_configuration_list['Debug'].base_configuration_reference = ref
	end


	# Slight modification (error suppression).
	# https://github.com/CocoaPods/Xcodeproj/blob/84ebf064499756da50101ee273ef3e053bdccd17/lib/xcodeproj/scheme.rb#L227
	def self.share_scheme(project_path, scheme_name)
		to_folder = Xcodeproj::XCScheme.shared_data_dir(project_path)
		to_folder.mkpath
		to = to_folder + "#{scheme_name}.xcscheme"
		from = Xcodeproj::XCScheme.user_data_dir(project_path, "shawndsouza") + "#{scheme_name}.xcscheme"
		FileUtils.mv from, to, :force => true # <—— Here
		to
	end


	# Shares and modifies the project's main target's scheme to accommodate the Autograder test target.
	def self.configure_scheme(autograder_target)
		# Share the main scheme, if it's not already.
		shared_scheme_path = Autograder.share_scheme(@@project.path, @@main_target.name)
		# Create a scheme object
		shared_scheme = Xcodeproj::XCScheme.new(shared_scheme_path)

		# Skip other test targets
		shared_scheme.test_action.testables.each do |testable|
			if testable.buildable_references.first.target_name != 'Autograder'
				testable.skipped = true
			end
		end

		# Check if the autograder target is in the scheme's build action.
		unless shared_scheme.build_action.entries.find {|entry|
			entry.buildable_references.first.target_name == autograder_target.name
		}
			# Add it if it isn't
			log "Adding Autograder target to the #{@@main_target.name} scheme's build action."
			build_entry = Xcodeproj::XCScheme::BuildAction::Entry.new(autograder_target)
			build_entry.build_for_analyzing = false
			shared_scheme.build_action.add_entry(build_entry)
		end

		# What about the scheme's test action?
		unless shared_scheme.test_action.testables.find {|testable|
			testable.buildable_references.first.target_name == autograder_target.name
		}
			# Add it if it isn't
			log "Adding Autograder target to the #{@@main_target.name} scheme's test action."
			shared_scheme.test_action.add_testable Xcodeproj::XCScheme::TestAction::TestableReference.new(autograder_target)
		end

		# Save the modified scheme back to the .xcscheme file.
		shared_scheme.save!
	end


	# Finds/creates the Autograder group. Creates the ./Autograder/ directory, if nonexistent.
	def self.create_autograder_group
		if (autograder_group = @@project.main_group['Autograder'])
			return autograder_group
		end

		log 'Creating Autograder group...'
		group_path = Pathname.new("#{@@project.main_group.real_path}/Autograder")
		unless group_path.directory?
			log '	Creating Autograder directory...'
			group_path.mkpath
		end
		@@project.main_group.new_group('Autograder', 'Autograder', :group)
	end


	# Adds the .swift and .csv files in the Autograder directory to the Autograder group and target. Aborts if the
	# directory structure is invalid.
	def self.configure_test_suites(autograder_group, autograder_target)
		@@csv_paths.each do |csv|
			components = csv.each_filename.to_a

			unless components.size == 4
				fatal_error("#{csv} in invalid location. Should follow the format: ./Autograder/*test suite name*/*test suite name*TestSuite.csv")
			end

			test_suite_name = components[2]
			csv_filename = components[3]
			swift_filename = csv_filename.sub('.csv', '.swift')

			# Ensure it's located in the Autograder directory
			if components[0] == '.' && components[1] == 'Autograder'
				if (group = autograder_group[test_suite_name])
					Autograder.add_file(csv_filename, autograder_target.resources_build_phase, group)
					Autograder.add_file(swift_filename, autograder_target.source_build_phase, group)
				else
					log "Creating #{test_suite_name} group and adding #{csv_filename}"
					group = autograder_group.new_group(test_suite_name, test_suite_name)
					Autograder.add_file(csv_filename, autograder_target.resources_build_phase, group)
					Autograder.add_file(swift_filename, autograder_target.source_build_phase, group)
				end
			else
				fatal_error("#{csv_filename} in invalid location. Should be in #{Dir.pwd}/Autograder/#{test_suite_name}/#{csv_filename}")
			end
		end
	end


	# Adds Main.storyboard to the Autograder target. Enables the Autograder to parse the storyboard XML for various info.
	def self.add_storyboard(autograder_target)
		unless (storyboard_copy_phase = autograder_target.copy_files_build_phases.find {|phase|
			phase.name.downcase == 'copy storyboard'
		})
			log '	Creating copy storyboard build phase...'
			storyboard_copy_phase = autograder_target.new_copy_files_build_phase('Copy Storyboard')
			storyboard_copy_phase.dst_path = '..'
			storyboard_copy_phase.dst_subfolder_spec = '7' # Resources
		end

		unless (ref = @@main_target.resources_build_phase.files_references.find {|file_ref|
			file_ref.display_name == 'Main.storyboard'
		})
			fatal_error("Could not find Main.storyboard in the #{@@main_target.name} group.")
		end

		storyboard_copy_phase.add_file_reference(ref, true)
	end


	# Adds the BKAutograder.framework to the project's 'Frameworks' group, and the Autograder target's 'frameworks' and
	# 'Copy Files' build phases.
	def self.add_frameworks(autograder_target)
		group = @@project.frameworks_group
		path = 'Autograder/Frameworks/BKAutograder.framework'

		unless (ref = group.find_file_by_path(path))
			log 'Adding BKAutograder.framework to frameworks group...'
			ref = group.new_file(path)
		end

		unless (copy_phase = autograder_target.copy_files_build_phases.find {|phase|
			phase.name.downcase == 'copy autograder'
		})
			log 'Creating copy autograder build phase...'
			copy_phase = autograder_target.new_copy_files_build_phase('Copy Autograder')
			copy_phase.dst_subfolder_spec = '10' # Frameworks
		end

		copy_phase.add_file_reference(ref, true)
		autograder_target.frameworks_build_phase.add_file_reference(ref, true)
	end

	def self.copy_file(from_source, to_destination)
		FileUtils.copy_entry from_source, to_destination, :force => true
	end

end


# Parses the CL arguments.
using_storyboard = Autograder.parse_arguments

# Open and load the xcode project.
Autograder.load_project

# Find/create the Autograder target.
autograder_target = Autograder.create_autograder_target

# Find/create the Autograder root folder in the Xcode Project.
autograder_group = Autograder.create_autograder_group

# Add Autograder.xcconfig
Autograder.add_configuration(autograder_group, autograder_target)

# Add test suites (.swift and .csv) to Autograder group.
Autograder.configure_test_suites(autograder_group, autograder_target)

# Check/set shared scheme's configurations.
Autograder.configure_scheme(autograder_target)

# Add Main.storyboard to copy files build phase.
Autograder.add_storyboard(autograder_target) if using_storyboard

# Add BKAutograder.framework.
Autograder.add_frameworks(autograder_target)

Autograder.save_project