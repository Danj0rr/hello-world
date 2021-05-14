#ifndef __KERN_MM_VMM_H__
#define __KERN_MM_VMM_H__

#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <sync.h>

//pre define
struct mm_struct;

// the virtual continuous memory area(vma), [vm_start, vm_end), 
// addr belong to a vma means  vma.vm_start<= addr <vma.vm_end 
struct vma_struct {//只有一段[start, end]，以一段区域为单位管理虚拟内存
    struct mm_struct *vm_mm; // the set of vma using the same PDT 
    uintptr_t vm_start;      // start addr of vma      
    uintptr_t vm_end;        // end addr of vma, not include the vm_end itself
    uint32_t vm_flags;       // flags of vma
    list_entry_t list_link;  // linear list link which sorted by start addr of vma
};

#define le2vma(le, member)                  \
    to_struct((le), struct vma_struct, member)

#define VM_READ                 0x00000001
#define VM_WRITE                0x00000002
#define VM_EXEC                 0x00000004

// the control struct for [[a set of vma]] using the same PDT，主要功能是下面的四个结构，没有指向vma_struct的指针
struct mm_struct {//以PDT为单位管理，每个mm_struct管理所有的，同一页目录下的vma_struct，和vma_struct是两个不同的管理结构
    list_entry_t mmap_list;        // linear list link which sorted by start addr of vma，连接的是vma_stuct
    struct vma_struct *mmap_cache; // current accessed vma, used for speed purpose
                                   //功能类似cache，指向一片虚拟地址（该页目录对应地址下）中实际使用到的部分（有映射的部分）
    pde_t *pgdir;                  // the PDT of these vma
    int map_count;                 // the count of these vma，说明有多个vma_struct
    void *sm_priv;                 // the private data for swap manager
};

struct vma_struct *find_vma(struct mm_struct *mm, uintptr_t addr);
struct vma_struct *vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags);
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma);

struct mm_struct *mm_create(void);
void mm_destroy(struct mm_struct *mm);

void vmm_init(void);

int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr);

extern volatile unsigned int pgfault_num;
extern struct mm_struct *check_mm_struct;
#endif /* !__KERN_MM_VMM_H__ */

