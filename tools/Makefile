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
