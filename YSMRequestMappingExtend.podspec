#
# Be sure to run `pod lib lint YSMRequestMappingExtend.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "YSMRequestMappingExtend"
  s.version          = "0.1.0"
  s.summary          = "AFNetworking+Restkit:http request and mapping special object"
  s.description      = <<-DESC
                        1、AFNetworking;
                        2、Restikit/NKObjectMapping;
                        3、Using:
                            a、custom data model inherit YSMMappingBaseDataModel;
                            b、adding attributes like the sample:
                                NSString : YSMProperty_String(title);
                                NSArray : YSMProperty_Array(CustomSubClassOfYSMMappingBaseDataModel, property_name);
                                CustomClass : YSMProperty_Class(propertyClass,propertyName);
                            c、property have setter and getter;
                       DESC
  s.homepage         = "https://github.com/Cain1127/YSMRequestMappingExtend"
  s.license          = 'MIT'
  s.author           = { "ysmeng" => "49427823@163.com" }
  s.source           = { :git => "https://github.com/Cain1127/YSMRequestMappingExtend.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.1'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'YSMRequestMappingExtend' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'AFNetworking', '~> 2.3.1'
  s.dependency 'RestKit/ObjectMapping', '~> 0.23.3'

end
