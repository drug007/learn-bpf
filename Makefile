KPROBE := memcpy_kprobe 
STAT   := memcpy_stat

# Generate file name-scheme based on TARGETS
KERN_SOURCES := memcpy_kprobe_kern.c memcpy_stat_kern.c
KERN_OBJECTS = ${KERN_SOURCES:.c=.o}

STAT_USER := d_memcpy_stat
STAT_USER_SOURCES = memcpy_stat_user.d
STAT_USER_OBJECTS := ${STAT_USER_SOURCES:.d=.o} 

KPROBE_USER := d_memcpy_kprobe
KPROBE_USER_SOURCES = memcpy_kprobe_user.d
KPROBE_USER_OBJECTS := ${KPROBE_USER_SOURCES:.d=.o} 

# Notice: the kbuilddir can be redefined on make cmdline
KERNEL ?= /lib/modules/$(shell uname -r)/build/

CFLAGS := -g -O1 -Wall
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

all: $(KPROBE_USER) $(STAT_USER) $(KERN_OBJECTS)

.PHONY: clean $(CLANG) $(LLC)

clean:
	rm -f *.ll
	rm -f $(BPFLIB)
	rm -f $(KPROBE)
	rm -f $(STAT)
	rm -f $(KERN_OBJECTS)
	rm -f $(STAT_USER_OBJECTS)
	rm -f $(KPROBE_USER_OBJECTS)

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

$(KPROBE_USER): $(KPROBE_USER_SOURCES) $(BPFLIB) Makefile
	$(DC) $(KPROBE_USER_SOURCES) -g $(BPFLIB) -L-lelf -ofmemcpy_kprobe

$(STAT_USER): $(STAT_USER_SOURCES) $(BPFLIB) Makefile
	$(DC) $(STAT_USER_SOURCES) -g $(BPFLIB) -L-lelf -ofmemcpy_stat
