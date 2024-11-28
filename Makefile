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

.PHONY: all
.DEFAULT_GOAL: all
all: ${BUILDDIR} ${BUILDDIR}/index.html ${BUILDDIR}/index.css ${BUILDDIR}/index.js ${BUILDDIR}/index.wasm

define cppdef
$(patsubst %.cpp, %.o, $1): $1 $(shell ${CPP} $1 ${CPPFLAGS} -E | grep -oe "\.\?/.*\.hpp" | sort -u)
	${CPP} -c $1 ${CPPFLAGS} -o $(patsubst %.cpp, %.o, $1)
endef

SRCS = $(addprefix ${WASM_DIRECTORY}/, main.cpp)
OBJS = ${SRCS:%.cpp=%.o}
$(foreach src, ${SRCS}, $(eval $(call cppdef, ${src})))

${BUILDDIR}:
	mkdir $@

BROWSER_WASI_ARCHIVE = ${BUILDDIR}/browser_wasi.tar.gz
${BUILDDIR}/browser_wasi/:
	curl -sSL https://github.com/bjorn3/browser_wasi_shim/archive/refs/tags/v0.3.0.tar.gz > ${BROWSER_WASI_ARCHIVE}
	tar -xf ${BROWSER_WASI_ARCHIVE} -C ${BUILDDIR}
	rm ${BROWSER_WASI_ARCHIVE}
	cd ${BUILDDIR}/browser_wasi_shim-0.3.0/ && npm i && npm run build
	cd ${BUILDDIR} && mv browser_wasi_shim-0.3.0/dist $@
	rm -rf ${BUILDDIR}/browser_wasi_shim-0.3.0/


${BUILDDIR}/index.wasm: ${OBJS} ${BUILDDIR}
	${CPP} ${OBJS} ${LDFLAGS} -o $@

${BUILDDIR}/index.html: ${ROOT_DIR}/src/index.html
	cp ${ROOT_DIR}/src/index.html $@
${BUILDDIR}/index.css: ${ROOT_DIR}/src/index.css
	cp ${ROOT_DIR}/src/index.css $@
${BUILDDIR}/index.js: ${BUILDDIR}/browser_wasi/ ${ROOT_DIR}/src/index.ts ${ROOT_DIR}/tsconfig.json
	tsc -p ${ROOT_DIR}/tsconfig.json --outDir ${BUILDDIR}

.PHONY: clean
clean:
	rm -rf ${OBJS} ${BUILDDIR}

.PHONY: compile_commands
compile_commands: ${BUILDDIR}
	make --always-make --dry-run \
	| grep -wE '${CPP}' \
	| grep -w '\-c' \
	| jq -nR '[inputs|{directory:"${ROOT_DIR}", command:., file: match(" [^ ]+.cpp").string[1:]}]' \
	> ${BUILDDIR}/compile_commands.json
