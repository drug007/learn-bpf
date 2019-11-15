import core.stdc.stdio;

extern(C)
{
	__gshared int load_bpf_file(char *path);

	enum MAX_MAPS = 32;
	__gshared extern int [MAX_MAPS] map_fd;
	enum BPF_LOG_BUF_SIZE = (uint.max >> 8); /* verifier maximum in kernels <= 5.1 */
	__gshared extern char[BPF_LOG_BUF_SIZE] bpf_log_buf;
	int bpf_map_lookup_elem(int fd, const void *key, void *value);
	void read_trace_pipe();
}

extern(C) int main(int argc, char** argv)
{
	char[256] filename;

	snprintf(filename.ptr, filename.sizeof, "%s_kern.o", argv[0]);

	if (load_bpf_file(filename.ptr)) {
		printf("%s", bpf_log_buf.ptr);
		return 1;
	}

	read_trace_pipe();

	return 0;
}
