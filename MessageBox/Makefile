export ARCHS=armv7 armv7s

export TARGET_CC = xcrun --sdk iphoneos clang
export TARGET_CXX = xcrun --sdk iphoneos clang++

GO_EASY_ON_ME=1

include theos/makefiles/common.mk

TWEAK_NAME = MessageBox
MessageBox_FILES = ABMessageBox.mm ABMessageBoxWindow.mm
MessageBox_FRAMEWORKS = UIKit CoreGraphics
MessageBox_PRIVATE_FRAMEWORKS = BackBoardServices AppSupport
MessageBox_LDFLAGS = -lsubstrate

include $(THEOS_MAKE_PATH)/tweak.mk

TWEAK_NAME = MessageBox_Facebook
MessageBox_Facebook_FILES = ABMessageBox_Facebook.mm
MessageBox_Facebook_PRIVATE_FRAMEWORKS = AppSupport
MessageBox_Facebook_FRAMEWORKS = UIKit CoreGraphics Foundation
MessageBox_Facebook_LDFLAGS = -lsubstrate -lobjc

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences
	cp -Rv Resources/* $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences