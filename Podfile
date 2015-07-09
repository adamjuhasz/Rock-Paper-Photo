source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.0'

def import_pods
  pod 'NYXImagesKit', '2.3'
  pod 'ParseFacebookUtilsV4'
  pod 'ParseUI', :path => '../ParseUI-iOS'

  pod 'FastttCamera'
  pod 'ReactiveCocoa','~> 2.5'
  pod 'ReactiveTableViewBinding'

  pod 'ClusterPrePermissions', :git => 'https://github.com/adamjuhasz/ClusterPrePermissions.git'
  pod 'AFDropdownNotification'
  pod 'jot',  :git => 'https://github.com/adamjuhasz/jot.git'
  pod 'NSURLConnection-Blocks'
  pod 'Colours', :git => 'https://github.com/adamjuhasz/Colours.git'
  pod 'Flow'
  pod 'FBSDKShareKit'
  pod 'JazzHands'
  pod 'UICKeyChainStore'
end

target 'PhotoPaperScissorsTests', :exclusive => true do
  import_pods
end

target 'PhotoPaperScissors', :exclusive => true do
  import_pods
  #pod 'Typhoon'
end
