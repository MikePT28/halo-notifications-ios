Pod::Spec.new do |spec|
  spec.name             = 'HaloNotificationsSDK'
  spec.module_name      = 'HaloNotifications'
  spec.version          = '2.3.2'
  spec.summary          = 'HALO Notifications iOS SDK'
  spec.homepage         = 'https://mobgen.github.io/halo-documentation/ios_home.html'
  spec.license          = 'Apache License, Version 2.0'
  spec.author           = { 'Borja Santos-Diez' => 'borja.santos@mobgen.com' }
  spec.source           = { :http => 'https://github.com/mobgen/halo-notifications-ios/archive/2.3.2.zip' }

  spec.platforms        = { :ios => '8.0' }
  spec.requires_arc     = true
  spec.ios.framework    = 'UserNotifications'
  spec.ios.vendored_frameworks = 'halo-notifications-ios-2.3.2/Frameworks/Firebase/**/*.framework'
  spec.ios.vendored_libraries = 

  spec.source_files     = 'halo-notifications-ios-2.3.2/Source/**/*.swift'
  spec.resources        = ['halo-notifications-ios-2.3.2/Sounds/*'] 

  spec.dependency 'HaloSDK'

end