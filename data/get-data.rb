
require 'date'
require 'fileutils'
require 'json'
require 'json/add/core'
require 'mongo'
require 'net/http'
require 'zip/zip'
include Mongo

# daily temp data path
DATA_DIRNAME = 'data-files'

# weather station struct
WeatherStation = Struct.new(:name, :province, :country, :id, :lat, :long, :wmo)


def download_latest_temp_data
  # switch to dir of running script so we're not responsible for deleting some *other* temp-data folder
  Dir.chdir(File.dirname(__FILE__))

  # create data folder if it doesn't exist
  Dir.mkdir 'data'
  
  # download the zip file
  puts "Downloading latest daily temp data..."
  Net::HTTP.start("academic.udayton.edu") do |http|
    resp = http.get("/kissock/http/Weather/gsod95-current/allsites.zip")
    open("#{DATA_DIRNAME}/allsites.zip", "w") do |file|
      file.write(resp.body)
    end
  end

  # unzip the zip file into temp-data
  unzip_file("#{DATA_DIRNAME}/allsites.zip", "#{DATA_DIRNAME}")

  # remove unwanted files
  File.delete("#{DATA_DIRNAME}/ISTELAVIV.txt")
  File.delete("#{DATA_DIRNAME}/WS_FTP.LOG")

  # remove the zip file
  File.delete("#{DATA_DIRNAME}/allsites.zip")
end

def get_weather_stations
  weather_stations = {}

  File.open('stations.txt', 'r').each_line.with_index do |line, lineno|
    next if lineno <= 2

    name = line[0..25]
    province = line[26..27]
    country = line[29..30]
    id = line[33..36]
    lat = line[42..47]
    long = line[49..55]
    wmo = line[63..67]

    # puts "#{name} #{province} #{country} #{id} #{lat} #{long} #{wmo}"

    # remove any leading/trailing whitespace
    name.strip!
    province.strip!
    country.strip!
    id.strip!
    lat.strip!
    long.strip!
    wmo.strip!

    weather_stations[wmo] = WeatherStation.new(name, province, country, id, lat, long, wmo)
  end

  return weather_stations
end

def get_data_files
  data_files = {}

  File.open('files.txt', 'r').each_line.with_index do |line, lineno|
    next if lineno <= 1

    filename = line[25..32]
    wmo = line[58..62]

    # puts "#{filename} #{wmo}"

    filename.strip!
    wmo.strip!

    data_files[filename] = wmo
  end

  return data_files
end

def insert_data(weather_stations, data_files)
  # initialize mongodb collection
  db = Connection.new.db('test')
  daily_temps = db.collection('dailytemps')

  # drop the collection
  daily_temps.drop()

  # create mongodb indexes
  create_indexes(daily_temps)

  # iterate over each weather station data file
  Dir.foreach("#{DATA_DIRNAME}") do |filename|
    next if filename == '.' || filename == '..'
    next if File.extname(filename) != '.txt'

    file_basename = File.basename(filename, '.txt')

    # get weather station given the filename
    wmo = data_files[file_basename]
    weather_station = weather_stations[wmo]

    if weather_station.nil?
      puts "no weather station info found for #{wmo}. skipping."
      next
    end

    # begin
      insert_station_data_file(filename, weather_station, daily_temps)
    # rescue => e
    #   raise e
    # end
  end
end

def insert_station_data_file (filename, weather_station, daily_temps)
  File.open("#{DATA_DIRNAME}/#{filename}").each_line do |line|
    tokens = line.split()

    month = tokens[0].to_i
    day = tokens[1].to_i
    year = tokens[2].to_i
    temp = tokens[3].to_i

    if temp != -99
      puts "#{weather_station.country} #{weather_station.province} #{weather_station.name} #{year} #{month} #{day} #{temp}"

      # create record and insert into mongodb
      daily_temp = { :month => month, :day => day, :year => year, :temp => temp, :station => {
        :name => weather_station.name,
        :province => weather_station.province,
        :country => weather_station.country,
        :id => weather_station.id,
        :lat => weather_station.lat,
        :long => weather_station.long,
        :wmo => weather_station.wmo
      }}

      begin
        daily_temps.insert(daily_temp)
      rescue Mongo::OperationFailure => e
        if e.message =~ /E11000/
          puts e
        else
          raise e
        end
      end
    end
  end
end

def test_insert_station_data_file (weather_stations, data_files, filename)
  db = Connection.new.db('test')
  daily_temps = db.collection('dailytemps')

  # drop collection
  daily_temps.drop()

  # create mongodb indexes
  create_indexes(daily_temps)

  file_basename = File.basename(filename, '.txt')

  # get weather station given the filename
  wmo = data_files[file_basename]
  weather_station = weather_stations[wmo]

  insert_station_data_file(filename, weather_station, daily_temps)
end

def create_indexes (collection)
  collection.create_index({:date => Mongo::ASCENDING, :temp => Mongo::ASCENDING})
  collection.create_index({
    'year' => Mongo::ASCENDING,
    'month' => Mongo::ASCENDING,
    'day' => Mongo::ASCENDING,
    'station.wmo' => Mongo::ASCENDING}, :unique => true)
  collection.create_index('station')
  collection.create_index('station.name')
end

def unzip_file (file, destination)
  Zip::ZipFile.open(file) do |zip_file|
    zip_file.each do |f|
      f_path=File.join(destination, f.name)
      FileUtils.mkdir_p(File.dirname(f_path))
      zip_file.extract(f, f_path) unless File.exist?(f_path)
    end
  end
end

# download latest daily temp data
download_latest_temp_data

# get the list of weather stations, mapping WMO to the weather station struct
weather_stations = get_weather_stations

# get the list of data files, mapping filename to WMO
data_files = get_data_files

# insert the daily temp data into the database
insert_data(weather_stations, data_files)

# test_insert_station_data_file(weather_stations, data_files, "DLHAMBUR.txt")
