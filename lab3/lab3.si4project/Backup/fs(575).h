#ifndef __KERN_FS_FS_H__
#define __KERN_FS_FS_H__

#include <mmu.h>
//一个扇区512b，一个页占八个扇区
#define SECTSIZE            512
#define PAGE_NSECT          (PGSIZE / SECTSIZE)
//为了区分基址0与swap分区的0号，swap扇区的0号扇区不使用
#define SWAP_DEV_NO         1

#endif /* !__KERN_FS_FS_H__ */

