CSS = gcc
IDIR=./include
CFLAGS = -I$(IDIR)

# Final binary
BIN = linstore

# Put all auto generated stuff to this build dir.
BUILD_DIR = ./build

# List of all .cpp source files.
#CPPS = main.cpp $(wildcard dir1/*.cpp) $(wildcard dir2/*.cpp)
CS := $(shell find ./src -name "*.c")

# All .o files go to build dir.
OBJ = $(CS:%.c=$(BUILD_DIR)/%.o)
# Gcc/Clang will create these .d files containing dependencies.
DEP = $(OBJ:%.o=%.d)

# Default target named after the binary.
$(BIN) : $(BUILD_DIR)/$(BIN)

# Actual target of the binary - depends on all .o files.
$(BUILD_DIR)/$(BIN) : $(OBJ)
	# Create build directories - same structure as sources.
	mkdir -p $(@D)
	# Just link all the object files.
	$(CSS) $(CFLAGS) $^ -o $@

# Include all .d files
-include $(DEP)

# Build target for every single object file.
# The potential dependency on header files is covered
# by calling `-include $(DEP)`.
$(BUILD_DIR)/%.o : %.c
	mkdir -p $(@D)
	# The -MMD flags additionaly creates a .d file with
	# the same name as the .o file.
	$(CSS) $(CFLAGS) -MMD -c $< -o $@

.PHONY : clean

# This should remove all generated files.
clean :
	-rm $(BUILD_DIR)/$(BIN) $(OBJ) $(DEP)

# Based on: http://stackoverflow.com/a/30142139
