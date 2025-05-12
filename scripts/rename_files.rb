#!/usr/bin/env ruby

# File renaming script
# Changes filenames from {order}-{title}.md to {title}.md or {title}-{han_number}.md

# Define kanji numbers for up to 20 files
KANJI_NUMBERS = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十",
                "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十"]

# Get all markdown files in content directory
files = Dir.glob("content/*.md")

# Group files by title
files_by_title = {}
files.each do |file|
  basename = File.basename(file)
  # Extract order and title from current filename pattern: "{order}-{title}.md"
  if basename =~ /^(\d+)-(.+)\.md$/
    order = $1.to_i
    title = $2
    files_by_title[title] ||= []
    files_by_title[title] << {original_path: file, order: order}
  else
    puts "Warning: File '#{basename}' doesn't match expected pattern"
  end
end

# Process each group to determine new filenames
rename_operations = []
files_by_title.each do |title, file_data|
  # Sort files by their original order
  file_data.sort_by! { |f| f[:order] }

  if file_data.size == 1
    # Single file case: just use the title
    old_path = file_data[0][:original_path]
    new_path = "content/#{title}.md"
    rename_operations << {old: old_path, new: new_path}
  else
    # Multiple files case: use title with kanji number
    file_data.each_with_index do |file, index|
      old_path = file[:original_path]
      kanji_number = KANJI_NUMBERS[index]
      new_path = "content/#{title}-#{kanji_number}.md"
      rename_operations << {old: old_path, new: new_path}
    end
  end
end

# Execute the rename operations
puts "The following files will be renamed:"
rename_operations.each do |op|
  puts "#{File.basename(op[:old])} → #{File.basename(op[:new])}"
end

puts "\nTotal files to rename: #{rename_operations.size}"
puts "Proceeding with renaming..."

rename_operations.each do |op|
  File.rename(op[:old], op[:new])
  puts "Renamed: #{File.basename(op[:old])} → #{File.basename(op[:new])}"
end
puts "Rename operation completed successfully."
