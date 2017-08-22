
Pod::Spec.new do |s|

  s.name         = "CLSAlbum"
  s.version      = "0.0.1"
  s.summary      = "A short description of CLSAlbum."
  s.description  = <<-DESC
                    Cc
                   DESC

  s.homepage     = "https://github.com/ccloveswift/CLSAlbum"
  
  s.license      = { :type => 'Copyright', :text =>
        <<-LICENSE
        Copyright 2010-2015 CenterC Inc.
        LICENSE
    }
  
  s.author             = { "TT" => "654974034@qq.com" }
  
  s.source       = { :git => "https://github.com/ccloveswift/CLSAlbum.git", :tag => "#{s.version}" }

  s.requires_arc = true

  s.default_subspec     = 'Core'

  s.subspec 'Core' do |ss|
    ss.dependency       'CLSCommon/Core'
    ss.frameworks          = "Photos"
    ss.source_files        = "Classes/Core/**/*.{swift}"
  end


end
