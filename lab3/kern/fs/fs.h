#ifndef __KERN_FS_FS_H__
#define __KERN_FS_FS_H__

#include <mmu.h>
<<<<<<< HEAD

#define SECTSIZE            512
#define PAGE_NSECT          (PGSIZE / SECTSIZE)

=======
//一个扇区512b，一个页占八个扇区
#define SECTSIZE            512
#define PAGE_NSECT          (PGSIZE / SECTSIZE)
//使用1号硬盘
>>>>>>> f5feecaf1bb2b59e9266ec8b9c4648a7cd0de235
#define SWAP_DEV_NO         1

#endif /* !__KERN_FS_FS_H__ */

