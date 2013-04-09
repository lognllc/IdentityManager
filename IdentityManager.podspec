Pod::Spec.new do |s|
  s.name     = 'IdentityManager'
  s.version  = '0.6'
  s.license  = 'MIT'
  s.summary  = 'IdentityManager maintains multiple accounts on each oauth platform, bundled with facebook, twitter, linkedin support. But you can register as many OAuth 1.0a services as you can.'
  s.homepage = 'https://github.com/lognllc/IdentityManager'
  s.author  = { 'Rex Sheng' => 'rex@lognllc.com' }
  s.source   = { :git => 'https://github.com/lognllc/IdentityManager.git', :tag => s.version.to_s }
  s.source_files = '*.{h,m}'
  s.requires_arc = true
  s.ios.deployment_target = '5.0'
end