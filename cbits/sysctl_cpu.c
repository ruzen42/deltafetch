#include "sysctl_cpu.h"

#ifdef __FreeBSD__

#include <sys/types.h>
#include <sys/sysctl.h>

const char *
get_cpu_model()
{
  static char model[64];
  size_t size = sizeof(model);

  if (sysctlbyname("hw.model", model, &size, NULL, 0) != 0) return "Unknown";

  return model;
}

#else 

const char *
get_cpu_model()
{
  return "Unknown";
}

#endif // __FreeBSD__



