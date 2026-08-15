#include "sysctl_cpu.h"

#ifdef __FreeBSD__

#include <sys/types.h>
#include <sys/sysctl.h>

#include <stdint.h>
#include <stddef.h>
#include <unistd.h>

static uint64_t
get_sysctl_u32(const char *name)
{
    uint32_t value = 0;
    size_t size = sizeof(value);

    if (sysctlbyname(name, &value, &size, NULL, 0) != 0 ||
        size != sizeof(value)) {
        return 0;
    }

    return (uint64_t)value;
}

static uint64_t
get_page_size()
{
    long page_size = sysconf(_SC_PAGESIZE);

    if (page_size <= 0)
        return 4096;

    return (uint64_t)page_size;
}

const char *
get_cpu_model()
{
    static char model[256];
    size_t size = sizeof(model);

    if (sysctlbyname("hw.model", model, &size, NULL, 0) != 0)
        return "Unknown";

    model[sizeof(model) - 1] = '\0';

    return model;
}

uint64_t
get_total_ram_kib()
{
    uint64_t ram_bytes = 0;
    size_t size = sizeof(ram_bytes);

    if (sysctlbyname("hw.realmem", &ram_bytes, &size, NULL, 0) != 0 ||
        size != sizeof(ram_bytes)) {
        return 0;
    }

    return ram_bytes / 1024;
}

uint64_t
get_active_ram_kib()
{
    uint64_t active_pages;
    uint64_t page_size;

    active_pages = get_sysctl_u32("vm.stats.vm.v_active_count");
    page_size = get_page_size();

    return (active_pages * page_size) / 1024;
}

#else /* !__FreeBSD__ */

#include <stdint.h>

const char *
get_cpu_model()
{
    return "Unknown";
}

uint64_t
get_total_ram_kib()
{
    return 0;
}

uint64_t
get_active_ram_kib()
{
    return 0;
}

#endif /* __FreeBSD__ */
