//
//  MmapCDarwin.h
//  
//
//  Created by Dr. Brandon Wiley on 8/13/22.
//

#ifndef MMAP_C_DARWIN_h
#define MMAP_C_DARWIN_h

#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

void *mmap(void *addr, size_t len, int prot, int flags, int fildes, off_t offset);
int munmap(void *addr, size_t len);
int msync(void *addr, size_t len, int flags);

#endif /* Header_h */
