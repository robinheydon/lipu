SRCS += $(wildcard src/*.zig)
SRCS += $(wildcard src/lipu/*.zig)
SRCS += Makefile

# ARGS += test.lipu
# ARGS += -o test.ast
# ARGS += -Dargs
# ARGS += -Dtokens
# ARGS += -Dparsing
# ARGS += -l test.log

all : coverage

run : zig-out/bin/lipu test.lipu
	@./zig-out/bin/lipu $(ARGS) -q -vvv -l test.log

zig-out/bin/lipu : $(SRCS)
	@zig build --summary all --color on -freference-trace=32

test :
	@zig build test --summary all --color on

coverage :
	@zig build coverage --summary none --color on
	@python3 tools/coverage.py kcov-out/coverage/kcov-merged

clean :
	@rm -rf kcov-out
	@rm -rf zig-cache
	@rm -rf zig-out
