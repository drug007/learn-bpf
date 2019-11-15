import ldc.attributes;

extern(C):
__gshared:

struct pt_regs
{
/*
 * C ABI says these regs are callee-preserved. They aren't saved on kernel entry
 * unless syscall needs a complete, fully filled "struct pt_regs".
 */
	ulong r15;
	ulong r14;
	ulong r13;
	ulong r12;
	ulong bp;
	ulong bx;
/* These regs are callee-clobbered. Always saved on kernel entry. */
	ulong r11;
	ulong r10;
	ulong r9;
	ulong r8;
	ulong ax;
	ulong cx;
	ulong dx;
	ulong si;
	ulong di;
/*
 * On syscall entry, this is syscall#. On CPU exception, this is error code.
 * On hw interrupt, it's IRQ number:
 */
	ulong orig_ax;
/* Return frame for iretq */
	ulong ip;
	ulong cs;
	ulong flags;
	ulong sp;
	ulong ss;
/* top of stock page */
}

__gshared
@(section("kprobe/memcpy"))
extern(C)
int bpf_prog1(pt_regs *ctx)
{
	ulong size;
	char[] fmt = cast(char[]) "memcpy size %d\n";

	// bpf_probe_read(&size, sizeof(size), cast(void *)&ctx.dx);

	// bpf_trace_printk(fmt, sizeof(fmt), size);

	return 0;
}

__gshared
@(section("license"))
char[3] _license = "GPL";

__gshared
@(section("version"))
uint _version = 266002 /*LINUX_VERSION_CODE*/;
