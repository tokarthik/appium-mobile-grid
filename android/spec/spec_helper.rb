require_relative "#{ENV["BASE_DIR"]}/common/methods"

ENV["UDID"] = assign_udid_from_thread

RSpec.configure do |config|
  config.color = true
  config.tty = true
  
  config.before :all do
    caps = Appium.load_appium_txt file: File.join(File.dirname(__FILE__), '../appium.txt')
    caps[:caps][:udid] = ENV["UDID"]
    caps[:caps][:app] = ENV["APP_PATH"]
    caps[:appium_lib][:server_url] = ENV["SERVER_URL"]
    caps[:caps][:name] = self.class.metadata[:full_description]

    @driver = Appium::Driver.new(caps).start_driver
    Appium.promote_appium_methods Object
    Appium.promote_appium_methods RSpec::Core::ExampleGroup
    require_relative '../adb_helpers'
    Appium.promote_singleton_appium_methods Adb
  end
  
  config.before :each do
    adb.start_logcat ENV["UDID"], "#{ENV["UDID"]}-#{thread}" 
    adb.start_video_record ENV["UDID"], "#{ENV["UDID"]}-#{thread}" 
  end
    
  config.after :each do |e|
    adb.stop_logcat
    adb.stop_video_record ENV["UDID"], "#{ENV["UDID"]}-#{thread}"
    update_sauce_status @driver.session_id, e.exception.nil?     
    unless e.exception.nil?
      e.attach_file("Hub Log: #{ENV["UDID"]}", File.new("#{ENV["BASE_DIR"]}/output/android-hub.log")) unless ENV["THREADS"].nil?
      @driver.screenshot "#{ENV["BASE_DIR"]}/output/screenshot-#{ENV["UDID"]}.png"
      files = (`ls #{ENV["BASE_DIR"]}/output/*#{ENV["UDID"]}*`).split("\n").map { |file| { name: file.match(/output\/(.*)-/)[1], file: file } }
      files.each { |file| e.attach_file(file[:name], File.new(file[:file])) } unless files.empty?
    end
  end
  
  config.after :all do
    @driver.driver_quit
  end
end

allure_setup