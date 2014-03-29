Pod::Spec.new do |s|
  s.name         = "kvdb"
  s.version      = "0.0.8"
  s.summary      = "a key-value object store backed by SQLite3 for iOS."

  # s.description  = <<-DESC
  #                   An optional longer description of kvdb
  #
  #                   * Markdown format.
  #                   * Don't worry about the indent, we strip it!
  #                  DESC

  s.homepage     = "https://github.com/colinyoung/kvdb"

  # s.screenshots  = "www.example.com/screenshots_1", "www.example.com/screenshots_2"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.author       = { "Colin Young" => "me@colinyoung.com" }

  s.source       = { :git => "https://github.com/colinyoung/kvdb.git", :tag => s.version.to_s }

  s.platform     = :ios, '5.0'

  s.source_files = 'kvdb/**/*.{h,m}'

  s.public_header_files = 'kvdb/kbdv.h'

  s.library  = 'sqlite3.0'

  s.requires_arc = true
end
