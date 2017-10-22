ARCHS = arm64 armv7
FINALPACKAGE=1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WazeRedirect
WazeRedirect_FILES = Tweak.xm
WazeRedirect_FRAMEWORKS = WebKit UIKit CoreLocation

include $(THEOS_MAKE_PATH)/tweak.mk
after-install::
	install.exec "killall backboardd"

