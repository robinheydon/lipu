SRCS += $(wildcard src/*.zig)
SRCS += $(wildcard src/lipu/*.zig)
SRCS += Makefile

ARGS += -vvv
ARGS += -q
ARGS += test.lipu
ARGS += -o test.ast
# ARGS += -Dargs
# ARGS += -Dtokens
ARGS += -Dparse
ARGS += -Dexec
ARGS += -l test.log

all : coverage

run : test.log
	@cat test.log

test.log : zig-out/bin/lipu test.lipu Makefile
	@./zig-out/bin/lipu $(ARGS)

zig-out/bin/lipu : $(SRCS)
	@zig build --summary all --color on -freference-trace=32

test :
	@zig build test -j1 --summary all --color on -freference-trace=32

coverage :
	@zig build coverage -j1 --summary all --color on -freference-trace=32
	@python3 tools/coverage.py kcov-out/coverage/kcov-merged

valgrind : zig-out/bin/lipu test.lipu Makefile
	@valgrind --num-callers=32 --gen-suppressions=no --suppressions=lipu.sup --track-origins=yes zig-out/bin/lipu $(ARGS)

clean :
	@rm -rf kcov-out
	@rm -rf zig-cache
	@rm -rf zig-out
