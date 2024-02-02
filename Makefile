SRCS += $(wildcard src/*.zig)
SRCS += $(wildcard src/lipu/*.zig)
SRCS += Makefile

ARGS += -vvv
ARGS += test.lipu
ARGS += -o test.ast
ARGS += -Dargs
ARGS += -Dtokens

run : zig-out/bin/lipu test.lipu
	./zig-out/bin/lipu $(ARGS)

zig-out/bin/lipu : $(SRCS)
	zig build --summary all --color on

test :
	zig build test --summary all --color on

coverage :
	rm -rf kcov-out
	zig build coverage --summary all --color on --verbose

clean :
	rm -rf kcov-out
	rm -rf zig-cache
	rm -rf zig-out
