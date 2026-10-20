CC = x86_64-w64-mingw32-gcc
CFLAGS = -O2 -municode -Wall

all: sigcheck.exe winlist.exe muitest.exe

sigcheck.exe: sigcheck.c
	$(CC) $(CFLAGS) -o $@ $< -lwintrust -lcrypt32

clean:
	rm -f *.exe

winlist.exe: winlist.c
	$(CC) $(CFLAGS) -o $@ $< -lgdi32 -luser32

muitest.exe: muitest.c
	$(CC) $(CFLAGS) -o $@ $< -luser32

# DXBC disassembler on wine's bundled vkd3d-shader; not in `all`, it needs a configured wine tree
# with libs/vkd3d built (make libs/vkd3d/x86_64-windows/libvkd3d.a in $(WINESRC)/build64)
WINESRC ?= $(HOME)/src/wine-11.0
dxbcdis.exe: dxbcdis.c
	$(CC) -O2 -Wall -o $@ $< -I$(WINESRC)/libs/vkd3d/include $(WINESRC)/build64/libs/vkd3d/x86_64-windows/libvkd3d.a
