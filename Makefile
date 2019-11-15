TARGETS := memcpy_kprobe 

# Generate file name-scheme based on TARGETS
KERN_SOURCES := memcpy_kprobe_kern.c memcpy_stat_kern.c
USER_SOURCES := memcpy_kprobe_user.c
KERN_OBJECTS = ${KERN_SOURCES:.c=.o}
USER_OBJECTS = memcpy_kprobe_user.o

STAT_USER := d_memcpy_stat
STAT_USER_SOURCES = memcpy_stat_user.d
STAT_USER_OBJECTS := ${STAT_USER_SOURCES:.d=.o} 

# Notice: the kbuilddir can be redefined on make cmdline
KERNEL ?= /lib/modules/$(shell uname -r)/build/

CFLAGS := -O2 -Wall
CFLAGS += -I ./

# EXTRA_CFLAGS=-Werror

LDFLAGS= -lelf

BPFLIB = bpf/bpf.o
BPFLIB += bpf_load.o

LLC ?= llc
CLANG ?= clang
CC = gcc
DC = dmd

NOSTDINC_FLAGS := -nostdinc -isystem $(shell $(CC) -print-file-name=include)
ARCH=$(shell uname -m | sed 's/x86_64/x86/' | sed 's/i386/x86/')

LINUXINCLUDE += -I$(KERNEL)/arch/$(ARCH)/include/generated/uapi
LINUXINCLUDE += -I$(KERNEL)/arch/$(ARCH)/include/generated
LINUXINCLUDE += -I$(KERNEL)/arch/$(ARCH)/include
LINUXINCLUDE += -I$(KERNEL)/arch/$(ARCH)/include/uapi
LINUXINCLUDE += -I$(KERNEL)/include
LINUXINCLUDE += -I$(KERNEL)/include/uapi
LINUXINCLUDE += -include $(KERNEL)/include/linux/kconfig.h
LINUXINCLUDE += -I$(KERNEL)/include/generated/uapi

all: $(TARGETS) $(STAT_USER) $(KERN_OBJECTS)

.PHONY: clean $(CLANG) $(LLC)

clean:
	rm -f *.ll
	rm -f $(BPFLIB)
	rm -f $(TARGETS)
	rm -f $(KERN_OBJECTS)
	rm -f $(USER_OBJECTS)

#  clang option -S generated output file with suffix .ll
#   which is the non-binary LLVM assembly language format
#   (normally LLVM bitcode format .bc is generated)
#
$(KERN_OBJECTS): %.o: %.c bpf_helpers.h
	#it will generate .ll file which is actually a LLVM assembly code
	$(CLANG) -S $(NOSTDINC_FLAGS) $(LINUXINCLUDE) $(EXTRA_CFLAGS) \
	    -D__KERNEL__ -D__ASM_SYSREG_H -Wno-unused-value -Wno-pointer-sign \
	    -Wno-compare-distinct-pointer-types \
	    -Wno-gnu-variable-sized-type-not-at-end \
	    -Wno-tautological-compare \
	    -O2 -emit-llvm -c $<
	#now translate LLVM assembly to native assembly
	$(LLC) -march=bpf -filetype=obj -o $@ ${@:.o=.ll}

$(TARGETS): $(USER_SOURCES) $(BPFLIB) Makefile
	$(CC) $(CFLAGS) $(BPFLIB) $(LDFLAGS) -o $@ $<

$(STAT_USER): $(STAT_USER_SOURCES) $(BPFLIB) Makefile
	$(DC) $(STAT_USER_SOURCES) -g $(BPFLIB) -L-lelf -ofmemcpy_stat