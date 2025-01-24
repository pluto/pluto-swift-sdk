Pod::Spec.new do |s|
  s.name             = "PlutoSwiftSDK"
  s.version          = "0.1.0"
  s.summary          = "A Swift SDK for generating zero-knowledge proofs with Pluto"
  s.description      = <<-DESC
    A Swift SDK that provides functionality generating zero-knowledge proofs.
  DESC

  s.homepage         = "https://pluto.xyz/"
  s.license          = { :type => "Apache License 2.0", :file => "LICENSE" }
  s.author           = { "Pluto" => "support@pluto.xyz" }
  s.source           = { :git => "https://github.com/pluto/pluto-swift-sdk.git", :tag => s.version.to_s }

  s.ios.deployment_target = "17.0"
  s.swift_versions = ["5.5"]

  # Swift files
  s.source_files       = "Sources/**/*.swift"

  s.vendored_frameworks = "PlutoProver.xcframework"

  # Exclude x86_64 for the simulator
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 x86_64'
  }

  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 x86_64'
  }

  s.xcconfig = {
    'OTHER_LDFLAGS' => '-lc++'
  }

end
