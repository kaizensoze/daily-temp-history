
city_filenames = {}

# map filename to city
File.open('cities.txt', 'r').each_line.with_index do |line, lineno|
  next if lineno <= 1

  tokens = line.split(/\s\s+/)
  filename = tokens[1]
  city = tokens[0]
  # puts "#{filename} #{city}"
  city_filenames[filename] = city
end

# load data files
Dir.foreach('data') do |filename|
  next if filename == '.' || filename == '..'
  next if File.extname(filename) != '.txt'

  file_basename = File.basename(filename, '.txt')

  File.open("data/#{filename}").each_line do |line|
    tokens = line.split()
    month = tokens[0]
    day = tokens[1]
    year = tokens[2]
    temp = tokens[3]
    city = city_filenames[file_basename]
    p "#{city} #{file_basename} #{month} #{day} #{year} #{temp}"

    # TODO: insert into mongodb
  end
end
