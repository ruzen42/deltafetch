#ifndef DELTAFETCH_SYSCTL_CPU_H
#define DELTAFETCH_SYSCTL_CPU_H

#include <stdint.h>

const char *get_cpu_model();

uint64_t get_total_ram_kib();

uint64_t get_active_ram_kib();

#endif // DELTAFETCH_SYSCTL_CPU_H
