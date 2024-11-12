.PHONY: build run debug compilar-tableros help-opcodes

SRC_DIR=./src
BUILD_DIR=./build
UTILS_DIR=./utils
ARCHIVOS_ASM=$(wildcard $(SRC_DIR)/*.asm)
ARCHIVOS_OBJ=$(patsubst $(SRC_DIR)/%.asm, $(BUILD_DIR)/%.o, $(ARCHIVOS_ASM))
EJECUTABLE=$(BUILD_DIR)/asalto
SCRIPT_COMPILACION_TABLEROS=$(UTILS_DIR)/compilar-tableros

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm
	@nasm -f elf64 -g -F dwarf -o $@ $<

$(EJECUTABLE): $(ARCHIVOS_OBJ)
	@gcc -z noexecstack -no-pie -o $(EJECUTABLE) $(ARCHIVOS_OBJ)

build: $(EJECUTABLE)

run: $(EJECUTABLE)
	@./$(EJECUTABLE)

valgrind: $(EJECUTABLE)
	@valgrind $(EJECUTABLE)

debug: $(EJECUTABLE)
	@gdb -tui ./$(EJECUTABLE)

compilar-tableros:
	@./$(SCRIPT_COMPILACION_TABLEROS)

help-opcodes:
	@cat /usr/include/x86_64-linux-gnu/asm/unistd_64.h
