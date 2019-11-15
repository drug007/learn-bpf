import core.stdc.stdio;
import core.sys.posix.unistd : sleep;

extern(C)
{
	int load_bpf_file(char *path);

	enum MAX_MAPS = 32;
	align(32)
	__gshared int [MAX_MAPS] map_fd;
	enum BPF_LOG_BUF_SIZE = (uint.max >> 8); /* verifier maximum in kernels <= 5.1 */
	__gshared extern char[BPF_LOG_BUF_SIZE] bpf_log_buf;
	int bpf_map_lookup_elem(int fd, const void *key, void *value);
}

int main(string[] args)
{
	char[256] filename;
	size_t size;
	uint size_cnt = 0;

	const len = filename.length < args[0].length+1 ? filename.length : args[0].length+1;
	snprintf(filename.ptr, len, "%s_kern.o", args[0].ptr);
	if (load_bpf_file(filename.ptr)) {
		printf("Error: %s\n", bpf_log_buf.ptr);
		return 1;
	}

	while (1) {
		printf("\tSize\t\tCount\n");
		for (size = 0; size <=1024; size = size + 64) {
			if(bpf_map_lookup_elem(map_fd[0], &size, &size_cnt))
				size_cnt = 0;
			if (size == 1024)
				printf("%4ld - %4ld*\t\t%d\n", size - 63, size,
						size_cnt);
			else if (size)
				printf("%4ld - %4ld\t\t%d\n", size - 63, size,
						size_cnt);
			else
				printf("   0\t\t\t%d\n", size_cnt);
		}
		printf ("* Size > 1024 have been counted in this interval\n");
		sleep(2);
	}

	return 0;
}
