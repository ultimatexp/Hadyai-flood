require 'xcodeproj'

project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the Runner group
group = project.main_group.find_sub_group('Runner')
if group.nil?
  puts "Runner group not found"
  exit 1
end

# Check if file is already added
file_ref = group.files.find { |file| file.path == 'GoogleService-Info.plist' }
if file_ref
  puts "GoogleService-Info.plist already exists in project"
  exit 0
end

# Add file to group
file_ref = group.new_reference('GoogleService-Info.plist')
puts "Added GoogleService-Info.plist to Runner group"

# Add file to Resources build phase of Runner target
target = project.targets.find { |t| t.name == 'Runner' }
if target
  resources_phase = target.resources_build_phase
  resources_phase.add_file_reference(file_ref)
  puts "Added to Resources build phase"
else
  puts "Runner target not found"
  exit 1
end

project.save
puts "Project saved"
