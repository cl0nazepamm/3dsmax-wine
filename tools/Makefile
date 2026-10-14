CC = x86_64-w64-mingw32-gcc
CFLAGS = -O2 -municode -Wall

all: sigcheck.exe

sigcheck.exe: sigcheck.c
	$(CC) $(CFLAGS) -o $@ $< -lwintrust -lcrypt32

clean:
	rm -f *.exe
