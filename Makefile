ROOT_DIR = $(shell dirname $(realpath $(firstword ${MAKEFILE_LIST})))
MAKEFLAGS += --no-builtin-rules # turn off this shit

VERSION = 0.1
CPP = clang++
TSC ?= tsc
CPPFLAGS ?=
LDFLAGS ?=
SYSROOT ?= /usr/share/wasi-sysroot/
BUILDDIR ?= ${ROOT_DIR}/build
LTO ?= 0
DEBUG ?= 0

WASM_DIRECTORY = wasm
WASM_FLAGS = --target=wasm32-wasip1 --sysroot=${SYSROOT} -std=gnu++20
override CPPFLAGS = ${WASM_FLAGS} -fno-rtti -fno-exceptions -I${ROOT_DIR}
override LDFLAGS = ${WASM_FLAGS}  \
	-Wl,-z,stack-size=$(shell echo $$((8 * 1024 * 1024))) \
	-Wl,--import-undefined,--allow-undefined-file=${WASM_DIRECTORY}/wasm.syms \
	-Wl,--strip-all

ifeq (${LTO}, 1)
override CPPFLAGS += -flto
override LDFLAGS += -flto -Wl,--lto-O3
endif

ifeq (${DEBUG}, 1)
override CPPFLAGS += -g
else
override CPPFLAGS += -O2 -Os -DNDEBUG
override LDFLAGS += -Wl,-O1
endif

.DEFAULT_GOAL: all
all: ${BUILDDIR}/index.html ${BUILDDIR}/index.css ${BUILDDIR}/index.js ${BUILDDIR}/index.wasm

define cppdef
$(patsubst %.cpp, %.o, $1): $1 $(shell ${CPP} $1 ${CPPFLAGS} -E | grep -oe "\.\?/.*\.hpp" | sort -u)
	${CPP} -c $1 ${CPPFLAGS} -o $(patsubst %.cpp, %.o, $1)
endef

SRCS = $(addprefix ${WASM_DIRECTORY}/, main.cpp)
OBJS = ${SRCS:%.cpp=%.o}
$(foreach src, ${SRCS}, $(eval $(call cppdef, ${src})))

${BUILDDIR}:
	mkdir $@

${BUILDDIR}/index.wasm: ${OBJS} ${BUILDDIR}
	${CPP} ${OBJS} ${LDFLAGS} -o $@

${BUILDDIR}/index.html: ${ROOT_DIR}/src/index.html
	@cp $^ $@
	@echo copying index.html

${BUILDDIR}/index.css: ${ROOT_DIR}/src/index.css
	@cp $^ $@
	@echo copying index.css
${BUILDDIR}/index.js: ${ROOT_DIR}/src/index.ts ${ROOT_DIR}/tsconfig.json
	tsc -p ${ROOT_DIR}/tsconfig.json --outDir ${BUILDDIR}

.PHONY: clean
clean:
	rm -f ${OBJS} ${BUILDDIR}/index.wasm

.PHONY: compile_commands
compile_commands: ${BUILDDIR}
	make --always-make --dry-run \
	| grep -wE '${CPP}' \
	| grep -w '\-c' \
	| jq -nR '[inputs|{directory:"${ROOT_DIR}", command:., file: match(" [^ ]+.cpp").string[1:]}]' \
	> ${BUILDDIR}/compile_commands.json
