#include <mmu.h>
#include <memlayout.h>

#define REALLOC(x) (x - KERNBASE)
#所用的地址如果没有进行处理仍然位于虚拟高地址，只不过在bootmain中被加载到了低地址得以正常运行
.text
.globl kern_entry
kern_entry:
    # load pa of boot pgdir
    movl $REALLOC(__boot_pgdir), %eax   
    movl %eax, %cr3   #将页目录的物理地址放入CR3

    # enable paging
    movl %cr0, %eax
    orl $(CR0_PE | CR0_PG | CR0_AM | CR0_WP | CR0_NE | CR0_TS | CR0_EM | CR0_MP), %eax
    andl $~(CR0_TS | CR0_EM), %eax
    movl %eax, %cr0  #设置cr0，开启保护、分页

    # update eip
    # now, eip = 0x1.....
    leal next, %eax
    # set eip = KERNBASE + 0x1.....
    jmp *%eax  #跳转到绝对地址，位于0xC。。。。由于将kernbase-kernbase+4M这一页目录仍然映射到了最低的0-4M
	#将eip指向高位的虚拟地址，通过已经设置好的一个页目录表项仍然正常运行在低地址
next:

    # unmap va 0 ~ 4M, it's temporary mapping
    xorl %eax, %eax
    movl %eax, __boot_pgdir  #将页目录的第一个表项清零

    # set ebp, esp
    movl $0x0, %ebp  #栈底为0
    # the kernel stack region is from bootstack -- bootstacktop,
    # the kernel stack size is KSTACKSIZE (8KB)defined in memlayout.h
    movl $bootstacktop, %esp
    # now kernel stack is ready , call the first C function
    call kern_init

# should never get here
spin:
    jmp spin

.data
.align PGSIZE
    .globl bootstack
bootstack:  #栈
    .space KSTACKSIZE  #8k .space全置0
    .globl bootstacktop
bootstacktop:# 栈顶

# kernel builtin pgdir
# an initial page directory (Page Directory Table, PDT)
# These page directory table and page table can be reused!
.section .data.pgdir
.align PGSIZE
__boot_pgdir:
.globl __boot_pgdir
    # map va 0 ~ 4M to pa 0 ~ 4M (temporary)
    .long REALLOC(__boot_pt1) + (PTE_P | PTE_U | PTE_W)  #标志：已被载入、可写、用户
	#右移22为是高10位，是页目录的索引，*4表明每个占4字节，全为空，将kernelbase之前的页目录（除第一个）置零
    .space (KERNBASE >> PGSHIFT >> 10 << 2) - (. - __boot_pgdir)# 减掉第一个页目录项的大小 # pad to PDE of KERNBASE
    # map va KERNBASE + (0 ~ 4M) to pa 0 ~ 4M
    .long REALLOC(__boot_pt1) + (PTE_P | PTE_U | PTE_W) #第二个有效的页目录项，同样指向boot_pt1
    .space PGSIZE - (. - __boot_pgdir) # pad to PGSIZE  填充满4k

.set i, 0
__boot_pt1:  #页目录的第一个表项指向的1024个页表项 每个4字节，共4k
.rept 1024
    .long i * PGSIZE + (PTE_P | PTE_W)
    .set i, i + 1
.endr

