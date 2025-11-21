CC = gcc
CFLAGS = -Wall -Wextra -std=c11
TARGET = simple_container

all: $(TARGET)

$(TARGET): simple_container.c
	$(CC) $(CFLAGS) -o $(TARGET) simple_container.c

clean:
	rm -f $(TARGET)

.PHONY: all clean
