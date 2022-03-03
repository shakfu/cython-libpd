
# BREW_PORTAUDIO_STATIC="/usr/local/opt/portaudio/lib/libportaudio.a"

CYSOUND=src/cysounddevice
LIBPD=src/libpd


all: compile

compile:
	@CYTHONIZE=1 python3 setup.py build

audio_test:
	@echo "generating portaudio c implementation test"
	@gcc -o test_audio tests/test_audio.c ../libs/libpd.a \
		-framework CoreServices -framework CoreFoundation \
		-framework AudioUnit -framework AudioToolbox -framework CoreAudio \
		-I ../pure-data/src -I ../libpd_wrapper -I ../libpd_wrapper/util -lportaudio
	@echo "now run ./test_audio "


minim:
	@echo "generating minimal test"
	@gcc -o minim tests/minimal.c ../libs/libpd.a \
		-framework CoreServices -framework CoreFoundation \
		-framework AudioUnit -framework AudioToolbox -framework CoreAudio \
		-I ../pure-data/src -I ../libpd_wrapper -I ../libpd_wrapper/util -lportaudio
	@echo "now run ./minim"

.PHONY: test clean test_atom

test_atom: libpd
	@python3 ./tests/test_atom.py

test: libpd
	@python3 ./tests/test_pd_play.py

clean:
	@rm -rf build
	@rm -f $(CYSOUND)/*.c $(LIBPD)/*.c
	@rm -f $(CYSOUND)/*.html $(LIBPD)/*.html
	@rm -f test_audio
	@rm -f minim