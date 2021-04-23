
bin/kernel：     文件格式 elf32-i386


Disassembly of section .text:

c0100000 <kern_entry>:
#所用的地址如果没有进行处理仍然位于虚拟高地址，只不过在bootmain中被加载到了低地址得以正常运行
.text
.globl kern_entry
kern_entry:
    # load pa of boot pgdir
    movl $REALLOC(__boot_pgdir), %eax   
c0100000:	b8 00 80 11 00       	mov    $0x118000,%eax
    movl %eax, %cr3   #将页目录的物理地址放入CR3
c0100005:	0f 22 d8             	mov    %eax,%cr3

    # enable paging
    movl %cr0, %eax
c0100008:	0f 20 c0             	mov    %cr0,%eax
    orl $(CR0_PE | CR0_PG | CR0_AM | CR0_WP | CR0_NE | CR0_TS | CR0_EM | CR0_MP), %eax
c010000b:	0d 2f 00 05 80       	or     $0x8005002f,%eax
    andl $~(CR0_TS | CR0_EM), %eax
c0100010:	83 e0 f3             	and    $0xfffffff3,%eax
    movl %eax, %cr0  #设置cr0，开启保护、分页
c0100013:	0f 22 c0             	mov    %eax,%cr0

    # update eip
    # now, eip = 0x1.....
    leal next, %eax
c0100016:	8d 05 1e 00 10 c0    	lea    0xc010001e,%eax
    # set eip = KERNBASE + 0x1.....
    jmp *%eax  #跳转到绝对地址，位于0xC。。。。由于将kernbase-kernbase+4M这一页目录仍然映射到了最低的0-4M
c010001c:	ff e0                	jmp    *%eax

c010001e <next>:
	#将eip指向高位的虚拟地址，通过已经设置好的一个页目录表项仍然正常运行在低地址
next:

    # unmap va 0 ~ 4M, it's temporary mapping
    xorl %eax, %eax
c010001e:	31 c0                	xor    %eax,%eax
    movl %eax, __boot_pgdir  #将页目录的第一个表项清零
c0100020:	a3 00 80 11 c0       	mov    %eax,0xc0118000

    # set ebp, esp
    movl $0x0, %ebp  #栈底为0
c0100025:	bd 00 00 00 00       	mov    $0x0,%ebp
    # the kernel stack region is from bootstack -- bootstacktop,
    # the kernel stack size is KSTACKSIZE (8KB)defined in memlayout.h
    movl $bootstacktop, %esp
c010002a:	bc 00 70 11 c0       	mov    $0xc0117000,%esp
    # now kernel stack is ready , call the first C function
    call kern_init
c010002f:	e8 02 00 00 00       	call   c0100036 <kern_init>

c0100034 <spin>:

# should never get here
spin:
    jmp spin
c0100034:	eb fe                	jmp    c0100034 <spin>

c0100036 <kern_init>:
int kern_init(void) __attribute__((noreturn)); //函数不会返回
void grade_backtrace(void);
static void lab1_switch_test(void);

int
kern_init(void) {
c0100036:	55                   	push   %ebp
c0100037:	89 e5                	mov    %esp,%ebp
c0100039:	83 ec 18             	sub    $0x18,%esp
    extern char edata[], end[];
    memset(edata, 0, end - edata);  //在ld中定义 edata是data段的结束地址 end是bss段的结束地址 end-edata就是bss的大小
c010003c:	ba 28 af 11 c0       	mov    $0xc011af28,%edx
c0100041:	b8 00 a0 11 c0       	mov    $0xc011a000,%eax
c0100046:	29 c2                	sub    %eax,%edx
c0100048:	89 d0                	mov    %edx,%eax
c010004a:	83 ec 04             	sub    $0x4,%esp
c010004d:	50                   	push   %eax
c010004e:	6a 00                	push   $0x0
c0100050:	68 00 a0 11 c0       	push   $0xc011a000
c0100055:	e8 ff 53 00 00       	call   c0105459 <memset>
c010005a:	83 c4 10             	add    $0x10,%esp

    cons_init();                // init the console
c010005d:	e8 67 15 00 00       	call   c01015c9 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
c0100062:	c7 45 f4 00 5c 10 c0 	movl   $0xc0105c00,-0xc(%ebp)
    cprintf("%s\n\n", message);
c0100069:	83 ec 08             	sub    $0x8,%esp
c010006c:	ff 75 f4             	pushl  -0xc(%ebp)
c010006f:	68 1c 5c 10 c0       	push   $0xc0105c1c
c0100074:	e8 04 02 00 00       	call   c010027d <cprintf>
c0100079:	83 c4 10             	add    $0x10,%esp

    print_kerninfo();
c010007c:	e8 9b 08 00 00       	call   c010091c <print_kerninfo>

    grade_backtrace();
c0100081:	e8 74 00 00 00       	call   c01000fa <grade_backtrace>

    pmm_init();                 // init physical memory management
c0100086:	e8 9d 31 00 00       	call   c0103228 <pmm_init>

    pic_init();                 // init interrupt controller
c010008b:	e8 ab 16 00 00       	call   c010173b <pic_init>
    idt_init();                 // init interrupt descriptor table
c0100090:	e8 0c 18 00 00       	call   c01018a1 <idt_init>

    clock_init();               // init clock interrupt
c0100095:	e8 d6 0c 00 00       	call   c0100d70 <clock_init>
    intr_enable();              // enable irq interrupt
c010009a:	e8 d9 17 00 00       	call   c0101878 <intr_enable>
    //LAB1: CAHLLENGE 1 If you try to do it, uncomment lab1_switch_test()
    // user/kernel mode switch test
    //lab1_switch_test();

    /* do nothing */
    while (1);
c010009f:	eb fe                	jmp    c010009f <kern_init+0x69>

c01000a1 <grade_backtrace2>:
}

void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
c01000a1:	55                   	push   %ebp
c01000a2:	89 e5                	mov    %esp,%ebp
c01000a4:	83 ec 08             	sub    $0x8,%esp
    mon_backtrace(0, NULL, NULL);
c01000a7:	83 ec 04             	sub    $0x4,%esp
c01000aa:	6a 00                	push   $0x0
c01000ac:	6a 00                	push   $0x0
c01000ae:	6a 00                	push   $0x0
c01000b0:	e8 a9 0c 00 00       	call   c0100d5e <mon_backtrace>
c01000b5:	83 c4 10             	add    $0x10,%esp
}
c01000b8:	90                   	nop
c01000b9:	c9                   	leave  
c01000ba:	c3                   	ret    

c01000bb <grade_backtrace1>:

void __attribute__((noinline))
grade_backtrace1(int arg0, int arg1) {
c01000bb:	55                   	push   %ebp
c01000bc:	89 e5                	mov    %esp,%ebp
c01000be:	53                   	push   %ebx
c01000bf:	83 ec 04             	sub    $0x4,%esp
    grade_backtrace2(arg0, (int)&arg0, arg1, (int)&arg1);
c01000c2:	8d 4d 0c             	lea    0xc(%ebp),%ecx
c01000c5:	8b 55 0c             	mov    0xc(%ebp),%edx
c01000c8:	8d 5d 08             	lea    0x8(%ebp),%ebx
c01000cb:	8b 45 08             	mov    0x8(%ebp),%eax
c01000ce:	51                   	push   %ecx
c01000cf:	52                   	push   %edx
c01000d0:	53                   	push   %ebx
c01000d1:	50                   	push   %eax
c01000d2:	e8 ca ff ff ff       	call   c01000a1 <grade_backtrace2>
c01000d7:	83 c4 10             	add    $0x10,%esp
}
c01000da:	90                   	nop
c01000db:	8b 5d fc             	mov    -0x4(%ebp),%ebx
c01000de:	c9                   	leave  
c01000df:	c3                   	ret    

c01000e0 <grade_backtrace0>:

void __attribute__((noinline))
grade_backtrace0(int arg0, int arg1, int arg2) {
c01000e0:	55                   	push   %ebp
c01000e1:	89 e5                	mov    %esp,%ebp
c01000e3:	83 ec 08             	sub    $0x8,%esp
    grade_backtrace1(arg0, arg2);
c01000e6:	83 ec 08             	sub    $0x8,%esp
c01000e9:	ff 75 10             	pushl  0x10(%ebp)
c01000ec:	ff 75 08             	pushl  0x8(%ebp)
c01000ef:	e8 c7 ff ff ff       	call   c01000bb <grade_backtrace1>
c01000f4:	83 c4 10             	add    $0x10,%esp
}
c01000f7:	90                   	nop
c01000f8:	c9                   	leave  
c01000f9:	c3                   	ret    

c01000fa <grade_backtrace>:

void
grade_backtrace(void) {
c01000fa:	55                   	push   %ebp
c01000fb:	89 e5                	mov    %esp,%ebp
c01000fd:	83 ec 08             	sub    $0x8,%esp
    grade_backtrace0(0, (int)kern_init, 0xffff0000);
c0100100:	b8 36 00 10 c0       	mov    $0xc0100036,%eax
c0100105:	83 ec 04             	sub    $0x4,%esp
c0100108:	68 00 00 ff ff       	push   $0xffff0000
c010010d:	50                   	push   %eax
c010010e:	6a 00                	push   $0x0
c0100110:	e8 cb ff ff ff       	call   c01000e0 <grade_backtrace0>
c0100115:	83 c4 10             	add    $0x10,%esp
}
c0100118:	90                   	nop
c0100119:	c9                   	leave  
c010011a:	c3                   	ret    

c010011b <lab1_print_cur_status>:

static void
lab1_print_cur_status(void) {
c010011b:	55                   	push   %ebp
c010011c:	89 e5                	mov    %esp,%ebp
c010011e:	83 ec 18             	sub    $0x18,%esp
    static int round = 0;
    uint16_t reg1, reg2, reg3, reg4;
    asm volatile (
c0100121:	8c 4d f6             	mov    %cs,-0xa(%ebp)
c0100124:	8c 5d f4             	mov    %ds,-0xc(%ebp)
c0100127:	8c 45 f2             	mov    %es,-0xe(%ebp)
c010012a:	8c 55 f0             	mov    %ss,-0x10(%ebp)
            "mov %%cs, %0;"
            "mov %%ds, %1;"
            "mov %%es, %2;"
            "mov %%ss, %3;"
            : "=m"(reg1), "=m"(reg2), "=m"(reg3), "=m"(reg4));
    cprintf("%d: @ring %d\n", round, reg1 & 3);
c010012d:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0100131:	0f b7 c0             	movzwl %ax,%eax
c0100134:	83 e0 03             	and    $0x3,%eax
c0100137:	89 c2                	mov    %eax,%edx
c0100139:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c010013e:	83 ec 04             	sub    $0x4,%esp
c0100141:	52                   	push   %edx
c0100142:	50                   	push   %eax
c0100143:	68 21 5c 10 c0       	push   $0xc0105c21
c0100148:	e8 30 01 00 00       	call   c010027d <cprintf>
c010014d:	83 c4 10             	add    $0x10,%esp
    cprintf("%d:  cs = %x\n", round, reg1);
c0100150:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0100154:	0f b7 d0             	movzwl %ax,%edx
c0100157:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c010015c:	83 ec 04             	sub    $0x4,%esp
c010015f:	52                   	push   %edx
c0100160:	50                   	push   %eax
c0100161:	68 2f 5c 10 c0       	push   $0xc0105c2f
c0100166:	e8 12 01 00 00       	call   c010027d <cprintf>
c010016b:	83 c4 10             	add    $0x10,%esp
    cprintf("%d:  ds = %x\n", round, reg2);
c010016e:	0f b7 45 f4          	movzwl -0xc(%ebp),%eax
c0100172:	0f b7 d0             	movzwl %ax,%edx
c0100175:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c010017a:	83 ec 04             	sub    $0x4,%esp
c010017d:	52                   	push   %edx
c010017e:	50                   	push   %eax
c010017f:	68 3d 5c 10 c0       	push   $0xc0105c3d
c0100184:	e8 f4 00 00 00       	call   c010027d <cprintf>
c0100189:	83 c4 10             	add    $0x10,%esp
    cprintf("%d:  es = %x\n", round, reg3);
c010018c:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c0100190:	0f b7 d0             	movzwl %ax,%edx
c0100193:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c0100198:	83 ec 04             	sub    $0x4,%esp
c010019b:	52                   	push   %edx
c010019c:	50                   	push   %eax
c010019d:	68 4b 5c 10 c0       	push   $0xc0105c4b
c01001a2:	e8 d6 00 00 00       	call   c010027d <cprintf>
c01001a7:	83 c4 10             	add    $0x10,%esp
    cprintf("%d:  ss = %x\n", round, reg4);
c01001aa:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
c01001ae:	0f b7 d0             	movzwl %ax,%edx
c01001b1:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c01001b6:	83 ec 04             	sub    $0x4,%esp
c01001b9:	52                   	push   %edx
c01001ba:	50                   	push   %eax
c01001bb:	68 59 5c 10 c0       	push   $0xc0105c59
c01001c0:	e8 b8 00 00 00       	call   c010027d <cprintf>
c01001c5:	83 c4 10             	add    $0x10,%esp
    round ++;
c01001c8:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c01001cd:	83 c0 01             	add    $0x1,%eax
c01001d0:	a3 00 a0 11 c0       	mov    %eax,0xc011a000
}
c01001d5:	90                   	nop
c01001d6:	c9                   	leave  
c01001d7:	c3                   	ret    

c01001d8 <lab1_switch_to_user>:

static void
lab1_switch_to_user(void) {
c01001d8:	55                   	push   %ebp
c01001d9:	89 e5                	mov    %esp,%ebp
    //LAB1 CHALLENGE 1 : TODO
    asm volatile(
c01001db:	16                   	push   %ss
c01001dc:	54                   	push   %esp
c01001dd:	cd 78                	int    $0x78
c01001df:	89 ec                	mov    %ebp,%esp
           "int %0;"
           "movl %%ebp,%%esp;"
           :
           :"i"(T_SWITCH_TOU));
   
}
c01001e1:	90                   	nop
c01001e2:	5d                   	pop    %ebp
c01001e3:	c3                   	ret    

c01001e4 <lab1_switch_to_kernel>:

static void
lab1_switch_to_kernel(void) {
c01001e4:	55                   	push   %ebp
c01001e5:	89 e5                	mov    %esp,%ebp
    //LAB1 CHALLENGE 1 :  TODO
    asm volatile(
c01001e7:	cd 79                	int    $0x79
c01001e9:	89 ec                	mov    %ebp,%esp
	  "int %0;"
          "movl %%ebp,%%esp;"
          :
          :"i"(T_SWITCH_TOK));

}
c01001eb:	90                   	nop
c01001ec:	5d                   	pop    %ebp
c01001ed:	c3                   	ret    

c01001ee <lab1_switch_test>:

static void
lab1_switch_test(void) {
c01001ee:	55                   	push   %ebp
c01001ef:	89 e5                	mov    %esp,%ebp
c01001f1:	83 ec 08             	sub    $0x8,%esp
    lab1_print_cur_status();
c01001f4:	e8 22 ff ff ff       	call   c010011b <lab1_print_cur_status>
    cprintf("+++ switch to  user  mode +++\n");
c01001f9:	83 ec 0c             	sub    $0xc,%esp
c01001fc:	68 68 5c 10 c0       	push   $0xc0105c68
c0100201:	e8 77 00 00 00       	call   c010027d <cprintf>
c0100206:	83 c4 10             	add    $0x10,%esp
    lab1_switch_to_user();
c0100209:	e8 ca ff ff ff       	call   c01001d8 <lab1_switch_to_user>
    lab1_print_cur_status();
c010020e:	e8 08 ff ff ff       	call   c010011b <lab1_print_cur_status>
    cprintf("+++ switch to kernel mode +++\n");
c0100213:	83 ec 0c             	sub    $0xc,%esp
c0100216:	68 88 5c 10 c0       	push   $0xc0105c88
c010021b:	e8 5d 00 00 00       	call   c010027d <cprintf>
c0100220:	83 c4 10             	add    $0x10,%esp
    lab1_switch_to_kernel();
c0100223:	e8 bc ff ff ff       	call   c01001e4 <lab1_switch_to_kernel>
    lab1_print_cur_status();
c0100228:	e8 ee fe ff ff       	call   c010011b <lab1_print_cur_status>
}
c010022d:	90                   	nop
c010022e:	c9                   	leave  
c010022f:	c3                   	ret    

c0100230 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
c0100230:	55                   	push   %ebp
c0100231:	89 e5                	mov    %esp,%ebp
c0100233:	83 ec 08             	sub    $0x8,%esp
    cons_putc(c);
c0100236:	83 ec 0c             	sub    $0xc,%esp
c0100239:	ff 75 08             	pushl  0x8(%ebp)
c010023c:	e8 b9 13 00 00       	call   c01015fa <cons_putc>
c0100241:	83 c4 10             	add    $0x10,%esp
    (*cnt) ++;
c0100244:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100247:	8b 00                	mov    (%eax),%eax
c0100249:	8d 50 01             	lea    0x1(%eax),%edx
c010024c:	8b 45 0c             	mov    0xc(%ebp),%eax
c010024f:	89 10                	mov    %edx,(%eax)
}
c0100251:	90                   	nop
c0100252:	c9                   	leave  
c0100253:	c3                   	ret    

c0100254 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
c0100254:	55                   	push   %ebp
c0100255:	89 e5                	mov    %esp,%ebp
c0100257:	83 ec 18             	sub    $0x18,%esp
    int cnt = 0;
c010025a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
c0100261:	ff 75 0c             	pushl  0xc(%ebp)
c0100264:	ff 75 08             	pushl  0x8(%ebp)
c0100267:	8d 45 f4             	lea    -0xc(%ebp),%eax
c010026a:	50                   	push   %eax
c010026b:	68 30 02 10 c0       	push   $0xc0100230
c0100270:	e8 1a 55 00 00       	call   c010578f <vprintfmt>
c0100275:	83 c4 10             	add    $0x10,%esp
    return cnt;
c0100278:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c010027b:	c9                   	leave  
c010027c:	c3                   	ret    

c010027d <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
c010027d:	55                   	push   %ebp
c010027e:	89 e5                	mov    %esp,%ebp
c0100280:	83 ec 18             	sub    $0x18,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
c0100283:	8d 45 0c             	lea    0xc(%ebp),%eax
c0100286:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vcprintf(fmt, ap);
c0100289:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010028c:	83 ec 08             	sub    $0x8,%esp
c010028f:	50                   	push   %eax
c0100290:	ff 75 08             	pushl  0x8(%ebp)
c0100293:	e8 bc ff ff ff       	call   c0100254 <vcprintf>
c0100298:	83 c4 10             	add    $0x10,%esp
c010029b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
c010029e:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01002a1:	c9                   	leave  
c01002a2:	c3                   	ret    

c01002a3 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
c01002a3:	55                   	push   %ebp
c01002a4:	89 e5                	mov    %esp,%ebp
c01002a6:	83 ec 08             	sub    $0x8,%esp
    cons_putc(c);
c01002a9:	83 ec 0c             	sub    $0xc,%esp
c01002ac:	ff 75 08             	pushl  0x8(%ebp)
c01002af:	e8 46 13 00 00       	call   c01015fa <cons_putc>
c01002b4:	83 c4 10             	add    $0x10,%esp
}
c01002b7:	90                   	nop
c01002b8:	c9                   	leave  
c01002b9:	c3                   	ret    

c01002ba <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
c01002ba:	55                   	push   %ebp
c01002bb:	89 e5                	mov    %esp,%ebp
c01002bd:	83 ec 18             	sub    $0x18,%esp
    int cnt = 0;
c01002c0:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    char c;
    while ((c = *str ++) != '\0') {
c01002c7:	eb 14                	jmp    c01002dd <cputs+0x23>
        cputch(c, &cnt);
c01002c9:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c01002cd:	83 ec 08             	sub    $0x8,%esp
c01002d0:	8d 55 f0             	lea    -0x10(%ebp),%edx
c01002d3:	52                   	push   %edx
c01002d4:	50                   	push   %eax
c01002d5:	e8 56 ff ff ff       	call   c0100230 <cputch>
c01002da:	83 c4 10             	add    $0x10,%esp
 * */
int
cputs(const char *str) {
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
c01002dd:	8b 45 08             	mov    0x8(%ebp),%eax
c01002e0:	8d 50 01             	lea    0x1(%eax),%edx
c01002e3:	89 55 08             	mov    %edx,0x8(%ebp)
c01002e6:	0f b6 00             	movzbl (%eax),%eax
c01002e9:	88 45 f7             	mov    %al,-0x9(%ebp)
c01002ec:	80 7d f7 00          	cmpb   $0x0,-0x9(%ebp)
c01002f0:	75 d7                	jne    c01002c9 <cputs+0xf>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
c01002f2:	83 ec 08             	sub    $0x8,%esp
c01002f5:	8d 45 f0             	lea    -0x10(%ebp),%eax
c01002f8:	50                   	push   %eax
c01002f9:	6a 0a                	push   $0xa
c01002fb:	e8 30 ff ff ff       	call   c0100230 <cputch>
c0100300:	83 c4 10             	add    $0x10,%esp
    return cnt;
c0100303:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
c0100306:	c9                   	leave  
c0100307:	c3                   	ret    

c0100308 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
c0100308:	55                   	push   %ebp
c0100309:	89 e5                	mov    %esp,%ebp
c010030b:	83 ec 18             	sub    $0x18,%esp
    int c;
    while ((c = cons_getc()) == 0)
c010030e:	e8 30 13 00 00       	call   c0101643 <cons_getc>
c0100313:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0100316:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c010031a:	74 f2                	je     c010030e <getchar+0x6>
        /* do nothing */;
    return c;
c010031c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c010031f:	c9                   	leave  
c0100320:	c3                   	ret    

c0100321 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
c0100321:	55                   	push   %ebp
c0100322:	89 e5                	mov    %esp,%ebp
c0100324:	83 ec 18             	sub    $0x18,%esp
    if (prompt != NULL) {
c0100327:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c010032b:	74 13                	je     c0100340 <readline+0x1f>
        cprintf("%s", prompt);
c010032d:	83 ec 08             	sub    $0x8,%esp
c0100330:	ff 75 08             	pushl  0x8(%ebp)
c0100333:	68 a7 5c 10 c0       	push   $0xc0105ca7
c0100338:	e8 40 ff ff ff       	call   c010027d <cprintf>
c010033d:	83 c4 10             	add    $0x10,%esp
    }
    int i = 0, c;
c0100340:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while (1) {
        c = getchar();
c0100347:	e8 bc ff ff ff       	call   c0100308 <getchar>
c010034c:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (c < 0) {
c010034f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0100353:	79 0a                	jns    c010035f <readline+0x3e>
            return NULL;
c0100355:	b8 00 00 00 00       	mov    $0x0,%eax
c010035a:	e9 82 00 00 00       	jmp    c01003e1 <readline+0xc0>
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
c010035f:	83 7d f0 1f          	cmpl   $0x1f,-0x10(%ebp)
c0100363:	7e 2b                	jle    c0100390 <readline+0x6f>
c0100365:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
c010036c:	7f 22                	jg     c0100390 <readline+0x6f>
            cputchar(c);
c010036e:	83 ec 0c             	sub    $0xc,%esp
c0100371:	ff 75 f0             	pushl  -0x10(%ebp)
c0100374:	e8 2a ff ff ff       	call   c01002a3 <cputchar>
c0100379:	83 c4 10             	add    $0x10,%esp
            buf[i ++] = c;
c010037c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010037f:	8d 50 01             	lea    0x1(%eax),%edx
c0100382:	89 55 f4             	mov    %edx,-0xc(%ebp)
c0100385:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100388:	88 90 20 a0 11 c0    	mov    %dl,-0x3fee5fe0(%eax)
c010038e:	eb 4c                	jmp    c01003dc <readline+0xbb>
        }
        else if (c == '\b' && i > 0) {
c0100390:	83 7d f0 08          	cmpl   $0x8,-0x10(%ebp)
c0100394:	75 1a                	jne    c01003b0 <readline+0x8f>
c0100396:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c010039a:	7e 14                	jle    c01003b0 <readline+0x8f>
            cputchar(c);
c010039c:	83 ec 0c             	sub    $0xc,%esp
c010039f:	ff 75 f0             	pushl  -0x10(%ebp)
c01003a2:	e8 fc fe ff ff       	call   c01002a3 <cputchar>
c01003a7:	83 c4 10             	add    $0x10,%esp
            i --;
c01003aa:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
c01003ae:	eb 2c                	jmp    c01003dc <readline+0xbb>
        }
        else if (c == '\n' || c == '\r') {
c01003b0:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
c01003b4:	74 06                	je     c01003bc <readline+0x9b>
c01003b6:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
c01003ba:	75 8b                	jne    c0100347 <readline+0x26>
            cputchar(c);
c01003bc:	83 ec 0c             	sub    $0xc,%esp
c01003bf:	ff 75 f0             	pushl  -0x10(%ebp)
c01003c2:	e8 dc fe ff ff       	call   c01002a3 <cputchar>
c01003c7:	83 c4 10             	add    $0x10,%esp
            buf[i] = '\0';
c01003ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01003cd:	05 20 a0 11 c0       	add    $0xc011a020,%eax
c01003d2:	c6 00 00             	movb   $0x0,(%eax)
            return buf;
c01003d5:	b8 20 a0 11 c0       	mov    $0xc011a020,%eax
c01003da:	eb 05                	jmp    c01003e1 <readline+0xc0>
        }
    }
c01003dc:	e9 66 ff ff ff       	jmp    c0100347 <readline+0x26>
}
c01003e1:	c9                   	leave  
c01003e2:	c3                   	ret    

c01003e3 <__panic>:
/* *
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
c01003e3:	55                   	push   %ebp
c01003e4:	89 e5                	mov    %esp,%ebp
c01003e6:	83 ec 18             	sub    $0x18,%esp
    if (is_panic) {
c01003e9:	a1 20 a4 11 c0       	mov    0xc011a420,%eax
c01003ee:	85 c0                	test   %eax,%eax
c01003f0:	75 5f                	jne    c0100451 <__panic+0x6e>
        goto panic_dead;
    }
    is_panic = 1;
c01003f2:	c7 05 20 a4 11 c0 01 	movl   $0x1,0xc011a420
c01003f9:	00 00 00 

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
c01003fc:	8d 45 14             	lea    0x14(%ebp),%eax
c01003ff:	89 45 f4             	mov    %eax,-0xc(%ebp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
c0100402:	83 ec 04             	sub    $0x4,%esp
c0100405:	ff 75 0c             	pushl  0xc(%ebp)
c0100408:	ff 75 08             	pushl  0x8(%ebp)
c010040b:	68 aa 5c 10 c0       	push   $0xc0105caa
c0100410:	e8 68 fe ff ff       	call   c010027d <cprintf>
c0100415:	83 c4 10             	add    $0x10,%esp
    vcprintf(fmt, ap);
c0100418:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010041b:	83 ec 08             	sub    $0x8,%esp
c010041e:	50                   	push   %eax
c010041f:	ff 75 10             	pushl  0x10(%ebp)
c0100422:	e8 2d fe ff ff       	call   c0100254 <vcprintf>
c0100427:	83 c4 10             	add    $0x10,%esp
    cprintf("\n");
c010042a:	83 ec 0c             	sub    $0xc,%esp
c010042d:	68 c6 5c 10 c0       	push   $0xc0105cc6
c0100432:	e8 46 fe ff ff       	call   c010027d <cprintf>
c0100437:	83 c4 10             	add    $0x10,%esp
    
    cprintf("stack trackback:\n");
c010043a:	83 ec 0c             	sub    $0xc,%esp
c010043d:	68 c8 5c 10 c0       	push   $0xc0105cc8
c0100442:	e8 36 fe ff ff       	call   c010027d <cprintf>
c0100447:	83 c4 10             	add    $0x10,%esp
    print_stackframe();
c010044a:	e8 17 06 00 00       	call   c0100a66 <print_stackframe>
c010044f:	eb 01                	jmp    c0100452 <__panic+0x6f>
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
        goto panic_dead;
c0100451:	90                   	nop
    print_stackframe();
    
    va_end(ap);

panic_dead:
    intr_disable();
c0100452:	e8 28 14 00 00       	call   c010187f <intr_disable>
    while (1) {
        kmonitor(NULL);
c0100457:	83 ec 0c             	sub    $0xc,%esp
c010045a:	6a 00                	push   $0x0
c010045c:	e8 23 08 00 00       	call   c0100c84 <kmonitor>
c0100461:	83 c4 10             	add    $0x10,%esp
    }
c0100464:	eb f1                	jmp    c0100457 <__panic+0x74>

c0100466 <__warn>:
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
c0100466:	55                   	push   %ebp
c0100467:	89 e5                	mov    %esp,%ebp
c0100469:	83 ec 18             	sub    $0x18,%esp
    va_list ap;
    va_start(ap, fmt);
c010046c:	8d 45 14             	lea    0x14(%ebp),%eax
c010046f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
c0100472:	83 ec 04             	sub    $0x4,%esp
c0100475:	ff 75 0c             	pushl  0xc(%ebp)
c0100478:	ff 75 08             	pushl  0x8(%ebp)
c010047b:	68 da 5c 10 c0       	push   $0xc0105cda
c0100480:	e8 f8 fd ff ff       	call   c010027d <cprintf>
c0100485:	83 c4 10             	add    $0x10,%esp
    vcprintf(fmt, ap);
c0100488:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010048b:	83 ec 08             	sub    $0x8,%esp
c010048e:	50                   	push   %eax
c010048f:	ff 75 10             	pushl  0x10(%ebp)
c0100492:	e8 bd fd ff ff       	call   c0100254 <vcprintf>
c0100497:	83 c4 10             	add    $0x10,%esp
    cprintf("\n");
c010049a:	83 ec 0c             	sub    $0xc,%esp
c010049d:	68 c6 5c 10 c0       	push   $0xc0105cc6
c01004a2:	e8 d6 fd ff ff       	call   c010027d <cprintf>
c01004a7:	83 c4 10             	add    $0x10,%esp
    va_end(ap);
}
c01004aa:	90                   	nop
c01004ab:	c9                   	leave  
c01004ac:	c3                   	ret    

c01004ad <is_kernel_panic>:

bool
is_kernel_panic(void) {
c01004ad:	55                   	push   %ebp
c01004ae:	89 e5                	mov    %esp,%ebp
    return is_panic;
c01004b0:	a1 20 a4 11 c0       	mov    0xc011a420,%eax
}
c01004b5:	5d                   	pop    %ebp
c01004b6:	c3                   	ret    

c01004b7 <stab_binsearch>:
 *      stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
 * will exit setting left = 118, right = 554.
 * */
static void
stab_binsearch(const struct stab *stabs, int *region_left, int *region_right,
           int type, uintptr_t addr) {
c01004b7:	55                   	push   %ebp
c01004b8:	89 e5                	mov    %esp,%ebp
c01004ba:	83 ec 20             	sub    $0x20,%esp
    int l = *region_left, r = *region_right, any_matches = 0;
c01004bd:	8b 45 0c             	mov    0xc(%ebp),%eax
c01004c0:	8b 00                	mov    (%eax),%eax
c01004c2:	89 45 fc             	mov    %eax,-0x4(%ebp)
c01004c5:	8b 45 10             	mov    0x10(%ebp),%eax
c01004c8:	8b 00                	mov    (%eax),%eax
c01004ca:	89 45 f8             	mov    %eax,-0x8(%ebp)
c01004cd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

    while (l <= r) {
c01004d4:	e9 d2 00 00 00       	jmp    c01005ab <stab_binsearch+0xf4>
        int true_m = (l + r) / 2, m = true_m;
c01004d9:	8b 55 fc             	mov    -0x4(%ebp),%edx
c01004dc:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01004df:	01 d0                	add    %edx,%eax
c01004e1:	89 c2                	mov    %eax,%edx
c01004e3:	c1 ea 1f             	shr    $0x1f,%edx
c01004e6:	01 d0                	add    %edx,%eax
c01004e8:	d1 f8                	sar    %eax
c01004ea:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01004ed:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01004f0:	89 45 f0             	mov    %eax,-0x10(%ebp)

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
c01004f3:	eb 04                	jmp    c01004f9 <stab_binsearch+0x42>
            m --;
c01004f5:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)

    while (l <= r) {
        int true_m = (l + r) / 2, m = true_m;

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
c01004f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01004fc:	3b 45 fc             	cmp    -0x4(%ebp),%eax
c01004ff:	7c 1f                	jl     c0100520 <stab_binsearch+0x69>
c0100501:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100504:	89 d0                	mov    %edx,%eax
c0100506:	01 c0                	add    %eax,%eax
c0100508:	01 d0                	add    %edx,%eax
c010050a:	c1 e0 02             	shl    $0x2,%eax
c010050d:	89 c2                	mov    %eax,%edx
c010050f:	8b 45 08             	mov    0x8(%ebp),%eax
c0100512:	01 d0                	add    %edx,%eax
c0100514:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c0100518:	0f b6 c0             	movzbl %al,%eax
c010051b:	3b 45 14             	cmp    0x14(%ebp),%eax
c010051e:	75 d5                	jne    c01004f5 <stab_binsearch+0x3e>
            m --;
        }
        if (m < l) {    // no match in [l, m]
c0100520:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100523:	3b 45 fc             	cmp    -0x4(%ebp),%eax
c0100526:	7d 0b                	jge    c0100533 <stab_binsearch+0x7c>
            l = true_m + 1;
c0100528:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010052b:	83 c0 01             	add    $0x1,%eax
c010052e:	89 45 fc             	mov    %eax,-0x4(%ebp)
            continue;
c0100531:	eb 78                	jmp    c01005ab <stab_binsearch+0xf4>
        }

        // actual binary search
        any_matches = 1;
c0100533:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
        if (stabs[m].n_value < addr) {
c010053a:	8b 55 f0             	mov    -0x10(%ebp),%edx
c010053d:	89 d0                	mov    %edx,%eax
c010053f:	01 c0                	add    %eax,%eax
c0100541:	01 d0                	add    %edx,%eax
c0100543:	c1 e0 02             	shl    $0x2,%eax
c0100546:	89 c2                	mov    %eax,%edx
c0100548:	8b 45 08             	mov    0x8(%ebp),%eax
c010054b:	01 d0                	add    %edx,%eax
c010054d:	8b 40 08             	mov    0x8(%eax),%eax
c0100550:	3b 45 18             	cmp    0x18(%ebp),%eax
c0100553:	73 13                	jae    c0100568 <stab_binsearch+0xb1>
            *region_left = m;
c0100555:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100558:	8b 55 f0             	mov    -0x10(%ebp),%edx
c010055b:	89 10                	mov    %edx,(%eax)
            l = true_m + 1;
c010055d:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100560:	83 c0 01             	add    $0x1,%eax
c0100563:	89 45 fc             	mov    %eax,-0x4(%ebp)
c0100566:	eb 43                	jmp    c01005ab <stab_binsearch+0xf4>
        } else if (stabs[m].n_value > addr) {
c0100568:	8b 55 f0             	mov    -0x10(%ebp),%edx
c010056b:	89 d0                	mov    %edx,%eax
c010056d:	01 c0                	add    %eax,%eax
c010056f:	01 d0                	add    %edx,%eax
c0100571:	c1 e0 02             	shl    $0x2,%eax
c0100574:	89 c2                	mov    %eax,%edx
c0100576:	8b 45 08             	mov    0x8(%ebp),%eax
c0100579:	01 d0                	add    %edx,%eax
c010057b:	8b 40 08             	mov    0x8(%eax),%eax
c010057e:	3b 45 18             	cmp    0x18(%ebp),%eax
c0100581:	76 16                	jbe    c0100599 <stab_binsearch+0xe2>
            *region_right = m - 1;
c0100583:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100586:	8d 50 ff             	lea    -0x1(%eax),%edx
c0100589:	8b 45 10             	mov    0x10(%ebp),%eax
c010058c:	89 10                	mov    %edx,(%eax)
            r = m - 1;
c010058e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100591:	83 e8 01             	sub    $0x1,%eax
c0100594:	89 45 f8             	mov    %eax,-0x8(%ebp)
c0100597:	eb 12                	jmp    c01005ab <stab_binsearch+0xf4>
        } else {
            // exact match for 'addr', but continue loop to find
            // *region_right
            *region_left = m;
c0100599:	8b 45 0c             	mov    0xc(%ebp),%eax
c010059c:	8b 55 f0             	mov    -0x10(%ebp),%edx
c010059f:	89 10                	mov    %edx,(%eax)
            l = m;
c01005a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01005a4:	89 45 fc             	mov    %eax,-0x4(%ebp)
            addr ++;
c01005a7:	83 45 18 01          	addl   $0x1,0x18(%ebp)
static void
stab_binsearch(const struct stab *stabs, int *region_left, int *region_right,
           int type, uintptr_t addr) {
    int l = *region_left, r = *region_right, any_matches = 0;

    while (l <= r) {
c01005ab:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01005ae:	3b 45 f8             	cmp    -0x8(%ebp),%eax
c01005b1:	0f 8e 22 ff ff ff    	jle    c01004d9 <stab_binsearch+0x22>
            l = m;
            addr ++;
        }
    }

    if (!any_matches) {
c01005b7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01005bb:	75 0f                	jne    c01005cc <stab_binsearch+0x115>
        *region_right = *region_left - 1;
c01005bd:	8b 45 0c             	mov    0xc(%ebp),%eax
c01005c0:	8b 00                	mov    (%eax),%eax
c01005c2:	8d 50 ff             	lea    -0x1(%eax),%edx
c01005c5:	8b 45 10             	mov    0x10(%ebp),%eax
c01005c8:	89 10                	mov    %edx,(%eax)
        l = *region_right;
        for (; l > *region_left && stabs[l].n_type != type; l --)
            /* do nothing */;
        *region_left = l;
    }
}
c01005ca:	eb 3f                	jmp    c010060b <stab_binsearch+0x154>
    if (!any_matches) {
        *region_right = *region_left - 1;
    }
    else {
        // find rightmost region containing 'addr'
        l = *region_right;
c01005cc:	8b 45 10             	mov    0x10(%ebp),%eax
c01005cf:	8b 00                	mov    (%eax),%eax
c01005d1:	89 45 fc             	mov    %eax,-0x4(%ebp)
        for (; l > *region_left && stabs[l].n_type != type; l --)
c01005d4:	eb 04                	jmp    c01005da <stab_binsearch+0x123>
c01005d6:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
c01005da:	8b 45 0c             	mov    0xc(%ebp),%eax
c01005dd:	8b 00                	mov    (%eax),%eax
c01005df:	3b 45 fc             	cmp    -0x4(%ebp),%eax
c01005e2:	7d 1f                	jge    c0100603 <stab_binsearch+0x14c>
c01005e4:	8b 55 fc             	mov    -0x4(%ebp),%edx
c01005e7:	89 d0                	mov    %edx,%eax
c01005e9:	01 c0                	add    %eax,%eax
c01005eb:	01 d0                	add    %edx,%eax
c01005ed:	c1 e0 02             	shl    $0x2,%eax
c01005f0:	89 c2                	mov    %eax,%edx
c01005f2:	8b 45 08             	mov    0x8(%ebp),%eax
c01005f5:	01 d0                	add    %edx,%eax
c01005f7:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c01005fb:	0f b6 c0             	movzbl %al,%eax
c01005fe:	3b 45 14             	cmp    0x14(%ebp),%eax
c0100601:	75 d3                	jne    c01005d6 <stab_binsearch+0x11f>
            /* do nothing */;
        *region_left = l;
c0100603:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100606:	8b 55 fc             	mov    -0x4(%ebp),%edx
c0100609:	89 10                	mov    %edx,(%eax)
    }
}
c010060b:	90                   	nop
c010060c:	c9                   	leave  
c010060d:	c3                   	ret    

c010060e <debuginfo_eip>:
 * the specified instruction address, @addr.  Returns 0 if information
 * was found, and negative if not.  But even if it returns negative it
 * has stored some information into '*info'.
 * */
int
debuginfo_eip(uintptr_t addr, struct eipdebuginfo *info) {
c010060e:	55                   	push   %ebp
c010060f:	89 e5                	mov    %esp,%ebp
c0100611:	83 ec 38             	sub    $0x38,%esp
    const struct stab *stabs, *stab_end;
    const char *stabstr, *stabstr_end;

    info->eip_file = "<unknown>";
c0100614:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100617:	c7 00 f8 5c 10 c0    	movl   $0xc0105cf8,(%eax)
    info->eip_line = 0;
c010061d:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100620:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
    info->eip_fn_name = "<unknown>";
c0100627:	8b 45 0c             	mov    0xc(%ebp),%eax
c010062a:	c7 40 08 f8 5c 10 c0 	movl   $0xc0105cf8,0x8(%eax)
    info->eip_fn_namelen = 9;
c0100631:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100634:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
    info->eip_fn_addr = addr;
c010063b:	8b 45 0c             	mov    0xc(%ebp),%eax
c010063e:	8b 55 08             	mov    0x8(%ebp),%edx
c0100641:	89 50 10             	mov    %edx,0x10(%eax)
    info->eip_fn_narg = 0;
c0100644:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100647:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

    stabs = __STAB_BEGIN__;
c010064e:	c7 45 f4 6c 6f 10 c0 	movl   $0xc0106f6c,-0xc(%ebp)
    stab_end = __STAB_END__;
c0100655:	c7 45 f0 98 1e 11 c0 	movl   $0xc0111e98,-0x10(%ebp)
    stabstr = __STABSTR_BEGIN__;
c010065c:	c7 45 ec 99 1e 11 c0 	movl   $0xc0111e99,-0x14(%ebp)
    stabstr_end = __STABSTR_END__;
c0100663:	c7 45 e8 14 49 11 c0 	movl   $0xc0114914,-0x18(%ebp)

    // String table validity checks
    if (stabstr_end <= stabstr || stabstr_end[-1] != 0) {
c010066a:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010066d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c0100670:	76 0d                	jbe    c010067f <debuginfo_eip+0x71>
c0100672:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0100675:	83 e8 01             	sub    $0x1,%eax
c0100678:	0f b6 00             	movzbl (%eax),%eax
c010067b:	84 c0                	test   %al,%al
c010067d:	74 0a                	je     c0100689 <debuginfo_eip+0x7b>
        return -1;
c010067f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c0100684:	e9 91 02 00 00       	jmp    c010091a <debuginfo_eip+0x30c>
    // 'eip'.  First, we find the basic source file containing 'eip'.
    // Then, we look in that source file for the function.  Then we look
    // for the line number.

    // Search the entire set of stabs for the source file (type N_SO).
    int lfile = 0, rfile = (stab_end - stabs) - 1;
c0100689:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
c0100690:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100693:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100696:	29 c2                	sub    %eax,%edx
c0100698:	89 d0                	mov    %edx,%eax
c010069a:	c1 f8 02             	sar    $0x2,%eax
c010069d:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
c01006a3:	83 e8 01             	sub    $0x1,%eax
c01006a6:	89 45 e0             	mov    %eax,-0x20(%ebp)
    stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
c01006a9:	ff 75 08             	pushl  0x8(%ebp)
c01006ac:	6a 64                	push   $0x64
c01006ae:	8d 45 e0             	lea    -0x20(%ebp),%eax
c01006b1:	50                   	push   %eax
c01006b2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
c01006b5:	50                   	push   %eax
c01006b6:	ff 75 f4             	pushl  -0xc(%ebp)
c01006b9:	e8 f9 fd ff ff       	call   c01004b7 <stab_binsearch>
c01006be:	83 c4 14             	add    $0x14,%esp
    if (lfile == 0)
c01006c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01006c4:	85 c0                	test   %eax,%eax
c01006c6:	75 0a                	jne    c01006d2 <debuginfo_eip+0xc4>
        return -1;
c01006c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c01006cd:	e9 48 02 00 00       	jmp    c010091a <debuginfo_eip+0x30c>

    // Search within that file's stabs for the function definition
    // (N_FUN).
    int lfun = lfile, rfun = rfile;
c01006d2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01006d5:	89 45 dc             	mov    %eax,-0x24(%ebp)
c01006d8:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01006db:	89 45 d8             	mov    %eax,-0x28(%ebp)
    int lline, rline;
    stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
c01006de:	ff 75 08             	pushl  0x8(%ebp)
c01006e1:	6a 24                	push   $0x24
c01006e3:	8d 45 d8             	lea    -0x28(%ebp),%eax
c01006e6:	50                   	push   %eax
c01006e7:	8d 45 dc             	lea    -0x24(%ebp),%eax
c01006ea:	50                   	push   %eax
c01006eb:	ff 75 f4             	pushl  -0xc(%ebp)
c01006ee:	e8 c4 fd ff ff       	call   c01004b7 <stab_binsearch>
c01006f3:	83 c4 14             	add    $0x14,%esp

    if (lfun <= rfun) {
c01006f6:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01006f9:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01006fc:	39 c2                	cmp    %eax,%edx
c01006fe:	7f 7c                	jg     c010077c <debuginfo_eip+0x16e>
        // stabs[lfun] points to the function name
        // in the string table, but check bounds just in case.
        if (stabs[lfun].n_strx < stabstr_end - stabstr) {
c0100700:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100703:	89 c2                	mov    %eax,%edx
c0100705:	89 d0                	mov    %edx,%eax
c0100707:	01 c0                	add    %eax,%eax
c0100709:	01 d0                	add    %edx,%eax
c010070b:	c1 e0 02             	shl    $0x2,%eax
c010070e:	89 c2                	mov    %eax,%edx
c0100710:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100713:	01 d0                	add    %edx,%eax
c0100715:	8b 00                	mov    (%eax),%eax
c0100717:	8b 4d e8             	mov    -0x18(%ebp),%ecx
c010071a:	8b 55 ec             	mov    -0x14(%ebp),%edx
c010071d:	29 d1                	sub    %edx,%ecx
c010071f:	89 ca                	mov    %ecx,%edx
c0100721:	39 d0                	cmp    %edx,%eax
c0100723:	73 22                	jae    c0100747 <debuginfo_eip+0x139>
            info->eip_fn_name = stabstr + stabs[lfun].n_strx;
c0100725:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100728:	89 c2                	mov    %eax,%edx
c010072a:	89 d0                	mov    %edx,%eax
c010072c:	01 c0                	add    %eax,%eax
c010072e:	01 d0                	add    %edx,%eax
c0100730:	c1 e0 02             	shl    $0x2,%eax
c0100733:	89 c2                	mov    %eax,%edx
c0100735:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100738:	01 d0                	add    %edx,%eax
c010073a:	8b 10                	mov    (%eax),%edx
c010073c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010073f:	01 c2                	add    %eax,%edx
c0100741:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100744:	89 50 08             	mov    %edx,0x8(%eax)
        }
        info->eip_fn_addr = stabs[lfun].n_value;
c0100747:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010074a:	89 c2                	mov    %eax,%edx
c010074c:	89 d0                	mov    %edx,%eax
c010074e:	01 c0                	add    %eax,%eax
c0100750:	01 d0                	add    %edx,%eax
c0100752:	c1 e0 02             	shl    $0x2,%eax
c0100755:	89 c2                	mov    %eax,%edx
c0100757:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010075a:	01 d0                	add    %edx,%eax
c010075c:	8b 50 08             	mov    0x8(%eax),%edx
c010075f:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100762:	89 50 10             	mov    %edx,0x10(%eax)
        addr -= info->eip_fn_addr;
c0100765:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100768:	8b 40 10             	mov    0x10(%eax),%eax
c010076b:	29 45 08             	sub    %eax,0x8(%ebp)
        // Search within the function definition for the line number.
        lline = lfun;
c010076e:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100771:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfun;
c0100774:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0100777:	89 45 d0             	mov    %eax,-0x30(%ebp)
c010077a:	eb 15                	jmp    c0100791 <debuginfo_eip+0x183>
    } else {
        // Couldn't find function stab!  Maybe we're in an assembly
        // file.  Search the whole file for the line number.
        info->eip_fn_addr = addr;
c010077c:	8b 45 0c             	mov    0xc(%ebp),%eax
c010077f:	8b 55 08             	mov    0x8(%ebp),%edx
c0100782:	89 50 10             	mov    %edx,0x10(%eax)
        lline = lfile;
c0100785:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100788:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfile;
c010078b:	8b 45 e0             	mov    -0x20(%ebp),%eax
c010078e:	89 45 d0             	mov    %eax,-0x30(%ebp)
    }
    info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
c0100791:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100794:	8b 40 08             	mov    0x8(%eax),%eax
c0100797:	83 ec 08             	sub    $0x8,%esp
c010079a:	6a 3a                	push   $0x3a
c010079c:	50                   	push   %eax
c010079d:	e8 2b 4b 00 00       	call   c01052cd <strfind>
c01007a2:	83 c4 10             	add    $0x10,%esp
c01007a5:	89 c2                	mov    %eax,%edx
c01007a7:	8b 45 0c             	mov    0xc(%ebp),%eax
c01007aa:	8b 40 08             	mov    0x8(%eax),%eax
c01007ad:	29 c2                	sub    %eax,%edx
c01007af:	8b 45 0c             	mov    0xc(%ebp),%eax
c01007b2:	89 50 0c             	mov    %edx,0xc(%eax)

    // Search within [lline, rline] for the line number stab.
    // If found, set info->eip_line to the right line number.
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
c01007b5:	83 ec 0c             	sub    $0xc,%esp
c01007b8:	ff 75 08             	pushl  0x8(%ebp)
c01007bb:	6a 44                	push   $0x44
c01007bd:	8d 45 d0             	lea    -0x30(%ebp),%eax
c01007c0:	50                   	push   %eax
c01007c1:	8d 45 d4             	lea    -0x2c(%ebp),%eax
c01007c4:	50                   	push   %eax
c01007c5:	ff 75 f4             	pushl  -0xc(%ebp)
c01007c8:	e8 ea fc ff ff       	call   c01004b7 <stab_binsearch>
c01007cd:	83 c4 20             	add    $0x20,%esp
    if (lline <= rline) {
c01007d0:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01007d3:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01007d6:	39 c2                	cmp    %eax,%edx
c01007d8:	7f 24                	jg     c01007fe <debuginfo_eip+0x1f0>
        info->eip_line = stabs[rline].n_desc;
c01007da:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01007dd:	89 c2                	mov    %eax,%edx
c01007df:	89 d0                	mov    %edx,%eax
c01007e1:	01 c0                	add    %eax,%eax
c01007e3:	01 d0                	add    %edx,%eax
c01007e5:	c1 e0 02             	shl    $0x2,%eax
c01007e8:	89 c2                	mov    %eax,%edx
c01007ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01007ed:	01 d0                	add    %edx,%eax
c01007ef:	0f b7 40 06          	movzwl 0x6(%eax),%eax
c01007f3:	0f b7 d0             	movzwl %ax,%edx
c01007f6:	8b 45 0c             	mov    0xc(%ebp),%eax
c01007f9:	89 50 04             	mov    %edx,0x4(%eax)

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
c01007fc:	eb 13                	jmp    c0100811 <debuginfo_eip+0x203>
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
    if (lline <= rline) {
        info->eip_line = stabs[rline].n_desc;
    } else {
        return -1;
c01007fe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c0100803:	e9 12 01 00 00       	jmp    c010091a <debuginfo_eip+0x30c>
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
           && stabs[lline].n_type != N_SOL
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
        lline --;
c0100808:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010080b:	83 e8 01             	sub    $0x1,%eax
c010080e:	89 45 d4             	mov    %eax,-0x2c(%ebp)

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
c0100811:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0100814:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100817:	39 c2                	cmp    %eax,%edx
c0100819:	7c 56                	jl     c0100871 <debuginfo_eip+0x263>
           && stabs[lline].n_type != N_SOL
c010081b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010081e:	89 c2                	mov    %eax,%edx
c0100820:	89 d0                	mov    %edx,%eax
c0100822:	01 c0                	add    %eax,%eax
c0100824:	01 d0                	add    %edx,%eax
c0100826:	c1 e0 02             	shl    $0x2,%eax
c0100829:	89 c2                	mov    %eax,%edx
c010082b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010082e:	01 d0                	add    %edx,%eax
c0100830:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c0100834:	3c 84                	cmp    $0x84,%al
c0100836:	74 39                	je     c0100871 <debuginfo_eip+0x263>
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
c0100838:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010083b:	89 c2                	mov    %eax,%edx
c010083d:	89 d0                	mov    %edx,%eax
c010083f:	01 c0                	add    %eax,%eax
c0100841:	01 d0                	add    %edx,%eax
c0100843:	c1 e0 02             	shl    $0x2,%eax
c0100846:	89 c2                	mov    %eax,%edx
c0100848:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010084b:	01 d0                	add    %edx,%eax
c010084d:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c0100851:	3c 64                	cmp    $0x64,%al
c0100853:	75 b3                	jne    c0100808 <debuginfo_eip+0x1fa>
c0100855:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0100858:	89 c2                	mov    %eax,%edx
c010085a:	89 d0                	mov    %edx,%eax
c010085c:	01 c0                	add    %eax,%eax
c010085e:	01 d0                	add    %edx,%eax
c0100860:	c1 e0 02             	shl    $0x2,%eax
c0100863:	89 c2                	mov    %eax,%edx
c0100865:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100868:	01 d0                	add    %edx,%eax
c010086a:	8b 40 08             	mov    0x8(%eax),%eax
c010086d:	85 c0                	test   %eax,%eax
c010086f:	74 97                	je     c0100808 <debuginfo_eip+0x1fa>
        lline --;
    }
    if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr) {
c0100871:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0100874:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100877:	39 c2                	cmp    %eax,%edx
c0100879:	7c 46                	jl     c01008c1 <debuginfo_eip+0x2b3>
c010087b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010087e:	89 c2                	mov    %eax,%edx
c0100880:	89 d0                	mov    %edx,%eax
c0100882:	01 c0                	add    %eax,%eax
c0100884:	01 d0                	add    %edx,%eax
c0100886:	c1 e0 02             	shl    $0x2,%eax
c0100889:	89 c2                	mov    %eax,%edx
c010088b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010088e:	01 d0                	add    %edx,%eax
c0100890:	8b 00                	mov    (%eax),%eax
c0100892:	8b 4d e8             	mov    -0x18(%ebp),%ecx
c0100895:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0100898:	29 d1                	sub    %edx,%ecx
c010089a:	89 ca                	mov    %ecx,%edx
c010089c:	39 d0                	cmp    %edx,%eax
c010089e:	73 21                	jae    c01008c1 <debuginfo_eip+0x2b3>
        info->eip_file = stabstr + stabs[lline].n_strx;
c01008a0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01008a3:	89 c2                	mov    %eax,%edx
c01008a5:	89 d0                	mov    %edx,%eax
c01008a7:	01 c0                	add    %eax,%eax
c01008a9:	01 d0                	add    %edx,%eax
c01008ab:	c1 e0 02             	shl    $0x2,%eax
c01008ae:	89 c2                	mov    %eax,%edx
c01008b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01008b3:	01 d0                	add    %edx,%eax
c01008b5:	8b 10                	mov    (%eax),%edx
c01008b7:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01008ba:	01 c2                	add    %eax,%edx
c01008bc:	8b 45 0c             	mov    0xc(%ebp),%eax
c01008bf:	89 10                	mov    %edx,(%eax)
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
c01008c1:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01008c4:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01008c7:	39 c2                	cmp    %eax,%edx
c01008c9:	7d 4a                	jge    c0100915 <debuginfo_eip+0x307>
        for (lline = lfun + 1;
c01008cb:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01008ce:	83 c0 01             	add    $0x1,%eax
c01008d1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
c01008d4:	eb 18                	jmp    c01008ee <debuginfo_eip+0x2e0>
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
            info->eip_fn_narg ++;
c01008d6:	8b 45 0c             	mov    0xc(%ebp),%eax
c01008d9:	8b 40 14             	mov    0x14(%eax),%eax
c01008dc:	8d 50 01             	lea    0x1(%eax),%edx
c01008df:	8b 45 0c             	mov    0xc(%ebp),%eax
c01008e2:	89 50 14             	mov    %edx,0x14(%eax)
    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
c01008e5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01008e8:	83 c0 01             	add    $0x1,%eax
c01008eb:	89 45 d4             	mov    %eax,-0x2c(%ebp)

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
             lline < rfun && stabs[lline].n_type == N_PSYM;
c01008ee:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01008f1:	8b 45 d8             	mov    -0x28(%ebp),%eax
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
        for (lline = lfun + 1;
c01008f4:	39 c2                	cmp    %eax,%edx
c01008f6:	7d 1d                	jge    c0100915 <debuginfo_eip+0x307>
             lline < rfun && stabs[lline].n_type == N_PSYM;
c01008f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01008fb:	89 c2                	mov    %eax,%edx
c01008fd:	89 d0                	mov    %edx,%eax
c01008ff:	01 c0                	add    %eax,%eax
c0100901:	01 d0                	add    %edx,%eax
c0100903:	c1 e0 02             	shl    $0x2,%eax
c0100906:	89 c2                	mov    %eax,%edx
c0100908:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010090b:	01 d0                	add    %edx,%eax
c010090d:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c0100911:	3c a0                	cmp    $0xa0,%al
c0100913:	74 c1                	je     c01008d6 <debuginfo_eip+0x2c8>
             lline ++) {
            info->eip_fn_narg ++;
        }
    }
    return 0;
c0100915:	b8 00 00 00 00       	mov    $0x0,%eax
}
c010091a:	c9                   	leave  
c010091b:	c3                   	ret    

c010091c <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void
print_kerninfo(void) {
c010091c:	55                   	push   %ebp
c010091d:	89 e5                	mov    %esp,%ebp
c010091f:	83 ec 08             	sub    $0x8,%esp
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
c0100922:	83 ec 0c             	sub    $0xc,%esp
c0100925:	68 02 5d 10 c0       	push   $0xc0105d02
c010092a:	e8 4e f9 ff ff       	call   c010027d <cprintf>
c010092f:	83 c4 10             	add    $0x10,%esp
    cprintf("  entry  0x%08x (phys)\n", kern_init);
c0100932:	83 ec 08             	sub    $0x8,%esp
c0100935:	68 36 00 10 c0       	push   $0xc0100036
c010093a:	68 1b 5d 10 c0       	push   $0xc0105d1b
c010093f:	e8 39 f9 ff ff       	call   c010027d <cprintf>
c0100944:	83 c4 10             	add    $0x10,%esp
    cprintf("  etext  0x%08x (phys)\n", etext);
c0100947:	83 ec 08             	sub    $0x8,%esp
c010094a:	68 f0 5b 10 c0       	push   $0xc0105bf0
c010094f:	68 33 5d 10 c0       	push   $0xc0105d33
c0100954:	e8 24 f9 ff ff       	call   c010027d <cprintf>
c0100959:	83 c4 10             	add    $0x10,%esp
    cprintf("  edata  0x%08x (phys)\n", edata);
c010095c:	83 ec 08             	sub    $0x8,%esp
c010095f:	68 00 a0 11 c0       	push   $0xc011a000
c0100964:	68 4b 5d 10 c0       	push   $0xc0105d4b
c0100969:	e8 0f f9 ff ff       	call   c010027d <cprintf>
c010096e:	83 c4 10             	add    $0x10,%esp
    cprintf("  end    0x%08x (phys)\n", end);
c0100971:	83 ec 08             	sub    $0x8,%esp
c0100974:	68 28 af 11 c0       	push   $0xc011af28
c0100979:	68 63 5d 10 c0       	push   $0xc0105d63
c010097e:	e8 fa f8 ff ff       	call   c010027d <cprintf>
c0100983:	83 c4 10             	add    $0x10,%esp
    cprintf("Kernel executable memory footprint: %dKB\n", (end - kern_init + 1023)/1024);
c0100986:	b8 28 af 11 c0       	mov    $0xc011af28,%eax
c010098b:	05 ff 03 00 00       	add    $0x3ff,%eax
c0100990:	ba 36 00 10 c0       	mov    $0xc0100036,%edx
c0100995:	29 d0                	sub    %edx,%eax
c0100997:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
c010099d:	85 c0                	test   %eax,%eax
c010099f:	0f 48 c2             	cmovs  %edx,%eax
c01009a2:	c1 f8 0a             	sar    $0xa,%eax
c01009a5:	83 ec 08             	sub    $0x8,%esp
c01009a8:	50                   	push   %eax
c01009a9:	68 7c 5d 10 c0       	push   $0xc0105d7c
c01009ae:	e8 ca f8 ff ff       	call   c010027d <cprintf>
c01009b3:	83 c4 10             	add    $0x10,%esp
}
c01009b6:	90                   	nop
c01009b7:	c9                   	leave  
c01009b8:	c3                   	ret    

c01009b9 <print_debuginfo>:
/* *
 * print_debuginfo - read and print the stat information for the address @eip,
 * and info.eip_fn_addr should be the first address of the related function.
 * */
void
print_debuginfo(uintptr_t eip) {
c01009b9:	55                   	push   %ebp
c01009ba:	89 e5                	mov    %esp,%ebp
c01009bc:	81 ec 28 01 00 00    	sub    $0x128,%esp
    struct eipdebuginfo info;
    if (debuginfo_eip(eip, &info) != 0) {
c01009c2:	83 ec 08             	sub    $0x8,%esp
c01009c5:	8d 45 dc             	lea    -0x24(%ebp),%eax
c01009c8:	50                   	push   %eax
c01009c9:	ff 75 08             	pushl  0x8(%ebp)
c01009cc:	e8 3d fc ff ff       	call   c010060e <debuginfo_eip>
c01009d1:	83 c4 10             	add    $0x10,%esp
c01009d4:	85 c0                	test   %eax,%eax
c01009d6:	74 15                	je     c01009ed <print_debuginfo+0x34>
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
c01009d8:	83 ec 08             	sub    $0x8,%esp
c01009db:	ff 75 08             	pushl  0x8(%ebp)
c01009de:	68 a6 5d 10 c0       	push   $0xc0105da6
c01009e3:	e8 95 f8 ff ff       	call   c010027d <cprintf>
c01009e8:	83 c4 10             	add    $0x10,%esp
        }
        fnname[j] = '\0';
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
                fnname, eip - info.eip_fn_addr);
    }
}
c01009eb:	eb 65                	jmp    c0100a52 <print_debuginfo+0x99>
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
c01009ed:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c01009f4:	eb 1c                	jmp    c0100a12 <print_debuginfo+0x59>
            fnname[j] = info.eip_fn_name[j];
c01009f6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01009f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01009fc:	01 d0                	add    %edx,%eax
c01009fe:	0f b6 00             	movzbl (%eax),%eax
c0100a01:	8d 8d dc fe ff ff    	lea    -0x124(%ebp),%ecx
c0100a07:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100a0a:	01 ca                	add    %ecx,%edx
c0100a0c:	88 02                	mov    %al,(%edx)
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
    }
    else {
        char fnname[256];
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
c0100a0e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0100a12:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0100a15:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0100a18:	7f dc                	jg     c01009f6 <print_debuginfo+0x3d>
            fnname[j] = info.eip_fn_name[j];
        }
        fnname[j] = '\0';
c0100a1a:	8d 95 dc fe ff ff    	lea    -0x124(%ebp),%edx
c0100a20:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100a23:	01 d0                	add    %edx,%eax
c0100a25:	c6 00 00             	movb   $0x0,(%eax)
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
                fnname, eip - info.eip_fn_addr);
c0100a28:	8b 45 ec             	mov    -0x14(%ebp),%eax
        int j;
        for (j = 0; j < info.eip_fn_namelen; j ++) {
            fnname[j] = info.eip_fn_name[j];
        }
        fnname[j] = '\0';
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
c0100a2b:	8b 55 08             	mov    0x8(%ebp),%edx
c0100a2e:	89 d1                	mov    %edx,%ecx
c0100a30:	29 c1                	sub    %eax,%ecx
c0100a32:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0100a35:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100a38:	83 ec 0c             	sub    $0xc,%esp
c0100a3b:	51                   	push   %ecx
c0100a3c:	8d 8d dc fe ff ff    	lea    -0x124(%ebp),%ecx
c0100a42:	51                   	push   %ecx
c0100a43:	52                   	push   %edx
c0100a44:	50                   	push   %eax
c0100a45:	68 c2 5d 10 c0       	push   $0xc0105dc2
c0100a4a:	e8 2e f8 ff ff       	call   c010027d <cprintf>
c0100a4f:	83 c4 20             	add    $0x20,%esp
                fnname, eip - info.eip_fn_addr);
    }
}
c0100a52:	90                   	nop
c0100a53:	c9                   	leave  
c0100a54:	c3                   	ret    

c0100a55 <read_eip>:

static __noinline uint32_t
read_eip(void) {
c0100a55:	55                   	push   %ebp
c0100a56:	89 e5                	mov    %esp,%ebp
c0100a58:	83 ec 10             	sub    $0x10,%esp
    uint32_t eip;
    asm volatile("movl 4(%%ebp), %0" : "=r" (eip));
c0100a5b:	8b 45 04             	mov    0x4(%ebp),%eax
c0100a5e:	89 45 fc             	mov    %eax,-0x4(%ebp)
    return eip;
c0100a61:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c0100a64:	c9                   	leave  
c0100a65:	c3                   	ret    

c0100a66 <print_stackframe>:
 *
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the boundary.
 * */
void
print_stackframe(void) {
c0100a66:	55                   	push   %ebp
c0100a67:	89 e5                	mov    %esp,%ebp
c0100a69:	53                   	push   %ebx
c0100a6a:	83 ec 24             	sub    $0x24,%esp
}

static inline uint32_t
read_ebp(void) {
    uint32_t ebp;
    asm volatile ("movl %%ebp, %0" : "=r" (ebp));
c0100a6d:	89 e8                	mov    %ebp,%eax
c0100a6f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    return ebp;
c0100a72:	8b 45 e4             	mov    -0x1c(%ebp),%eax
      *    (3.4) call print_debuginfo(eip-1) to print the C calling function name and line number, etc.
      *    (3.5) popup a calling stackframe
      *           NOTICE: the calling funciton's return addr eip  = ss:[ebp+4]
      *                   the calling funciton's ebp = ss:[ebp]
      */
     uint32_t ebp=read_ebp(), eip=read_eip();
c0100a75:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0100a78:	e8 d8 ff ff ff       	call   c0100a55 <read_eip>
c0100a7d:	89 45 f0             	mov    %eax,-0x10(%ebp)
     for(int i=0;i<STACKFRAME_DEPTH && ebp!=0;i++){
c0100a80:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
c0100a87:	eb 79                	jmp    c0100b02 <print_stackframe+0x9c>
     
     uint32_t* call_arguments = (uint32_t*)ebp+2;
c0100a89:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100a8c:	83 c0 08             	add    $0x8,%eax
c0100a8f:	89 45 e8             	mov    %eax,-0x18(%ebp)
     cprintf("ebp:0x%08x eip:0x%08x args:0x%08x 0x%08x 0x%08x 0x%08x",
             ebp,eip,call_arguments[0],call_arguments[1],
             call_arguments[2],call_arguments[3]);
c0100a92:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0100a95:	83 c0 0c             	add    $0xc,%eax
      */
     uint32_t ebp=read_ebp(), eip=read_eip();
     for(int i=0;i<STACKFRAME_DEPTH && ebp!=0;i++){
     
     uint32_t* call_arguments = (uint32_t*)ebp+2;
     cprintf("ebp:0x%08x eip:0x%08x args:0x%08x 0x%08x 0x%08x 0x%08x",
c0100a98:	8b 18                	mov    (%eax),%ebx
             ebp,eip,call_arguments[0],call_arguments[1],
             call_arguments[2],call_arguments[3]);
c0100a9a:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0100a9d:	83 c0 08             	add    $0x8,%eax
      */
     uint32_t ebp=read_ebp(), eip=read_eip();
     for(int i=0;i<STACKFRAME_DEPTH && ebp!=0;i++){
     
     uint32_t* call_arguments = (uint32_t*)ebp+2;
     cprintf("ebp:0x%08x eip:0x%08x args:0x%08x 0x%08x 0x%08x 0x%08x",
c0100aa0:	8b 08                	mov    (%eax),%ecx
             ebp,eip,call_arguments[0],call_arguments[1],
c0100aa2:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0100aa5:	83 c0 04             	add    $0x4,%eax
      */
     uint32_t ebp=read_ebp(), eip=read_eip();
     for(int i=0;i<STACKFRAME_DEPTH && ebp!=0;i++){
     
     uint32_t* call_arguments = (uint32_t*)ebp+2;
     cprintf("ebp:0x%08x eip:0x%08x args:0x%08x 0x%08x 0x%08x 0x%08x",
c0100aa8:	8b 10                	mov    (%eax),%edx
c0100aaa:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0100aad:	8b 00                	mov    (%eax),%eax
c0100aaf:	83 ec 04             	sub    $0x4,%esp
c0100ab2:	53                   	push   %ebx
c0100ab3:	51                   	push   %ecx
c0100ab4:	52                   	push   %edx
c0100ab5:	50                   	push   %eax
c0100ab6:	ff 75 f0             	pushl  -0x10(%ebp)
c0100ab9:	ff 75 f4             	pushl  -0xc(%ebp)
c0100abc:	68 d4 5d 10 c0       	push   $0xc0105dd4
c0100ac1:	e8 b7 f7 ff ff       	call   c010027d <cprintf>
c0100ac6:	83 c4 20             	add    $0x20,%esp
             ebp,eip,call_arguments[0],call_arguments[1],
             call_arguments[2],call_arguments[3]);
     cprintf("\n");
c0100ac9:	83 ec 0c             	sub    $0xc,%esp
c0100acc:	68 0b 5e 10 c0       	push   $0xc0105e0b
c0100ad1:	e8 a7 f7 ff ff       	call   c010027d <cprintf>
c0100ad6:	83 c4 10             	add    $0x10,%esp
     print_debuginfo(eip-1);
c0100ad9:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100adc:	83 e8 01             	sub    $0x1,%eax
c0100adf:	83 ec 0c             	sub    $0xc,%esp
c0100ae2:	50                   	push   %eax
c0100ae3:	e8 d1 fe ff ff       	call   c01009b9 <print_debuginfo>
c0100ae8:	83 c4 10             	add    $0x10,%esp
     eip=*(((uint32_t*)ebp)+1);
c0100aeb:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100aee:	83 c0 04             	add    $0x4,%eax
c0100af1:	8b 00                	mov    (%eax),%eax
c0100af3:	89 45 f0             	mov    %eax,-0x10(%ebp)
     ebp=*((uint32_t*)ebp);
c0100af6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100af9:	8b 00                	mov    (%eax),%eax
c0100afb:	89 45 f4             	mov    %eax,-0xc(%ebp)
      *    (3.5) popup a calling stackframe
      *           NOTICE: the calling funciton's return addr eip  = ss:[ebp+4]
      *                   the calling funciton's ebp = ss:[ebp]
      */
     uint32_t ebp=read_ebp(), eip=read_eip();
     for(int i=0;i<STACKFRAME_DEPTH && ebp!=0;i++){
c0100afe:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
c0100b02:	83 7d ec 13          	cmpl   $0x13,-0x14(%ebp)
c0100b06:	7f 0a                	jg     c0100b12 <print_stackframe+0xac>
c0100b08:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0100b0c:	0f 85 77 ff ff ff    	jne    c0100a89 <print_stackframe+0x23>
     cprintf("\n");
     print_debuginfo(eip-1);
     eip=*(((uint32_t*)ebp)+1);
     ebp=*((uint32_t*)ebp);
     } 
}
c0100b12:	90                   	nop
c0100b13:	8b 5d fc             	mov    -0x4(%ebp),%ebx
c0100b16:	c9                   	leave  
c0100b17:	c3                   	ret    

c0100b18 <parse>:
#define MAXARGS         16
#define WHITESPACE      " \t\n\r"

/* parse - parse the command buffer into whitespace-separated arguments */
static int
parse(char *buf, char **argv) {
c0100b18:	55                   	push   %ebp
c0100b19:	89 e5                	mov    %esp,%ebp
c0100b1b:	83 ec 18             	sub    $0x18,%esp
    int argc = 0;
c0100b1e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
c0100b25:	eb 0c                	jmp    c0100b33 <parse+0x1b>
            *buf ++ = '\0';
c0100b27:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b2a:	8d 50 01             	lea    0x1(%eax),%edx
c0100b2d:	89 55 08             	mov    %edx,0x8(%ebp)
c0100b30:	c6 00 00             	movb   $0x0,(%eax)
static int
parse(char *buf, char **argv) {
    int argc = 0;
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
c0100b33:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b36:	0f b6 00             	movzbl (%eax),%eax
c0100b39:	84 c0                	test   %al,%al
c0100b3b:	74 1e                	je     c0100b5b <parse+0x43>
c0100b3d:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b40:	0f b6 00             	movzbl (%eax),%eax
c0100b43:	0f be c0             	movsbl %al,%eax
c0100b46:	83 ec 08             	sub    $0x8,%esp
c0100b49:	50                   	push   %eax
c0100b4a:	68 90 5e 10 c0       	push   $0xc0105e90
c0100b4f:	e8 46 47 00 00       	call   c010529a <strchr>
c0100b54:	83 c4 10             	add    $0x10,%esp
c0100b57:	85 c0                	test   %eax,%eax
c0100b59:	75 cc                	jne    c0100b27 <parse+0xf>
            *buf ++ = '\0';
        }
        if (*buf == '\0') {
c0100b5b:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b5e:	0f b6 00             	movzbl (%eax),%eax
c0100b61:	84 c0                	test   %al,%al
c0100b63:	74 69                	je     c0100bce <parse+0xb6>
            break;
        }

        // save and scan past next arg
        if (argc == MAXARGS - 1) {
c0100b65:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
c0100b69:	75 12                	jne    c0100b7d <parse+0x65>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
c0100b6b:	83 ec 08             	sub    $0x8,%esp
c0100b6e:	6a 10                	push   $0x10
c0100b70:	68 95 5e 10 c0       	push   $0xc0105e95
c0100b75:	e8 03 f7 ff ff       	call   c010027d <cprintf>
c0100b7a:	83 c4 10             	add    $0x10,%esp
        }
        argv[argc ++] = buf;
c0100b7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100b80:	8d 50 01             	lea    0x1(%eax),%edx
c0100b83:	89 55 f4             	mov    %edx,-0xc(%ebp)
c0100b86:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0100b8d:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100b90:	01 c2                	add    %eax,%edx
c0100b92:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b95:	89 02                	mov    %eax,(%edx)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
c0100b97:	eb 04                	jmp    c0100b9d <parse+0x85>
            buf ++;
c0100b99:	83 45 08 01          	addl   $0x1,0x8(%ebp)
        // save and scan past next arg
        if (argc == MAXARGS - 1) {
            cprintf("Too many arguments (max %d).\n", MAXARGS);
        }
        argv[argc ++] = buf;
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
c0100b9d:	8b 45 08             	mov    0x8(%ebp),%eax
c0100ba0:	0f b6 00             	movzbl (%eax),%eax
c0100ba3:	84 c0                	test   %al,%al
c0100ba5:	0f 84 7a ff ff ff    	je     c0100b25 <parse+0xd>
c0100bab:	8b 45 08             	mov    0x8(%ebp),%eax
c0100bae:	0f b6 00             	movzbl (%eax),%eax
c0100bb1:	0f be c0             	movsbl %al,%eax
c0100bb4:	83 ec 08             	sub    $0x8,%esp
c0100bb7:	50                   	push   %eax
c0100bb8:	68 90 5e 10 c0       	push   $0xc0105e90
c0100bbd:	e8 d8 46 00 00       	call   c010529a <strchr>
c0100bc2:	83 c4 10             	add    $0x10,%esp
c0100bc5:	85 c0                	test   %eax,%eax
c0100bc7:	74 d0                	je     c0100b99 <parse+0x81>
            buf ++;
        }
    }
c0100bc9:	e9 57 ff ff ff       	jmp    c0100b25 <parse+0xd>
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
            *buf ++ = '\0';
        }
        if (*buf == '\0') {
            break;
c0100bce:	90                   	nop
        argv[argc ++] = buf;
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
            buf ++;
        }
    }
    return argc;
c0100bcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0100bd2:	c9                   	leave  
c0100bd3:	c3                   	ret    

c0100bd4 <runcmd>:
/* *
 * runcmd - parse the input string, split it into separated arguments
 * and then lookup and invoke some related commands/
 * */
static int
runcmd(char *buf, struct trapframe *tf) {
c0100bd4:	55                   	push   %ebp
c0100bd5:	89 e5                	mov    %esp,%ebp
c0100bd7:	83 ec 58             	sub    $0x58,%esp
    char *argv[MAXARGS];
    int argc = parse(buf, argv);
c0100bda:	83 ec 08             	sub    $0x8,%esp
c0100bdd:	8d 45 b0             	lea    -0x50(%ebp),%eax
c0100be0:	50                   	push   %eax
c0100be1:	ff 75 08             	pushl  0x8(%ebp)
c0100be4:	e8 2f ff ff ff       	call   c0100b18 <parse>
c0100be9:	83 c4 10             	add    $0x10,%esp
c0100bec:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if (argc == 0) {
c0100bef:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0100bf3:	75 0a                	jne    c0100bff <runcmd+0x2b>
        return 0;
c0100bf5:	b8 00 00 00 00       	mov    $0x0,%eax
c0100bfa:	e9 83 00 00 00       	jmp    c0100c82 <runcmd+0xae>
    }
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100bff:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0100c06:	eb 59                	jmp    c0100c61 <runcmd+0x8d>
        if (strcmp(commands[i].name, argv[0]) == 0) {
c0100c08:	8b 4d b0             	mov    -0x50(%ebp),%ecx
c0100c0b:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100c0e:	89 d0                	mov    %edx,%eax
c0100c10:	01 c0                	add    %eax,%eax
c0100c12:	01 d0                	add    %edx,%eax
c0100c14:	c1 e0 02             	shl    $0x2,%eax
c0100c17:	05 00 70 11 c0       	add    $0xc0117000,%eax
c0100c1c:	8b 00                	mov    (%eax),%eax
c0100c1e:	83 ec 08             	sub    $0x8,%esp
c0100c21:	51                   	push   %ecx
c0100c22:	50                   	push   %eax
c0100c23:	e8 d2 45 00 00       	call   c01051fa <strcmp>
c0100c28:	83 c4 10             	add    $0x10,%esp
c0100c2b:	85 c0                	test   %eax,%eax
c0100c2d:	75 2e                	jne    c0100c5d <runcmd+0x89>
            return commands[i].func(argc - 1, argv + 1, tf);
c0100c2f:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100c32:	89 d0                	mov    %edx,%eax
c0100c34:	01 c0                	add    %eax,%eax
c0100c36:	01 d0                	add    %edx,%eax
c0100c38:	c1 e0 02             	shl    $0x2,%eax
c0100c3b:	05 08 70 11 c0       	add    $0xc0117008,%eax
c0100c40:	8b 10                	mov    (%eax),%edx
c0100c42:	8d 45 b0             	lea    -0x50(%ebp),%eax
c0100c45:	83 c0 04             	add    $0x4,%eax
c0100c48:	8b 4d f0             	mov    -0x10(%ebp),%ecx
c0100c4b:	83 e9 01             	sub    $0x1,%ecx
c0100c4e:	83 ec 04             	sub    $0x4,%esp
c0100c51:	ff 75 0c             	pushl  0xc(%ebp)
c0100c54:	50                   	push   %eax
c0100c55:	51                   	push   %ecx
c0100c56:	ff d2                	call   *%edx
c0100c58:	83 c4 10             	add    $0x10,%esp
c0100c5b:	eb 25                	jmp    c0100c82 <runcmd+0xae>
    int argc = parse(buf, argv);
    if (argc == 0) {
        return 0;
    }
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100c5d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0100c61:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100c64:	83 f8 02             	cmp    $0x2,%eax
c0100c67:	76 9f                	jbe    c0100c08 <runcmd+0x34>
        if (strcmp(commands[i].name, argv[0]) == 0) {
            return commands[i].func(argc - 1, argv + 1, tf);
        }
    }
    cprintf("Unknown command '%s'\n", argv[0]);
c0100c69:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0100c6c:	83 ec 08             	sub    $0x8,%esp
c0100c6f:	50                   	push   %eax
c0100c70:	68 b3 5e 10 c0       	push   $0xc0105eb3
c0100c75:	e8 03 f6 ff ff       	call   c010027d <cprintf>
c0100c7a:	83 c4 10             	add    $0x10,%esp
    return 0;
c0100c7d:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100c82:	c9                   	leave  
c0100c83:	c3                   	ret    

c0100c84 <kmonitor>:

/***** Implementations of basic kernel monitor commands *****/

void
kmonitor(struct trapframe *tf) {
c0100c84:	55                   	push   %ebp
c0100c85:	89 e5                	mov    %esp,%ebp
c0100c87:	83 ec 18             	sub    $0x18,%esp
    cprintf("Welcome to the kernel debug monitor!!\n");
c0100c8a:	83 ec 0c             	sub    $0xc,%esp
c0100c8d:	68 cc 5e 10 c0       	push   $0xc0105ecc
c0100c92:	e8 e6 f5 ff ff       	call   c010027d <cprintf>
c0100c97:	83 c4 10             	add    $0x10,%esp
    cprintf("Type 'help' for a list of commands.\n");
c0100c9a:	83 ec 0c             	sub    $0xc,%esp
c0100c9d:	68 f4 5e 10 c0       	push   $0xc0105ef4
c0100ca2:	e8 d6 f5 ff ff       	call   c010027d <cprintf>
c0100ca7:	83 c4 10             	add    $0x10,%esp

    if (tf != NULL) {
c0100caa:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0100cae:	74 0e                	je     c0100cbe <kmonitor+0x3a>
        print_trapframe(tf);
c0100cb0:	83 ec 0c             	sub    $0xc,%esp
c0100cb3:	ff 75 08             	pushl  0x8(%ebp)
c0100cb6:	e8 9b 0d 00 00       	call   c0101a56 <print_trapframe>
c0100cbb:	83 c4 10             	add    $0x10,%esp
    }

    char *buf;
    while (1) {
        if ((buf = readline("K> ")) != NULL) {
c0100cbe:	83 ec 0c             	sub    $0xc,%esp
c0100cc1:	68 19 5f 10 c0       	push   $0xc0105f19
c0100cc6:	e8 56 f6 ff ff       	call   c0100321 <readline>
c0100ccb:	83 c4 10             	add    $0x10,%esp
c0100cce:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0100cd1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0100cd5:	74 e7                	je     c0100cbe <kmonitor+0x3a>
            if (runcmd(buf, tf) < 0) {
c0100cd7:	83 ec 08             	sub    $0x8,%esp
c0100cda:	ff 75 08             	pushl  0x8(%ebp)
c0100cdd:	ff 75 f4             	pushl  -0xc(%ebp)
c0100ce0:	e8 ef fe ff ff       	call   c0100bd4 <runcmd>
c0100ce5:	83 c4 10             	add    $0x10,%esp
c0100ce8:	85 c0                	test   %eax,%eax
c0100cea:	78 02                	js     c0100cee <kmonitor+0x6a>
                break;
            }
        }
    }
c0100cec:	eb d0                	jmp    c0100cbe <kmonitor+0x3a>

    char *buf;
    while (1) {
        if ((buf = readline("K> ")) != NULL) {
            if (runcmd(buf, tf) < 0) {
                break;
c0100cee:	90                   	nop
            }
        }
    }
}
c0100cef:	90                   	nop
c0100cf0:	c9                   	leave  
c0100cf1:	c3                   	ret    

c0100cf2 <mon_help>:

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
c0100cf2:	55                   	push   %ebp
c0100cf3:	89 e5                	mov    %esp,%ebp
c0100cf5:	83 ec 18             	sub    $0x18,%esp
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100cf8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0100cff:	eb 3c                	jmp    c0100d3d <mon_help+0x4b>
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
c0100d01:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100d04:	89 d0                	mov    %edx,%eax
c0100d06:	01 c0                	add    %eax,%eax
c0100d08:	01 d0                	add    %edx,%eax
c0100d0a:	c1 e0 02             	shl    $0x2,%eax
c0100d0d:	05 04 70 11 c0       	add    $0xc0117004,%eax
c0100d12:	8b 08                	mov    (%eax),%ecx
c0100d14:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100d17:	89 d0                	mov    %edx,%eax
c0100d19:	01 c0                	add    %eax,%eax
c0100d1b:	01 d0                	add    %edx,%eax
c0100d1d:	c1 e0 02             	shl    $0x2,%eax
c0100d20:	05 00 70 11 c0       	add    $0xc0117000,%eax
c0100d25:	8b 00                	mov    (%eax),%eax
c0100d27:	83 ec 04             	sub    $0x4,%esp
c0100d2a:	51                   	push   %ecx
c0100d2b:	50                   	push   %eax
c0100d2c:	68 1d 5f 10 c0       	push   $0xc0105f1d
c0100d31:	e8 47 f5 ff ff       	call   c010027d <cprintf>
c0100d36:	83 c4 10             	add    $0x10,%esp

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100d39:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0100d3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100d40:	83 f8 02             	cmp    $0x2,%eax
c0100d43:	76 bc                	jbe    c0100d01 <mon_help+0xf>
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
    }
    return 0;
c0100d45:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100d4a:	c9                   	leave  
c0100d4b:	c3                   	ret    

c0100d4c <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
c0100d4c:	55                   	push   %ebp
c0100d4d:	89 e5                	mov    %esp,%ebp
c0100d4f:	83 ec 08             	sub    $0x8,%esp
    print_kerninfo();
c0100d52:	e8 c5 fb ff ff       	call   c010091c <print_kerninfo>
    return 0;
c0100d57:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100d5c:	c9                   	leave  
c0100d5d:	c3                   	ret    

c0100d5e <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
c0100d5e:	55                   	push   %ebp
c0100d5f:	89 e5                	mov    %esp,%ebp
c0100d61:	83 ec 08             	sub    $0x8,%esp
    print_stackframe();
c0100d64:	e8 fd fc ff ff       	call   c0100a66 <print_stackframe>
    return 0;
c0100d69:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100d6e:	c9                   	leave  
c0100d6f:	c3                   	ret    

c0100d70 <clock_init>:
/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void
clock_init(void) {
c0100d70:	55                   	push   %ebp
c0100d71:	89 e5                	mov    %esp,%ebp
c0100d73:	83 ec 18             	sub    $0x18,%esp
c0100d76:	66 c7 45 f6 43 00    	movw   $0x43,-0xa(%ebp)
c0100d7c:	c6 45 ef 34          	movb   $0x34,-0x11(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100d80:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
c0100d84:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0100d88:	ee                   	out    %al,(%dx)
c0100d89:	66 c7 45 f4 40 00    	movw   $0x40,-0xc(%ebp)
c0100d8f:	c6 45 f0 9c          	movb   $0x9c,-0x10(%ebp)
c0100d93:	0f b6 45 f0          	movzbl -0x10(%ebp),%eax
c0100d97:	0f b7 55 f4          	movzwl -0xc(%ebp),%edx
c0100d9b:	ee                   	out    %al,(%dx)
c0100d9c:	66 c7 45 f2 40 00    	movw   $0x40,-0xe(%ebp)
c0100da2:	c6 45 f1 2e          	movb   $0x2e,-0xf(%ebp)
c0100da6:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c0100daa:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0100dae:	ee                   	out    %al,(%dx)
    outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
    outb(IO_TIMER1, TIMER_DIV(100) % 256);
    outb(IO_TIMER1, TIMER_DIV(100) / 256);

    // initialize time counter 'ticks' to zero
    ticks = 0;
c0100daf:	c7 05 0c af 11 c0 00 	movl   $0x0,0xc011af0c
c0100db6:	00 00 00 

    cprintf("++ setup timer interrupts\n");
c0100db9:	83 ec 0c             	sub    $0xc,%esp
c0100dbc:	68 26 5f 10 c0       	push   $0xc0105f26
c0100dc1:	e8 b7 f4 ff ff       	call   c010027d <cprintf>
c0100dc6:	83 c4 10             	add    $0x10,%esp
    pic_enable(IRQ_TIMER);
c0100dc9:	83 ec 0c             	sub    $0xc,%esp
c0100dcc:	6a 00                	push   $0x0
c0100dce:	e8 3b 09 00 00       	call   c010170e <pic_enable>
c0100dd3:	83 c4 10             	add    $0x10,%esp
}
c0100dd6:	90                   	nop
c0100dd7:	c9                   	leave  
c0100dd8:	c3                   	ret    

c0100dd9 <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
c0100dd9:	55                   	push   %ebp
c0100dda:	89 e5                	mov    %esp,%ebp
c0100ddc:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
c0100ddf:	9c                   	pushf  
c0100de0:	58                   	pop    %eax
c0100de1:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
c0100de4:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
c0100de7:	25 00 02 00 00       	and    $0x200,%eax
c0100dec:	85 c0                	test   %eax,%eax
c0100dee:	74 0c                	je     c0100dfc <__intr_save+0x23>
        intr_disable();
c0100df0:	e8 8a 0a 00 00       	call   c010187f <intr_disable>
        return 1;
c0100df5:	b8 01 00 00 00       	mov    $0x1,%eax
c0100dfa:	eb 05                	jmp    c0100e01 <__intr_save+0x28>
    }
    return 0;
c0100dfc:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100e01:	c9                   	leave  
c0100e02:	c3                   	ret    

c0100e03 <__intr_restore>:

static inline void
__intr_restore(bool flag) {
c0100e03:	55                   	push   %ebp
c0100e04:	89 e5                	mov    %esp,%ebp
c0100e06:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
c0100e09:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0100e0d:	74 05                	je     c0100e14 <__intr_restore+0x11>
        intr_enable();
c0100e0f:	e8 64 0a 00 00       	call   c0101878 <intr_enable>
    }
}
c0100e14:	90                   	nop
c0100e15:	c9                   	leave  
c0100e16:	c3                   	ret    

c0100e17 <delay>:
#include <memlayout.h>
#include <sync.h>

/* stupid I/O delay routine necessitated by historical PC design flaws */
static void
delay(void) {
c0100e17:	55                   	push   %ebp
c0100e18:	89 e5                	mov    %esp,%ebp
c0100e1a:	83 ec 10             	sub    $0x10,%esp
c0100e1d:	66 c7 45 fe 84 00    	movw   $0x84,-0x2(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100e23:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
c0100e27:	89 c2                	mov    %eax,%edx
c0100e29:	ec                   	in     (%dx),%al
c0100e2a:	88 45 f4             	mov    %al,-0xc(%ebp)
c0100e2d:	66 c7 45 fc 84 00    	movw   $0x84,-0x4(%ebp)
c0100e33:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
c0100e37:	89 c2                	mov    %eax,%edx
c0100e39:	ec                   	in     (%dx),%al
c0100e3a:	88 45 f5             	mov    %al,-0xb(%ebp)
c0100e3d:	66 c7 45 fa 84 00    	movw   $0x84,-0x6(%ebp)
c0100e43:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
c0100e47:	89 c2                	mov    %eax,%edx
c0100e49:	ec                   	in     (%dx),%al
c0100e4a:	88 45 f6             	mov    %al,-0xa(%ebp)
c0100e4d:	66 c7 45 f8 84 00    	movw   $0x84,-0x8(%ebp)
c0100e53:	0f b7 45 f8          	movzwl -0x8(%ebp),%eax
c0100e57:	89 c2                	mov    %eax,%edx
c0100e59:	ec                   	in     (%dx),%al
c0100e5a:	88 45 f7             	mov    %al,-0x9(%ebp)
    inb(0x84);
    inb(0x84);
    inb(0x84);
    inb(0x84);
}
c0100e5d:	90                   	nop
c0100e5e:	c9                   	leave  
c0100e5f:	c3                   	ret    

c0100e60 <cga_init>:
static uint16_t addr_6845;

/* TEXT-mode CGA/VGA display output */

static void
cga_init(void) {
c0100e60:	55                   	push   %ebp
c0100e61:	89 e5                	mov    %esp,%ebp
c0100e63:	83 ec 20             	sub    $0x20,%esp
    volatile uint16_t *cp = (uint16_t *)(CGA_BUF + KERNBASE);
c0100e66:	c7 45 fc 00 80 0b c0 	movl   $0xc00b8000,-0x4(%ebp)
    uint16_t was = *cp;
c0100e6d:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100e70:	0f b7 00             	movzwl (%eax),%eax
c0100e73:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
    *cp = (uint16_t) 0xA55A;
c0100e77:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100e7a:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
    if (*cp != 0xA55A) {
c0100e7f:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100e82:	0f b7 00             	movzwl (%eax),%eax
c0100e85:	66 3d 5a a5          	cmp    $0xa55a,%ax
c0100e89:	74 12                	je     c0100e9d <cga_init+0x3d>
        cp = (uint16_t*)(MONO_BUF + KERNBASE);
c0100e8b:	c7 45 fc 00 00 0b c0 	movl   $0xc00b0000,-0x4(%ebp)
        addr_6845 = MONO_BASE;
c0100e92:	66 c7 05 46 a4 11 c0 	movw   $0x3b4,0xc011a446
c0100e99:	b4 03 
c0100e9b:	eb 13                	jmp    c0100eb0 <cga_init+0x50>
    } else {
        *cp = was;
c0100e9d:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100ea0:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c0100ea4:	66 89 10             	mov    %dx,(%eax)
        addr_6845 = CGA_BASE;
c0100ea7:	66 c7 05 46 a4 11 c0 	movw   $0x3d4,0xc011a446
c0100eae:	d4 03 
    }

    // Extract cursor location
    uint32_t pos;
    outb(addr_6845, 14);
c0100eb0:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c0100eb7:	0f b7 c0             	movzwl %ax,%eax
c0100eba:	66 89 45 f8          	mov    %ax,-0x8(%ebp)
c0100ebe:	c6 45 ea 0e          	movb   $0xe,-0x16(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100ec2:	0f b6 45 ea          	movzbl -0x16(%ebp),%eax
c0100ec6:	0f b7 55 f8          	movzwl -0x8(%ebp),%edx
c0100eca:	ee                   	out    %al,(%dx)
    pos = inb(addr_6845 + 1) << 8;
c0100ecb:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c0100ed2:	83 c0 01             	add    $0x1,%eax
c0100ed5:	0f b7 c0             	movzwl %ax,%eax
c0100ed8:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100edc:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c0100ee0:	89 c2                	mov    %eax,%edx
c0100ee2:	ec                   	in     (%dx),%al
c0100ee3:	88 45 eb             	mov    %al,-0x15(%ebp)
    return data;
c0100ee6:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
c0100eea:	0f b6 c0             	movzbl %al,%eax
c0100eed:	c1 e0 08             	shl    $0x8,%eax
c0100ef0:	89 45 f4             	mov    %eax,-0xc(%ebp)
    outb(addr_6845, 15);
c0100ef3:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c0100efa:	0f b7 c0             	movzwl %ax,%eax
c0100efd:	66 89 45 f0          	mov    %ax,-0x10(%ebp)
c0100f01:	c6 45 ec 0f          	movb   $0xf,-0x14(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100f05:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
c0100f09:	0f b7 55 f0          	movzwl -0x10(%ebp),%edx
c0100f0d:	ee                   	out    %al,(%dx)
    pos |= inb(addr_6845 + 1);
c0100f0e:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c0100f15:	83 c0 01             	add    $0x1,%eax
c0100f18:	0f b7 c0             	movzwl %ax,%eax
c0100f1b:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100f1f:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
c0100f23:	89 c2                	mov    %eax,%edx
c0100f25:	ec                   	in     (%dx),%al
c0100f26:	88 45 ed             	mov    %al,-0x13(%ebp)
    return data;
c0100f29:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
c0100f2d:	0f b6 c0             	movzbl %al,%eax
c0100f30:	09 45 f4             	or     %eax,-0xc(%ebp)

    crt_buf = (uint16_t*) cp;
c0100f33:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100f36:	a3 40 a4 11 c0       	mov    %eax,0xc011a440
    crt_pos = pos;
c0100f3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100f3e:	66 a3 44 a4 11 c0    	mov    %ax,0xc011a444
}
c0100f44:	90                   	nop
c0100f45:	c9                   	leave  
c0100f46:	c3                   	ret    

c0100f47 <serial_init>:

static bool serial_exists = 0;

static void
serial_init(void) {
c0100f47:	55                   	push   %ebp
c0100f48:	89 e5                	mov    %esp,%ebp
c0100f4a:	83 ec 28             	sub    $0x28,%esp
c0100f4d:	66 c7 45 f6 fa 03    	movw   $0x3fa,-0xa(%ebp)
c0100f53:	c6 45 da 00          	movb   $0x0,-0x26(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100f57:	0f b6 45 da          	movzbl -0x26(%ebp),%eax
c0100f5b:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0100f5f:	ee                   	out    %al,(%dx)
c0100f60:	66 c7 45 f4 fb 03    	movw   $0x3fb,-0xc(%ebp)
c0100f66:	c6 45 db 80          	movb   $0x80,-0x25(%ebp)
c0100f6a:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
c0100f6e:	0f b7 55 f4          	movzwl -0xc(%ebp),%edx
c0100f72:	ee                   	out    %al,(%dx)
c0100f73:	66 c7 45 f2 f8 03    	movw   $0x3f8,-0xe(%ebp)
c0100f79:	c6 45 dc 0c          	movb   $0xc,-0x24(%ebp)
c0100f7d:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
c0100f81:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0100f85:	ee                   	out    %al,(%dx)
c0100f86:	66 c7 45 f0 f9 03    	movw   $0x3f9,-0x10(%ebp)
c0100f8c:	c6 45 dd 00          	movb   $0x0,-0x23(%ebp)
c0100f90:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
c0100f94:	0f b7 55 f0          	movzwl -0x10(%ebp),%edx
c0100f98:	ee                   	out    %al,(%dx)
c0100f99:	66 c7 45 ee fb 03    	movw   $0x3fb,-0x12(%ebp)
c0100f9f:	c6 45 de 03          	movb   $0x3,-0x22(%ebp)
c0100fa3:	0f b6 45 de          	movzbl -0x22(%ebp),%eax
c0100fa7:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c0100fab:	ee                   	out    %al,(%dx)
c0100fac:	66 c7 45 ec fc 03    	movw   $0x3fc,-0x14(%ebp)
c0100fb2:	c6 45 df 00          	movb   $0x0,-0x21(%ebp)
c0100fb6:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
c0100fba:	0f b7 55 ec          	movzwl -0x14(%ebp),%edx
c0100fbe:	ee                   	out    %al,(%dx)
c0100fbf:	66 c7 45 ea f9 03    	movw   $0x3f9,-0x16(%ebp)
c0100fc5:	c6 45 e0 01          	movb   $0x1,-0x20(%ebp)
c0100fc9:	0f b6 45 e0          	movzbl -0x20(%ebp),%eax
c0100fcd:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
c0100fd1:	ee                   	out    %al,(%dx)
c0100fd2:	66 c7 45 e8 fd 03    	movw   $0x3fd,-0x18(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100fd8:	0f b7 45 e8          	movzwl -0x18(%ebp),%eax
c0100fdc:	89 c2                	mov    %eax,%edx
c0100fde:	ec                   	in     (%dx),%al
c0100fdf:	88 45 e1             	mov    %al,-0x1f(%ebp)
    return data;
c0100fe2:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
    // Enable rcv interrupts
    outb(COM1 + COM_IER, COM_IER_RDI);

    // Clear any preexisting overrun indications and interrupts
    // Serial port doesn't exist if COM_LSR returns 0xFF
    serial_exists = (inb(COM1 + COM_LSR) != 0xFF);
c0100fe6:	3c ff                	cmp    $0xff,%al
c0100fe8:	0f 95 c0             	setne  %al
c0100feb:	0f b6 c0             	movzbl %al,%eax
c0100fee:	a3 48 a4 11 c0       	mov    %eax,0xc011a448
c0100ff3:	66 c7 45 e6 fa 03    	movw   $0x3fa,-0x1a(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100ff9:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax
c0100ffd:	89 c2                	mov    %eax,%edx
c0100fff:	ec                   	in     (%dx),%al
c0101000:	88 45 e2             	mov    %al,-0x1e(%ebp)
c0101003:	66 c7 45 e4 f8 03    	movw   $0x3f8,-0x1c(%ebp)
c0101009:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
c010100d:	89 c2                	mov    %eax,%edx
c010100f:	ec                   	in     (%dx),%al
c0101010:	88 45 e3             	mov    %al,-0x1d(%ebp)
    (void) inb(COM1+COM_IIR);
    (void) inb(COM1+COM_RX);

    if (serial_exists) {
c0101013:	a1 48 a4 11 c0       	mov    0xc011a448,%eax
c0101018:	85 c0                	test   %eax,%eax
c010101a:	74 0d                	je     c0101029 <serial_init+0xe2>
        pic_enable(IRQ_COM1);
c010101c:	83 ec 0c             	sub    $0xc,%esp
c010101f:	6a 04                	push   $0x4
c0101021:	e8 e8 06 00 00       	call   c010170e <pic_enable>
c0101026:	83 c4 10             	add    $0x10,%esp
    }
}
c0101029:	90                   	nop
c010102a:	c9                   	leave  
c010102b:	c3                   	ret    

c010102c <lpt_putc_sub>:

static void
lpt_putc_sub(int c) {
c010102c:	55                   	push   %ebp
c010102d:	89 e5                	mov    %esp,%ebp
c010102f:	83 ec 10             	sub    $0x10,%esp
    int i;
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
c0101032:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c0101039:	eb 09                	jmp    c0101044 <lpt_putc_sub+0x18>
        delay();
c010103b:	e8 d7 fd ff ff       	call   c0100e17 <delay>
}

static void
lpt_putc_sub(int c) {
    int i;
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
c0101040:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c0101044:	66 c7 45 f4 79 03    	movw   $0x379,-0xc(%ebp)
c010104a:	0f b7 45 f4          	movzwl -0xc(%ebp),%eax
c010104e:	89 c2                	mov    %eax,%edx
c0101050:	ec                   	in     (%dx),%al
c0101051:	88 45 f3             	mov    %al,-0xd(%ebp)
    return data;
c0101054:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101058:	84 c0                	test   %al,%al
c010105a:	78 09                	js     c0101065 <lpt_putc_sub+0x39>
c010105c:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
c0101063:	7e d6                	jle    c010103b <lpt_putc_sub+0xf>
        delay();
    }
    outb(LPTPORT + 0, c);
c0101065:	8b 45 08             	mov    0x8(%ebp),%eax
c0101068:	0f b6 c0             	movzbl %al,%eax
c010106b:	66 c7 45 f8 78 03    	movw   $0x378,-0x8(%ebp)
c0101071:	88 45 f0             	mov    %al,-0x10(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0101074:	0f b6 45 f0          	movzbl -0x10(%ebp),%eax
c0101078:	0f b7 55 f8          	movzwl -0x8(%ebp),%edx
c010107c:	ee                   	out    %al,(%dx)
c010107d:	66 c7 45 f6 7a 03    	movw   $0x37a,-0xa(%ebp)
c0101083:	c6 45 f1 0d          	movb   $0xd,-0xf(%ebp)
c0101087:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c010108b:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c010108f:	ee                   	out    %al,(%dx)
c0101090:	66 c7 45 fa 7a 03    	movw   $0x37a,-0x6(%ebp)
c0101096:	c6 45 f2 08          	movb   $0x8,-0xe(%ebp)
c010109a:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
c010109e:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c01010a2:	ee                   	out    %al,(%dx)
    outb(LPTPORT + 2, 0x08 | 0x04 | 0x01);
    outb(LPTPORT + 2, 0x08);
}
c01010a3:	90                   	nop
c01010a4:	c9                   	leave  
c01010a5:	c3                   	ret    

c01010a6 <lpt_putc>:

/* lpt_putc - copy console output to parallel port */
static void
lpt_putc(int c) {
c01010a6:	55                   	push   %ebp
c01010a7:	89 e5                	mov    %esp,%ebp
    if (c != '\b') {
c01010a9:	83 7d 08 08          	cmpl   $0x8,0x8(%ebp)
c01010ad:	74 0d                	je     c01010bc <lpt_putc+0x16>
        lpt_putc_sub(c);
c01010af:	ff 75 08             	pushl  0x8(%ebp)
c01010b2:	e8 75 ff ff ff       	call   c010102c <lpt_putc_sub>
c01010b7:	83 c4 04             	add    $0x4,%esp
    else {
        lpt_putc_sub('\b');
        lpt_putc_sub(' ');
        lpt_putc_sub('\b');
    }
}
c01010ba:	eb 1e                	jmp    c01010da <lpt_putc+0x34>
lpt_putc(int c) {
    if (c != '\b') {
        lpt_putc_sub(c);
    }
    else {
        lpt_putc_sub('\b');
c01010bc:	6a 08                	push   $0x8
c01010be:	e8 69 ff ff ff       	call   c010102c <lpt_putc_sub>
c01010c3:	83 c4 04             	add    $0x4,%esp
        lpt_putc_sub(' ');
c01010c6:	6a 20                	push   $0x20
c01010c8:	e8 5f ff ff ff       	call   c010102c <lpt_putc_sub>
c01010cd:	83 c4 04             	add    $0x4,%esp
        lpt_putc_sub('\b');
c01010d0:	6a 08                	push   $0x8
c01010d2:	e8 55 ff ff ff       	call   c010102c <lpt_putc_sub>
c01010d7:	83 c4 04             	add    $0x4,%esp
    }
}
c01010da:	90                   	nop
c01010db:	c9                   	leave  
c01010dc:	c3                   	ret    

c01010dd <cga_putc>:

/* cga_putc - print character to console */
static void
cga_putc(int c) {
c01010dd:	55                   	push   %ebp
c01010de:	89 e5                	mov    %esp,%ebp
c01010e0:	53                   	push   %ebx
c01010e1:	83 ec 14             	sub    $0x14,%esp
    // set black on white
    if (!(c & ~0xFF)) {
c01010e4:	8b 45 08             	mov    0x8(%ebp),%eax
c01010e7:	b0 00                	mov    $0x0,%al
c01010e9:	85 c0                	test   %eax,%eax
c01010eb:	75 07                	jne    c01010f4 <cga_putc+0x17>
        c |= 0x0700;
c01010ed:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)
    }

    switch (c & 0xff) {
c01010f4:	8b 45 08             	mov    0x8(%ebp),%eax
c01010f7:	0f b6 c0             	movzbl %al,%eax
c01010fa:	83 f8 0a             	cmp    $0xa,%eax
c01010fd:	74 4e                	je     c010114d <cga_putc+0x70>
c01010ff:	83 f8 0d             	cmp    $0xd,%eax
c0101102:	74 59                	je     c010115d <cga_putc+0x80>
c0101104:	83 f8 08             	cmp    $0x8,%eax
c0101107:	0f 85 8a 00 00 00    	jne    c0101197 <cga_putc+0xba>
    case '\b':
        if (crt_pos > 0) {
c010110d:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c0101114:	66 85 c0             	test   %ax,%ax
c0101117:	0f 84 a0 00 00 00    	je     c01011bd <cga_putc+0xe0>
            crt_pos --;
c010111d:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c0101124:	83 e8 01             	sub    $0x1,%eax
c0101127:	66 a3 44 a4 11 c0    	mov    %ax,0xc011a444
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
c010112d:	a1 40 a4 11 c0       	mov    0xc011a440,%eax
c0101132:	0f b7 15 44 a4 11 c0 	movzwl 0xc011a444,%edx
c0101139:	0f b7 d2             	movzwl %dx,%edx
c010113c:	01 d2                	add    %edx,%edx
c010113e:	01 d0                	add    %edx,%eax
c0101140:	8b 55 08             	mov    0x8(%ebp),%edx
c0101143:	b2 00                	mov    $0x0,%dl
c0101145:	83 ca 20             	or     $0x20,%edx
c0101148:	66 89 10             	mov    %dx,(%eax)
        }
        break;
c010114b:	eb 70                	jmp    c01011bd <cga_putc+0xe0>
    case '\n':
        crt_pos += CRT_COLS;
c010114d:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c0101154:	83 c0 50             	add    $0x50,%eax
c0101157:	66 a3 44 a4 11 c0    	mov    %ax,0xc011a444
    case '\r':
        crt_pos -= (crt_pos % CRT_COLS);
c010115d:	0f b7 1d 44 a4 11 c0 	movzwl 0xc011a444,%ebx
c0101164:	0f b7 0d 44 a4 11 c0 	movzwl 0xc011a444,%ecx
c010116b:	0f b7 c1             	movzwl %cx,%eax
c010116e:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
c0101174:	c1 e8 10             	shr    $0x10,%eax
c0101177:	89 c2                	mov    %eax,%edx
c0101179:	66 c1 ea 06          	shr    $0x6,%dx
c010117d:	89 d0                	mov    %edx,%eax
c010117f:	c1 e0 02             	shl    $0x2,%eax
c0101182:	01 d0                	add    %edx,%eax
c0101184:	c1 e0 04             	shl    $0x4,%eax
c0101187:	29 c1                	sub    %eax,%ecx
c0101189:	89 ca                	mov    %ecx,%edx
c010118b:	89 d8                	mov    %ebx,%eax
c010118d:	29 d0                	sub    %edx,%eax
c010118f:	66 a3 44 a4 11 c0    	mov    %ax,0xc011a444
        break;
c0101195:	eb 27                	jmp    c01011be <cga_putc+0xe1>
    default:
        crt_buf[crt_pos ++] = c;     // write the character
c0101197:	8b 0d 40 a4 11 c0    	mov    0xc011a440,%ecx
c010119d:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c01011a4:	8d 50 01             	lea    0x1(%eax),%edx
c01011a7:	66 89 15 44 a4 11 c0 	mov    %dx,0xc011a444
c01011ae:	0f b7 c0             	movzwl %ax,%eax
c01011b1:	01 c0                	add    %eax,%eax
c01011b3:	01 c8                	add    %ecx,%eax
c01011b5:	8b 55 08             	mov    0x8(%ebp),%edx
c01011b8:	66 89 10             	mov    %dx,(%eax)
        break;
c01011bb:	eb 01                	jmp    c01011be <cga_putc+0xe1>
    case '\b':
        if (crt_pos > 0) {
            crt_pos --;
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
        }
        break;
c01011bd:	90                   	nop
        crt_buf[crt_pos ++] = c;     // write the character
        break;
    }

    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) {
c01011be:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c01011c5:	66 3d cf 07          	cmp    $0x7cf,%ax
c01011c9:	76 59                	jbe    c0101224 <cga_putc+0x147>
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
c01011cb:	a1 40 a4 11 c0       	mov    0xc011a440,%eax
c01011d0:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
c01011d6:	a1 40 a4 11 c0       	mov    0xc011a440,%eax
c01011db:	83 ec 04             	sub    $0x4,%esp
c01011de:	68 00 0f 00 00       	push   $0xf00
c01011e3:	52                   	push   %edx
c01011e4:	50                   	push   %eax
c01011e5:	e8 af 42 00 00       	call   c0105499 <memmove>
c01011ea:	83 c4 10             	add    $0x10,%esp
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i ++) {
c01011ed:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
c01011f4:	eb 15                	jmp    c010120b <cga_putc+0x12e>
            crt_buf[i] = 0x0700 | ' ';
c01011f6:	a1 40 a4 11 c0       	mov    0xc011a440,%eax
c01011fb:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01011fe:	01 d2                	add    %edx,%edx
c0101200:	01 d0                	add    %edx,%eax
c0101202:	66 c7 00 20 07       	movw   $0x720,(%eax)

    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) {
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i ++) {
c0101207:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c010120b:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
c0101212:	7e e2                	jle    c01011f6 <cga_putc+0x119>
            crt_buf[i] = 0x0700 | ' ';
        }
        crt_pos -= CRT_COLS;
c0101214:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c010121b:	83 e8 50             	sub    $0x50,%eax
c010121e:	66 a3 44 a4 11 c0    	mov    %ax,0xc011a444
    }

    // move that little blinky thing
    outb(addr_6845, 14);
c0101224:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c010122b:	0f b7 c0             	movzwl %ax,%eax
c010122e:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
c0101232:	c6 45 e8 0e          	movb   $0xe,-0x18(%ebp)
c0101236:	0f b6 45 e8          	movzbl -0x18(%ebp),%eax
c010123a:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c010123e:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos >> 8);
c010123f:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c0101246:	66 c1 e8 08          	shr    $0x8,%ax
c010124a:	0f b6 c0             	movzbl %al,%eax
c010124d:	0f b7 15 46 a4 11 c0 	movzwl 0xc011a446,%edx
c0101254:	83 c2 01             	add    $0x1,%edx
c0101257:	0f b7 d2             	movzwl %dx,%edx
c010125a:	66 89 55 f0          	mov    %dx,-0x10(%ebp)
c010125e:	88 45 e9             	mov    %al,-0x17(%ebp)
c0101261:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
c0101265:	0f b7 55 f0          	movzwl -0x10(%ebp),%edx
c0101269:	ee                   	out    %al,(%dx)
    outb(addr_6845, 15);
c010126a:	0f b7 05 46 a4 11 c0 	movzwl 0xc011a446,%eax
c0101271:	0f b7 c0             	movzwl %ax,%eax
c0101274:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
c0101278:	c6 45 ea 0f          	movb   $0xf,-0x16(%ebp)
c010127c:	0f b6 45 ea          	movzbl -0x16(%ebp),%eax
c0101280:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c0101284:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos);
c0101285:	0f b7 05 44 a4 11 c0 	movzwl 0xc011a444,%eax
c010128c:	0f b6 c0             	movzbl %al,%eax
c010128f:	0f b7 15 46 a4 11 c0 	movzwl 0xc011a446,%edx
c0101296:	83 c2 01             	add    $0x1,%edx
c0101299:	0f b7 d2             	movzwl %dx,%edx
c010129c:	66 89 55 ec          	mov    %dx,-0x14(%ebp)
c01012a0:	88 45 eb             	mov    %al,-0x15(%ebp)
c01012a3:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
c01012a7:	0f b7 55 ec          	movzwl -0x14(%ebp),%edx
c01012ab:	ee                   	out    %al,(%dx)
}
c01012ac:	90                   	nop
c01012ad:	8b 5d fc             	mov    -0x4(%ebp),%ebx
c01012b0:	c9                   	leave  
c01012b1:	c3                   	ret    

c01012b2 <serial_putc_sub>:

static void
serial_putc_sub(int c) {
c01012b2:	55                   	push   %ebp
c01012b3:	89 e5                	mov    %esp,%ebp
c01012b5:	83 ec 10             	sub    $0x10,%esp
    int i;
    for (i = 0; !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800; i ++) {
c01012b8:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c01012bf:	eb 09                	jmp    c01012ca <serial_putc_sub+0x18>
        delay();
c01012c1:	e8 51 fb ff ff       	call   c0100e17 <delay>
}

static void
serial_putc_sub(int c) {
    int i;
    for (i = 0; !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800; i ++) {
c01012c6:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c01012ca:	66 c7 45 f8 fd 03    	movw   $0x3fd,-0x8(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c01012d0:	0f b7 45 f8          	movzwl -0x8(%ebp),%eax
c01012d4:	89 c2                	mov    %eax,%edx
c01012d6:	ec                   	in     (%dx),%al
c01012d7:	88 45 f7             	mov    %al,-0x9(%ebp)
    return data;
c01012da:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
c01012de:	0f b6 c0             	movzbl %al,%eax
c01012e1:	83 e0 20             	and    $0x20,%eax
c01012e4:	85 c0                	test   %eax,%eax
c01012e6:	75 09                	jne    c01012f1 <serial_putc_sub+0x3f>
c01012e8:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
c01012ef:	7e d0                	jle    c01012c1 <serial_putc_sub+0xf>
        delay();
    }
    outb(COM1 + COM_TX, c);
c01012f1:	8b 45 08             	mov    0x8(%ebp),%eax
c01012f4:	0f b6 c0             	movzbl %al,%eax
c01012f7:	66 c7 45 fa f8 03    	movw   $0x3f8,-0x6(%ebp)
c01012fd:	88 45 f6             	mov    %al,-0xa(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0101300:	0f b6 45 f6          	movzbl -0xa(%ebp),%eax
c0101304:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c0101308:	ee                   	out    %al,(%dx)
}
c0101309:	90                   	nop
c010130a:	c9                   	leave  
c010130b:	c3                   	ret    

c010130c <serial_putc>:

/* serial_putc - print character to serial port */
static void
serial_putc(int c) {
c010130c:	55                   	push   %ebp
c010130d:	89 e5                	mov    %esp,%ebp
    if (c != '\b') {
c010130f:	83 7d 08 08          	cmpl   $0x8,0x8(%ebp)
c0101313:	74 0d                	je     c0101322 <serial_putc+0x16>
        serial_putc_sub(c);
c0101315:	ff 75 08             	pushl  0x8(%ebp)
c0101318:	e8 95 ff ff ff       	call   c01012b2 <serial_putc_sub>
c010131d:	83 c4 04             	add    $0x4,%esp
    else {
        serial_putc_sub('\b');
        serial_putc_sub(' ');
        serial_putc_sub('\b');
    }
}
c0101320:	eb 1e                	jmp    c0101340 <serial_putc+0x34>
serial_putc(int c) {
    if (c != '\b') {
        serial_putc_sub(c);
    }
    else {
        serial_putc_sub('\b');
c0101322:	6a 08                	push   $0x8
c0101324:	e8 89 ff ff ff       	call   c01012b2 <serial_putc_sub>
c0101329:	83 c4 04             	add    $0x4,%esp
        serial_putc_sub(' ');
c010132c:	6a 20                	push   $0x20
c010132e:	e8 7f ff ff ff       	call   c01012b2 <serial_putc_sub>
c0101333:	83 c4 04             	add    $0x4,%esp
        serial_putc_sub('\b');
c0101336:	6a 08                	push   $0x8
c0101338:	e8 75 ff ff ff       	call   c01012b2 <serial_putc_sub>
c010133d:	83 c4 04             	add    $0x4,%esp
    }
}
c0101340:	90                   	nop
c0101341:	c9                   	leave  
c0101342:	c3                   	ret    

c0101343 <cons_intr>:
/* *
 * cons_intr - called by device interrupt routines to feed input
 * characters into the circular console input buffer.
 * */
static void
cons_intr(int (*proc)(void)) {
c0101343:	55                   	push   %ebp
c0101344:	89 e5                	mov    %esp,%ebp
c0101346:	83 ec 18             	sub    $0x18,%esp
    int c;
    while ((c = (*proc)()) != -1) {
c0101349:	eb 33                	jmp    c010137e <cons_intr+0x3b>
        if (c != 0) {
c010134b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c010134f:	74 2d                	je     c010137e <cons_intr+0x3b>
            cons.buf[cons.wpos ++] = c;
c0101351:	a1 64 a6 11 c0       	mov    0xc011a664,%eax
c0101356:	8d 50 01             	lea    0x1(%eax),%edx
c0101359:	89 15 64 a6 11 c0    	mov    %edx,0xc011a664
c010135f:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0101362:	88 90 60 a4 11 c0    	mov    %dl,-0x3fee5ba0(%eax)
            if (cons.wpos == CONSBUFSIZE) {
c0101368:	a1 64 a6 11 c0       	mov    0xc011a664,%eax
c010136d:	3d 00 02 00 00       	cmp    $0x200,%eax
c0101372:	75 0a                	jne    c010137e <cons_intr+0x3b>
                cons.wpos = 0;
c0101374:	c7 05 64 a6 11 c0 00 	movl   $0x0,0xc011a664
c010137b:	00 00 00 
 * characters into the circular console input buffer.
 * */
static void
cons_intr(int (*proc)(void)) {
    int c;
    while ((c = (*proc)()) != -1) {
c010137e:	8b 45 08             	mov    0x8(%ebp),%eax
c0101381:	ff d0                	call   *%eax
c0101383:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0101386:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
c010138a:	75 bf                	jne    c010134b <cons_intr+0x8>
            if (cons.wpos == CONSBUFSIZE) {
                cons.wpos = 0;
            }
        }
    }
}
c010138c:	90                   	nop
c010138d:	c9                   	leave  
c010138e:	c3                   	ret    

c010138f <serial_proc_data>:

/* serial_proc_data - get data from serial port */
static int
serial_proc_data(void) {
c010138f:	55                   	push   %ebp
c0101390:	89 e5                	mov    %esp,%ebp
c0101392:	83 ec 10             	sub    $0x10,%esp
c0101395:	66 c7 45 f8 fd 03    	movw   $0x3fd,-0x8(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c010139b:	0f b7 45 f8          	movzwl -0x8(%ebp),%eax
c010139f:	89 c2                	mov    %eax,%edx
c01013a1:	ec                   	in     (%dx),%al
c01013a2:	88 45 f7             	mov    %al,-0x9(%ebp)
    return data;
c01013a5:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
    if (!(inb(COM1 + COM_LSR) & COM_LSR_DATA)) {
c01013a9:	0f b6 c0             	movzbl %al,%eax
c01013ac:	83 e0 01             	and    $0x1,%eax
c01013af:	85 c0                	test   %eax,%eax
c01013b1:	75 07                	jne    c01013ba <serial_proc_data+0x2b>
        return -1;
c01013b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c01013b8:	eb 2a                	jmp    c01013e4 <serial_proc_data+0x55>
c01013ba:	66 c7 45 fa f8 03    	movw   $0x3f8,-0x6(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c01013c0:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
c01013c4:	89 c2                	mov    %eax,%edx
c01013c6:	ec                   	in     (%dx),%al
c01013c7:	88 45 f6             	mov    %al,-0xa(%ebp)
    return data;
c01013ca:	0f b6 45 f6          	movzbl -0xa(%ebp),%eax
    }
    int c = inb(COM1 + COM_RX);
c01013ce:	0f b6 c0             	movzbl %al,%eax
c01013d1:	89 45 fc             	mov    %eax,-0x4(%ebp)
    if (c == 127) {
c01013d4:	83 7d fc 7f          	cmpl   $0x7f,-0x4(%ebp)
c01013d8:	75 07                	jne    c01013e1 <serial_proc_data+0x52>
        c = '\b';
c01013da:	c7 45 fc 08 00 00 00 	movl   $0x8,-0x4(%ebp)
    }
    return c;
c01013e1:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c01013e4:	c9                   	leave  
c01013e5:	c3                   	ret    

c01013e6 <serial_intr>:

/* serial_intr - try to feed input characters from serial port */
void
serial_intr(void) {
c01013e6:	55                   	push   %ebp
c01013e7:	89 e5                	mov    %esp,%ebp
c01013e9:	83 ec 08             	sub    $0x8,%esp
    if (serial_exists) {
c01013ec:	a1 48 a4 11 c0       	mov    0xc011a448,%eax
c01013f1:	85 c0                	test   %eax,%eax
c01013f3:	74 10                	je     c0101405 <serial_intr+0x1f>
        cons_intr(serial_proc_data);
c01013f5:	83 ec 0c             	sub    $0xc,%esp
c01013f8:	68 8f 13 10 c0       	push   $0xc010138f
c01013fd:	e8 41 ff ff ff       	call   c0101343 <cons_intr>
c0101402:	83 c4 10             	add    $0x10,%esp
    }
}
c0101405:	90                   	nop
c0101406:	c9                   	leave  
c0101407:	c3                   	ret    

c0101408 <kbd_proc_data>:
 *
 * The kbd_proc_data() function gets data from the keyboard.
 * If we finish a character, return it, else 0. And return -1 if no data.
 * */
static int
kbd_proc_data(void) {
c0101408:	55                   	push   %ebp
c0101409:	89 e5                	mov    %esp,%ebp
c010140b:	83 ec 18             	sub    $0x18,%esp
c010140e:	66 c7 45 ec 64 00    	movw   $0x64,-0x14(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0101414:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
c0101418:	89 c2                	mov    %eax,%edx
c010141a:	ec                   	in     (%dx),%al
c010141b:	88 45 eb             	mov    %al,-0x15(%ebp)
    return data;
c010141e:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
    int c;
    uint8_t data;
    static uint32_t shift;

    if ((inb(KBSTATP) & KBS_DIB) == 0) {
c0101422:	0f b6 c0             	movzbl %al,%eax
c0101425:	83 e0 01             	and    $0x1,%eax
c0101428:	85 c0                	test   %eax,%eax
c010142a:	75 0a                	jne    c0101436 <kbd_proc_data+0x2e>
        return -1;
c010142c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c0101431:	e9 5d 01 00 00       	jmp    c0101593 <kbd_proc_data+0x18b>
c0101436:	66 c7 45 f0 60 00    	movw   $0x60,-0x10(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c010143c:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
c0101440:	89 c2                	mov    %eax,%edx
c0101442:	ec                   	in     (%dx),%al
c0101443:	88 45 ea             	mov    %al,-0x16(%ebp)
    return data;
c0101446:	0f b6 45 ea          	movzbl -0x16(%ebp),%eax
    }

    data = inb(KBDATAP);
c010144a:	88 45 f3             	mov    %al,-0xd(%ebp)

    if (data == 0xE0) {
c010144d:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
c0101451:	75 17                	jne    c010146a <kbd_proc_data+0x62>
        // E0 escape character
        shift |= E0ESC;
c0101453:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c0101458:	83 c8 40             	or     $0x40,%eax
c010145b:	a3 68 a6 11 c0       	mov    %eax,0xc011a668
        return 0;
c0101460:	b8 00 00 00 00       	mov    $0x0,%eax
c0101465:	e9 29 01 00 00       	jmp    c0101593 <kbd_proc_data+0x18b>
    } else if (data & 0x80) {
c010146a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c010146e:	84 c0                	test   %al,%al
c0101470:	79 47                	jns    c01014b9 <kbd_proc_data+0xb1>
        // Key released
        data = (shift & E0ESC ? data : data & 0x7F);
c0101472:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c0101477:	83 e0 40             	and    $0x40,%eax
c010147a:	85 c0                	test   %eax,%eax
c010147c:	75 09                	jne    c0101487 <kbd_proc_data+0x7f>
c010147e:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101482:	83 e0 7f             	and    $0x7f,%eax
c0101485:	eb 04                	jmp    c010148b <kbd_proc_data+0x83>
c0101487:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c010148b:	88 45 f3             	mov    %al,-0xd(%ebp)
        shift &= ~(shiftcode[data] | E0ESC);
c010148e:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101492:	0f b6 80 40 70 11 c0 	movzbl -0x3fee8fc0(%eax),%eax
c0101499:	83 c8 40             	or     $0x40,%eax
c010149c:	0f b6 c0             	movzbl %al,%eax
c010149f:	f7 d0                	not    %eax
c01014a1:	89 c2                	mov    %eax,%edx
c01014a3:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c01014a8:	21 d0                	and    %edx,%eax
c01014aa:	a3 68 a6 11 c0       	mov    %eax,0xc011a668
        return 0;
c01014af:	b8 00 00 00 00       	mov    $0x0,%eax
c01014b4:	e9 da 00 00 00       	jmp    c0101593 <kbd_proc_data+0x18b>
    } else if (shift & E0ESC) {
c01014b9:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c01014be:	83 e0 40             	and    $0x40,%eax
c01014c1:	85 c0                	test   %eax,%eax
c01014c3:	74 11                	je     c01014d6 <kbd_proc_data+0xce>
        // Last character was an E0 escape; or with 0x80
        data |= 0x80;
c01014c5:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
        shift &= ~E0ESC;
c01014c9:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c01014ce:	83 e0 bf             	and    $0xffffffbf,%eax
c01014d1:	a3 68 a6 11 c0       	mov    %eax,0xc011a668
    }

    shift |= shiftcode[data];
c01014d6:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c01014da:	0f b6 80 40 70 11 c0 	movzbl -0x3fee8fc0(%eax),%eax
c01014e1:	0f b6 d0             	movzbl %al,%edx
c01014e4:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c01014e9:	09 d0                	or     %edx,%eax
c01014eb:	a3 68 a6 11 c0       	mov    %eax,0xc011a668
    shift ^= togglecode[data];
c01014f0:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c01014f4:	0f b6 80 40 71 11 c0 	movzbl -0x3fee8ec0(%eax),%eax
c01014fb:	0f b6 d0             	movzbl %al,%edx
c01014fe:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c0101503:	31 d0                	xor    %edx,%eax
c0101505:	a3 68 a6 11 c0       	mov    %eax,0xc011a668

    c = charcode[shift & (CTL | SHIFT)][data];
c010150a:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c010150f:	83 e0 03             	and    $0x3,%eax
c0101512:	8b 14 85 40 75 11 c0 	mov    -0x3fee8ac0(,%eax,4),%edx
c0101519:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c010151d:	01 d0                	add    %edx,%eax
c010151f:	0f b6 00             	movzbl (%eax),%eax
c0101522:	0f b6 c0             	movzbl %al,%eax
c0101525:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (shift & CAPSLOCK) {
c0101528:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c010152d:	83 e0 08             	and    $0x8,%eax
c0101530:	85 c0                	test   %eax,%eax
c0101532:	74 22                	je     c0101556 <kbd_proc_data+0x14e>
        if ('a' <= c && c <= 'z')
c0101534:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
c0101538:	7e 0c                	jle    c0101546 <kbd_proc_data+0x13e>
c010153a:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
c010153e:	7f 06                	jg     c0101546 <kbd_proc_data+0x13e>
            c += 'A' - 'a';
c0101540:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
c0101544:	eb 10                	jmp    c0101556 <kbd_proc_data+0x14e>
        else if ('A' <= c && c <= 'Z')
c0101546:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
c010154a:	7e 0a                	jle    c0101556 <kbd_proc_data+0x14e>
c010154c:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
c0101550:	7f 04                	jg     c0101556 <kbd_proc_data+0x14e>
            c += 'a' - 'A';
c0101552:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
    }

    // Process special keys
    // Ctrl-Alt-Del: reboot
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
c0101556:	a1 68 a6 11 c0       	mov    0xc011a668,%eax
c010155b:	f7 d0                	not    %eax
c010155d:	83 e0 06             	and    $0x6,%eax
c0101560:	85 c0                	test   %eax,%eax
c0101562:	75 2c                	jne    c0101590 <kbd_proc_data+0x188>
c0101564:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
c010156b:	75 23                	jne    c0101590 <kbd_proc_data+0x188>
        cprintf("Rebooting!\n");
c010156d:	83 ec 0c             	sub    $0xc,%esp
c0101570:	68 41 5f 10 c0       	push   $0xc0105f41
c0101575:	e8 03 ed ff ff       	call   c010027d <cprintf>
c010157a:	83 c4 10             	add    $0x10,%esp
c010157d:	66 c7 45 ee 92 00    	movw   $0x92,-0x12(%ebp)
c0101583:	c6 45 e9 03          	movb   $0x3,-0x17(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0101587:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
c010158b:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c010158f:	ee                   	out    %al,(%dx)
        outb(0x92, 0x3); // courtesy of Chris Frost
    }
    return c;
c0101590:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0101593:	c9                   	leave  
c0101594:	c3                   	ret    

c0101595 <kbd_intr>:

/* kbd_intr - try to feed input characters from keyboard */
static void
kbd_intr(void) {
c0101595:	55                   	push   %ebp
c0101596:	89 e5                	mov    %esp,%ebp
c0101598:	83 ec 08             	sub    $0x8,%esp
    cons_intr(kbd_proc_data);
c010159b:	83 ec 0c             	sub    $0xc,%esp
c010159e:	68 08 14 10 c0       	push   $0xc0101408
c01015a3:	e8 9b fd ff ff       	call   c0101343 <cons_intr>
c01015a8:	83 c4 10             	add    $0x10,%esp
}
c01015ab:	90                   	nop
c01015ac:	c9                   	leave  
c01015ad:	c3                   	ret    

c01015ae <kbd_init>:

static void
kbd_init(void) {
c01015ae:	55                   	push   %ebp
c01015af:	89 e5                	mov    %esp,%ebp
c01015b1:	83 ec 08             	sub    $0x8,%esp
    // drain the kbd buffer
    kbd_intr();
c01015b4:	e8 dc ff ff ff       	call   c0101595 <kbd_intr>
    pic_enable(IRQ_KBD);
c01015b9:	83 ec 0c             	sub    $0xc,%esp
c01015bc:	6a 01                	push   $0x1
c01015be:	e8 4b 01 00 00       	call   c010170e <pic_enable>
c01015c3:	83 c4 10             	add    $0x10,%esp
}
c01015c6:	90                   	nop
c01015c7:	c9                   	leave  
c01015c8:	c3                   	ret    

c01015c9 <cons_init>:

/* cons_init - initializes the console devices */
void
cons_init(void) {
c01015c9:	55                   	push   %ebp
c01015ca:	89 e5                	mov    %esp,%ebp
c01015cc:	83 ec 08             	sub    $0x8,%esp
    cga_init();
c01015cf:	e8 8c f8 ff ff       	call   c0100e60 <cga_init>
    serial_init();
c01015d4:	e8 6e f9 ff ff       	call   c0100f47 <serial_init>
    kbd_init();
c01015d9:	e8 d0 ff ff ff       	call   c01015ae <kbd_init>
    if (!serial_exists) {
c01015de:	a1 48 a4 11 c0       	mov    0xc011a448,%eax
c01015e3:	85 c0                	test   %eax,%eax
c01015e5:	75 10                	jne    c01015f7 <cons_init+0x2e>
        cprintf("serial port does not exist!!\n");
c01015e7:	83 ec 0c             	sub    $0xc,%esp
c01015ea:	68 4d 5f 10 c0       	push   $0xc0105f4d
c01015ef:	e8 89 ec ff ff       	call   c010027d <cprintf>
c01015f4:	83 c4 10             	add    $0x10,%esp
    }
}
c01015f7:	90                   	nop
c01015f8:	c9                   	leave  
c01015f9:	c3                   	ret    

c01015fa <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void
cons_putc(int c) {
c01015fa:	55                   	push   %ebp
c01015fb:	89 e5                	mov    %esp,%ebp
c01015fd:	83 ec 18             	sub    $0x18,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
c0101600:	e8 d4 f7 ff ff       	call   c0100dd9 <__intr_save>
c0101605:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        lpt_putc(c);
c0101608:	83 ec 0c             	sub    $0xc,%esp
c010160b:	ff 75 08             	pushl  0x8(%ebp)
c010160e:	e8 93 fa ff ff       	call   c01010a6 <lpt_putc>
c0101613:	83 c4 10             	add    $0x10,%esp
        cga_putc(c);
c0101616:	83 ec 0c             	sub    $0xc,%esp
c0101619:	ff 75 08             	pushl  0x8(%ebp)
c010161c:	e8 bc fa ff ff       	call   c01010dd <cga_putc>
c0101621:	83 c4 10             	add    $0x10,%esp
        serial_putc(c);
c0101624:	83 ec 0c             	sub    $0xc,%esp
c0101627:	ff 75 08             	pushl  0x8(%ebp)
c010162a:	e8 dd fc ff ff       	call   c010130c <serial_putc>
c010162f:	83 c4 10             	add    $0x10,%esp
    }
    local_intr_restore(intr_flag);
c0101632:	83 ec 0c             	sub    $0xc,%esp
c0101635:	ff 75 f4             	pushl  -0xc(%ebp)
c0101638:	e8 c6 f7 ff ff       	call   c0100e03 <__intr_restore>
c010163d:	83 c4 10             	add    $0x10,%esp
}
c0101640:	90                   	nop
c0101641:	c9                   	leave  
c0101642:	c3                   	ret    

c0101643 <cons_getc>:
/* *
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int
cons_getc(void) {
c0101643:	55                   	push   %ebp
c0101644:	89 e5                	mov    %esp,%ebp
c0101646:	83 ec 18             	sub    $0x18,%esp
    int c = 0;
c0101649:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
c0101650:	e8 84 f7 ff ff       	call   c0100dd9 <__intr_save>
c0101655:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        // poll for any pending input characters,
        // so that this function works even when interrupts are disabled
        // (e.g., when called from the kernel monitor).
        serial_intr();
c0101658:	e8 89 fd ff ff       	call   c01013e6 <serial_intr>
        kbd_intr();
c010165d:	e8 33 ff ff ff       	call   c0101595 <kbd_intr>

        // grab the next character from the input buffer.
        if (cons.rpos != cons.wpos) {
c0101662:	8b 15 60 a6 11 c0    	mov    0xc011a660,%edx
c0101668:	a1 64 a6 11 c0       	mov    0xc011a664,%eax
c010166d:	39 c2                	cmp    %eax,%edx
c010166f:	74 31                	je     c01016a2 <cons_getc+0x5f>
            c = cons.buf[cons.rpos ++];
c0101671:	a1 60 a6 11 c0       	mov    0xc011a660,%eax
c0101676:	8d 50 01             	lea    0x1(%eax),%edx
c0101679:	89 15 60 a6 11 c0    	mov    %edx,0xc011a660
c010167f:	0f b6 80 60 a4 11 c0 	movzbl -0x3fee5ba0(%eax),%eax
c0101686:	0f b6 c0             	movzbl %al,%eax
c0101689:	89 45 f4             	mov    %eax,-0xc(%ebp)
            if (cons.rpos == CONSBUFSIZE) {
c010168c:	a1 60 a6 11 c0       	mov    0xc011a660,%eax
c0101691:	3d 00 02 00 00       	cmp    $0x200,%eax
c0101696:	75 0a                	jne    c01016a2 <cons_getc+0x5f>
                cons.rpos = 0;
c0101698:	c7 05 60 a6 11 c0 00 	movl   $0x0,0xc011a660
c010169f:	00 00 00 
            }
        }
    }
    local_intr_restore(intr_flag);
c01016a2:	83 ec 0c             	sub    $0xc,%esp
c01016a5:	ff 75 f0             	pushl  -0x10(%ebp)
c01016a8:	e8 56 f7 ff ff       	call   c0100e03 <__intr_restore>
c01016ad:	83 c4 10             	add    $0x10,%esp
    return c;
c01016b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01016b3:	c9                   	leave  
c01016b4:	c3                   	ret    

c01016b5 <pic_setmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static uint16_t irq_mask = 0xFFFF & ~(1 << IRQ_SLAVE);
static bool did_init = 0;

static void
pic_setmask(uint16_t mask) {
c01016b5:	55                   	push   %ebp
c01016b6:	89 e5                	mov    %esp,%ebp
c01016b8:	83 ec 14             	sub    $0x14,%esp
c01016bb:	8b 45 08             	mov    0x8(%ebp),%eax
c01016be:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
    irq_mask = mask;
c01016c2:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
c01016c6:	66 a3 50 75 11 c0    	mov    %ax,0xc0117550
    if (did_init) {
c01016cc:	a1 6c a6 11 c0       	mov    0xc011a66c,%eax
c01016d1:	85 c0                	test   %eax,%eax
c01016d3:	74 36                	je     c010170b <pic_setmask+0x56>
        outb(IO_PIC1 + 1, mask);
c01016d5:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
c01016d9:	0f b6 c0             	movzbl %al,%eax
c01016dc:	66 c7 45 fe 21 00    	movw   $0x21,-0x2(%ebp)
c01016e2:	88 45 fa             	mov    %al,-0x6(%ebp)
c01016e5:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
c01016e9:	0f b7 55 fe          	movzwl -0x2(%ebp),%edx
c01016ed:	ee                   	out    %al,(%dx)
        outb(IO_PIC2 + 1, mask >> 8);
c01016ee:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
c01016f2:	66 c1 e8 08          	shr    $0x8,%ax
c01016f6:	0f b6 c0             	movzbl %al,%eax
c01016f9:	66 c7 45 fc a1 00    	movw   $0xa1,-0x4(%ebp)
c01016ff:	88 45 fb             	mov    %al,-0x5(%ebp)
c0101702:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
c0101706:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
c010170a:	ee                   	out    %al,(%dx)
    }
}
c010170b:	90                   	nop
c010170c:	c9                   	leave  
c010170d:	c3                   	ret    

c010170e <pic_enable>:

void
pic_enable(unsigned int irq) {
c010170e:	55                   	push   %ebp
c010170f:	89 e5                	mov    %esp,%ebp
    pic_setmask(irq_mask & ~(1 << irq));
c0101711:	8b 45 08             	mov    0x8(%ebp),%eax
c0101714:	ba 01 00 00 00       	mov    $0x1,%edx
c0101719:	89 c1                	mov    %eax,%ecx
c010171b:	d3 e2                	shl    %cl,%edx
c010171d:	89 d0                	mov    %edx,%eax
c010171f:	f7 d0                	not    %eax
c0101721:	89 c2                	mov    %eax,%edx
c0101723:	0f b7 05 50 75 11 c0 	movzwl 0xc0117550,%eax
c010172a:	21 d0                	and    %edx,%eax
c010172c:	0f b7 c0             	movzwl %ax,%eax
c010172f:	50                   	push   %eax
c0101730:	e8 80 ff ff ff       	call   c01016b5 <pic_setmask>
c0101735:	83 c4 04             	add    $0x4,%esp
}
c0101738:	90                   	nop
c0101739:	c9                   	leave  
c010173a:	c3                   	ret    

c010173b <pic_init>:

/* pic_init - initialize the 8259A interrupt controllers */
void
pic_init(void) {
c010173b:	55                   	push   %ebp
c010173c:	89 e5                	mov    %esp,%ebp
c010173e:	83 ec 30             	sub    $0x30,%esp
    did_init = 1;
c0101741:	c7 05 6c a6 11 c0 01 	movl   $0x1,0xc011a66c
c0101748:	00 00 00 
c010174b:	66 c7 45 fe 21 00    	movw   $0x21,-0x2(%ebp)
c0101751:	c6 45 d6 ff          	movb   $0xff,-0x2a(%ebp)
c0101755:	0f b6 45 d6          	movzbl -0x2a(%ebp),%eax
c0101759:	0f b7 55 fe          	movzwl -0x2(%ebp),%edx
c010175d:	ee                   	out    %al,(%dx)
c010175e:	66 c7 45 fc a1 00    	movw   $0xa1,-0x4(%ebp)
c0101764:	c6 45 d7 ff          	movb   $0xff,-0x29(%ebp)
c0101768:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
c010176c:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
c0101770:	ee                   	out    %al,(%dx)
c0101771:	66 c7 45 fa 20 00    	movw   $0x20,-0x6(%ebp)
c0101777:	c6 45 d8 11          	movb   $0x11,-0x28(%ebp)
c010177b:	0f b6 45 d8          	movzbl -0x28(%ebp),%eax
c010177f:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c0101783:	ee                   	out    %al,(%dx)
c0101784:	66 c7 45 f8 21 00    	movw   $0x21,-0x8(%ebp)
c010178a:	c6 45 d9 20          	movb   $0x20,-0x27(%ebp)
c010178e:	0f b6 45 d9          	movzbl -0x27(%ebp),%eax
c0101792:	0f b7 55 f8          	movzwl -0x8(%ebp),%edx
c0101796:	ee                   	out    %al,(%dx)
c0101797:	66 c7 45 f6 21 00    	movw   $0x21,-0xa(%ebp)
c010179d:	c6 45 da 04          	movb   $0x4,-0x26(%ebp)
c01017a1:	0f b6 45 da          	movzbl -0x26(%ebp),%eax
c01017a5:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c01017a9:	ee                   	out    %al,(%dx)
c01017aa:	66 c7 45 f4 21 00    	movw   $0x21,-0xc(%ebp)
c01017b0:	c6 45 db 03          	movb   $0x3,-0x25(%ebp)
c01017b4:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
c01017b8:	0f b7 55 f4          	movzwl -0xc(%ebp),%edx
c01017bc:	ee                   	out    %al,(%dx)
c01017bd:	66 c7 45 f2 a0 00    	movw   $0xa0,-0xe(%ebp)
c01017c3:	c6 45 dc 11          	movb   $0x11,-0x24(%ebp)
c01017c7:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
c01017cb:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c01017cf:	ee                   	out    %al,(%dx)
c01017d0:	66 c7 45 f0 a1 00    	movw   $0xa1,-0x10(%ebp)
c01017d6:	c6 45 dd 28          	movb   $0x28,-0x23(%ebp)
c01017da:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
c01017de:	0f b7 55 f0          	movzwl -0x10(%ebp),%edx
c01017e2:	ee                   	out    %al,(%dx)
c01017e3:	66 c7 45 ee a1 00    	movw   $0xa1,-0x12(%ebp)
c01017e9:	c6 45 de 02          	movb   $0x2,-0x22(%ebp)
c01017ed:	0f b6 45 de          	movzbl -0x22(%ebp),%eax
c01017f1:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c01017f5:	ee                   	out    %al,(%dx)
c01017f6:	66 c7 45 ec a1 00    	movw   $0xa1,-0x14(%ebp)
c01017fc:	c6 45 df 03          	movb   $0x3,-0x21(%ebp)
c0101800:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
c0101804:	0f b7 55 ec          	movzwl -0x14(%ebp),%edx
c0101808:	ee                   	out    %al,(%dx)
c0101809:	66 c7 45 ea 20 00    	movw   $0x20,-0x16(%ebp)
c010180f:	c6 45 e0 68          	movb   $0x68,-0x20(%ebp)
c0101813:	0f b6 45 e0          	movzbl -0x20(%ebp),%eax
c0101817:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
c010181b:	ee                   	out    %al,(%dx)
c010181c:	66 c7 45 e8 20 00    	movw   $0x20,-0x18(%ebp)
c0101822:	c6 45 e1 0a          	movb   $0xa,-0x1f(%ebp)
c0101826:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
c010182a:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
c010182e:	ee                   	out    %al,(%dx)
c010182f:	66 c7 45 e6 a0 00    	movw   $0xa0,-0x1a(%ebp)
c0101835:	c6 45 e2 68          	movb   $0x68,-0x1e(%ebp)
c0101839:	0f b6 45 e2          	movzbl -0x1e(%ebp),%eax
c010183d:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
c0101841:	ee                   	out    %al,(%dx)
c0101842:	66 c7 45 e4 a0 00    	movw   $0xa0,-0x1c(%ebp)
c0101848:	c6 45 e3 0a          	movb   $0xa,-0x1d(%ebp)
c010184c:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
c0101850:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
c0101854:	ee                   	out    %al,(%dx)
    outb(IO_PIC1, 0x0a);    // read IRR by default

    outb(IO_PIC2, 0x68);    // OCW3
    outb(IO_PIC2, 0x0a);    // OCW3

    if (irq_mask != 0xFFFF) {
c0101855:	0f b7 05 50 75 11 c0 	movzwl 0xc0117550,%eax
c010185c:	66 83 f8 ff          	cmp    $0xffff,%ax
c0101860:	74 13                	je     c0101875 <pic_init+0x13a>
        pic_setmask(irq_mask);
c0101862:	0f b7 05 50 75 11 c0 	movzwl 0xc0117550,%eax
c0101869:	0f b7 c0             	movzwl %ax,%eax
c010186c:	50                   	push   %eax
c010186d:	e8 43 fe ff ff       	call   c01016b5 <pic_setmask>
c0101872:	83 c4 04             	add    $0x4,%esp
    }
}
c0101875:	90                   	nop
c0101876:	c9                   	leave  
c0101877:	c3                   	ret    

c0101878 <intr_enable>:
#include <x86.h>
#include <intr.h>

/* intr_enable - enable irq interrupt */
void
intr_enable(void) {
c0101878:	55                   	push   %ebp
c0101879:	89 e5                	mov    %esp,%ebp
    asm volatile ("lidt (%0)" :: "r" (pd) : "memory");
}

static inline void
sti(void) {
    asm volatile ("sti");
c010187b:	fb                   	sti    
    sti();
}
c010187c:	90                   	nop
c010187d:	5d                   	pop    %ebp
c010187e:	c3                   	ret    

c010187f <intr_disable>:

/* intr_disable - disable irq interrupt */
void
intr_disable(void) {
c010187f:	55                   	push   %ebp
c0101880:	89 e5                	mov    %esp,%ebp
}

static inline void
cli(void) {
    asm volatile ("cli" ::: "memory");
c0101882:	fa                   	cli    
    cli();
}
c0101883:	90                   	nop
c0101884:	5d                   	pop    %ebp
c0101885:	c3                   	ret    

c0101886 <print_ticks>:
#include <console.h>
#include <kdebug.h>

#define TICK_NUM 100

static void print_ticks() {
c0101886:	55                   	push   %ebp
c0101887:	89 e5                	mov    %esp,%ebp
c0101889:	83 ec 08             	sub    $0x8,%esp
    cprintf("%d ticks\n",TICK_NUM);
c010188c:	83 ec 08             	sub    $0x8,%esp
c010188f:	6a 64                	push   $0x64
c0101891:	68 80 5f 10 c0       	push   $0xc0105f80
c0101896:	e8 e2 e9 ff ff       	call   c010027d <cprintf>
c010189b:	83 c4 10             	add    $0x10,%esp
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
}
c010189e:	90                   	nop
c010189f:	c9                   	leave  
c01018a0:	c3                   	ret    

c01018a1 <idt_init>:
    sizeof(idt) - 1, (uintptr_t)idt
};

/* idt_init - initialize IDT to each of the entry points in kern/trap/vectors.S */
void
idt_init(void) {
c01018a1:	55                   	push   %ebp
c01018a2:	89 e5                	mov    %esp,%ebp
c01018a4:	83 ec 10             	sub    $0x10,%esp
      * (3) After setup the contents of IDT, you will let CPU know where is the IDT by using 'lidt' instruction.
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
      extern uintptr_t __vectors[];
      for(int i=0;i<256;i++){
c01018a7:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c01018ae:	e9 c3 00 00 00       	jmp    c0101976 <idt_init+0xd5>
      SETGATE(idt[i],0,GD_KTEXT,__vectors[i],DPL_KERNEL);
c01018b3:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018b6:	8b 04 85 e0 75 11 c0 	mov    -0x3fee8a20(,%eax,4),%eax
c01018bd:	89 c2                	mov    %eax,%edx
c01018bf:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018c2:	66 89 14 c5 80 a6 11 	mov    %dx,-0x3fee5980(,%eax,8)
c01018c9:	c0 
c01018ca:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018cd:	66 c7 04 c5 82 a6 11 	movw   $0x8,-0x3fee597e(,%eax,8)
c01018d4:	c0 08 00 
c01018d7:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018da:	0f b6 14 c5 84 a6 11 	movzbl -0x3fee597c(,%eax,8),%edx
c01018e1:	c0 
c01018e2:	83 e2 e0             	and    $0xffffffe0,%edx
c01018e5:	88 14 c5 84 a6 11 c0 	mov    %dl,-0x3fee597c(,%eax,8)
c01018ec:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018ef:	0f b6 14 c5 84 a6 11 	movzbl -0x3fee597c(,%eax,8),%edx
c01018f6:	c0 
c01018f7:	83 e2 1f             	and    $0x1f,%edx
c01018fa:	88 14 c5 84 a6 11 c0 	mov    %dl,-0x3fee597c(,%eax,8)
c0101901:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101904:	0f b6 14 c5 85 a6 11 	movzbl -0x3fee597b(,%eax,8),%edx
c010190b:	c0 
c010190c:	83 e2 f0             	and    $0xfffffff0,%edx
c010190f:	83 ca 0e             	or     $0xe,%edx
c0101912:	88 14 c5 85 a6 11 c0 	mov    %dl,-0x3fee597b(,%eax,8)
c0101919:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010191c:	0f b6 14 c5 85 a6 11 	movzbl -0x3fee597b(,%eax,8),%edx
c0101923:	c0 
c0101924:	83 e2 ef             	and    $0xffffffef,%edx
c0101927:	88 14 c5 85 a6 11 c0 	mov    %dl,-0x3fee597b(,%eax,8)
c010192e:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101931:	0f b6 14 c5 85 a6 11 	movzbl -0x3fee597b(,%eax,8),%edx
c0101938:	c0 
c0101939:	83 e2 9f             	and    $0xffffff9f,%edx
c010193c:	88 14 c5 85 a6 11 c0 	mov    %dl,-0x3fee597b(,%eax,8)
c0101943:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101946:	0f b6 14 c5 85 a6 11 	movzbl -0x3fee597b(,%eax,8),%edx
c010194d:	c0 
c010194e:	83 ca 80             	or     $0xffffff80,%edx
c0101951:	88 14 c5 85 a6 11 c0 	mov    %dl,-0x3fee597b(,%eax,8)
c0101958:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010195b:	8b 04 85 e0 75 11 c0 	mov    -0x3fee8a20(,%eax,4),%eax
c0101962:	c1 e8 10             	shr    $0x10,%eax
c0101965:	89 c2                	mov    %eax,%edx
c0101967:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010196a:	66 89 14 c5 86 a6 11 	mov    %dx,-0x3fee597a(,%eax,8)
c0101971:	c0 
      * (3) After setup the contents of IDT, you will let CPU know where is the IDT by using 'lidt' instruction.
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
      extern uintptr_t __vectors[];
      for(int i=0;i<256;i++){
c0101972:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c0101976:	81 7d fc ff 00 00 00 	cmpl   $0xff,-0x4(%ebp)
c010197d:	0f 8e 30 ff ff ff    	jle    c01018b3 <idt_init+0x12>
      SETGATE(idt[i],0,GD_KTEXT,__vectors[i],DPL_KERNEL);
      }
      SETGATE(idt[T_SWITCH_TOK],1,KERNEL_CS,__vectors[T_SWITCH_TOK],DPL_USER);
c0101983:	a1 c4 77 11 c0       	mov    0xc01177c4,%eax
c0101988:	66 a3 48 aa 11 c0    	mov    %ax,0xc011aa48
c010198e:	66 c7 05 4a aa 11 c0 	movw   $0x8,0xc011aa4a
c0101995:	08 00 
c0101997:	0f b6 05 4c aa 11 c0 	movzbl 0xc011aa4c,%eax
c010199e:	83 e0 e0             	and    $0xffffffe0,%eax
c01019a1:	a2 4c aa 11 c0       	mov    %al,0xc011aa4c
c01019a6:	0f b6 05 4c aa 11 c0 	movzbl 0xc011aa4c,%eax
c01019ad:	83 e0 1f             	and    $0x1f,%eax
c01019b0:	a2 4c aa 11 c0       	mov    %al,0xc011aa4c
c01019b5:	0f b6 05 4d aa 11 c0 	movzbl 0xc011aa4d,%eax
c01019bc:	83 c8 0f             	or     $0xf,%eax
c01019bf:	a2 4d aa 11 c0       	mov    %al,0xc011aa4d
c01019c4:	0f b6 05 4d aa 11 c0 	movzbl 0xc011aa4d,%eax
c01019cb:	83 e0 ef             	and    $0xffffffef,%eax
c01019ce:	a2 4d aa 11 c0       	mov    %al,0xc011aa4d
c01019d3:	0f b6 05 4d aa 11 c0 	movzbl 0xc011aa4d,%eax
c01019da:	83 c8 60             	or     $0x60,%eax
c01019dd:	a2 4d aa 11 c0       	mov    %al,0xc011aa4d
c01019e2:	0f b6 05 4d aa 11 c0 	movzbl 0xc011aa4d,%eax
c01019e9:	83 c8 80             	or     $0xffffff80,%eax
c01019ec:	a2 4d aa 11 c0       	mov    %al,0xc011aa4d
c01019f1:	a1 c4 77 11 c0       	mov    0xc01177c4,%eax
c01019f6:	c1 e8 10             	shr    $0x10,%eax
c01019f9:	66 a3 4e aa 11 c0    	mov    %ax,0xc011aa4e
c01019ff:	c7 45 f8 60 75 11 c0 	movl   $0xc0117560,-0x8(%ebp)
    }
}

static inline void
lidt(struct pseudodesc *pd) {
    asm volatile ("lidt (%0)" :: "r" (pd) : "memory");
c0101a06:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0101a09:	0f 01 18             	lidtl  (%eax)
      lidt(&idt_pd);
      
      
}
c0101a0c:	90                   	nop
c0101a0d:	c9                   	leave  
c0101a0e:	c3                   	ret    

c0101a0f <trapname>:

static const char *
trapname(int trapno) {
c0101a0f:	55                   	push   %ebp
c0101a10:	89 e5                	mov    %esp,%ebp
        "Alignment Check",
        "Machine-Check",
        "SIMD Floating-Point Exception"
    };

    if (trapno < sizeof(excnames)/sizeof(const char * const)) {
c0101a12:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a15:	83 f8 13             	cmp    $0x13,%eax
c0101a18:	77 0c                	ja     c0101a26 <trapname+0x17>
        return excnames[trapno];
c0101a1a:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a1d:	8b 04 85 e0 62 10 c0 	mov    -0x3fef9d20(,%eax,4),%eax
c0101a24:	eb 18                	jmp    c0101a3e <trapname+0x2f>
    }
    if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16) {
c0101a26:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
c0101a2a:	7e 0d                	jle    c0101a39 <trapname+0x2a>
c0101a2c:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
c0101a30:	7f 07                	jg     c0101a39 <trapname+0x2a>
        return "Hardware Interrupt";
c0101a32:	b8 8a 5f 10 c0       	mov    $0xc0105f8a,%eax
c0101a37:	eb 05                	jmp    c0101a3e <trapname+0x2f>
    }
    return "(unknown trap)";
c0101a39:	b8 9d 5f 10 c0       	mov    $0xc0105f9d,%eax
}
c0101a3e:	5d                   	pop    %ebp
c0101a3f:	c3                   	ret    

c0101a40 <trap_in_kernel>:

/* trap_in_kernel - test if trap happened in kernel */
bool
trap_in_kernel(struct trapframe *tf) {
c0101a40:	55                   	push   %ebp
c0101a41:	89 e5                	mov    %esp,%ebp
    return (tf->tf_cs == (uint16_t)KERNEL_CS);
c0101a43:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a46:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101a4a:	66 83 f8 08          	cmp    $0x8,%ax
c0101a4e:	0f 94 c0             	sete   %al
c0101a51:	0f b6 c0             	movzbl %al,%eax
}
c0101a54:	5d                   	pop    %ebp
c0101a55:	c3                   	ret    

c0101a56 <print_trapframe>:
    "TF", "IF", "DF", "OF", NULL, NULL, "NT", NULL,
    "RF", "VM", "AC", "VIF", "VIP", "ID", NULL, NULL,
};

void
print_trapframe(struct trapframe *tf) {
c0101a56:	55                   	push   %ebp
c0101a57:	89 e5                	mov    %esp,%ebp
c0101a59:	83 ec 18             	sub    $0x18,%esp
    cprintf("trapframe at %p\n", tf);
c0101a5c:	83 ec 08             	sub    $0x8,%esp
c0101a5f:	ff 75 08             	pushl  0x8(%ebp)
c0101a62:	68 de 5f 10 c0       	push   $0xc0105fde
c0101a67:	e8 11 e8 ff ff       	call   c010027d <cprintf>
c0101a6c:	83 c4 10             	add    $0x10,%esp
    print_regs(&tf->tf_regs);
c0101a6f:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a72:	83 ec 0c             	sub    $0xc,%esp
c0101a75:	50                   	push   %eax
c0101a76:	e8 b8 01 00 00       	call   c0101c33 <print_regs>
c0101a7b:	83 c4 10             	add    $0x10,%esp
    cprintf("  ds   0x----%04x\n", tf->tf_ds);
c0101a7e:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a81:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
c0101a85:	0f b7 c0             	movzwl %ax,%eax
c0101a88:	83 ec 08             	sub    $0x8,%esp
c0101a8b:	50                   	push   %eax
c0101a8c:	68 ef 5f 10 c0       	push   $0xc0105fef
c0101a91:	e8 e7 e7 ff ff       	call   c010027d <cprintf>
c0101a96:	83 c4 10             	add    $0x10,%esp
    cprintf("  es   0x----%04x\n", tf->tf_es);
c0101a99:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a9c:	0f b7 40 28          	movzwl 0x28(%eax),%eax
c0101aa0:	0f b7 c0             	movzwl %ax,%eax
c0101aa3:	83 ec 08             	sub    $0x8,%esp
c0101aa6:	50                   	push   %eax
c0101aa7:	68 02 60 10 c0       	push   $0xc0106002
c0101aac:	e8 cc e7 ff ff       	call   c010027d <cprintf>
c0101ab1:	83 c4 10             	add    $0x10,%esp
    cprintf("  fs   0x----%04x\n", tf->tf_fs);
c0101ab4:	8b 45 08             	mov    0x8(%ebp),%eax
c0101ab7:	0f b7 40 24          	movzwl 0x24(%eax),%eax
c0101abb:	0f b7 c0             	movzwl %ax,%eax
c0101abe:	83 ec 08             	sub    $0x8,%esp
c0101ac1:	50                   	push   %eax
c0101ac2:	68 15 60 10 c0       	push   $0xc0106015
c0101ac7:	e8 b1 e7 ff ff       	call   c010027d <cprintf>
c0101acc:	83 c4 10             	add    $0x10,%esp
    cprintf("  gs   0x----%04x\n", tf->tf_gs);
c0101acf:	8b 45 08             	mov    0x8(%ebp),%eax
c0101ad2:	0f b7 40 20          	movzwl 0x20(%eax),%eax
c0101ad6:	0f b7 c0             	movzwl %ax,%eax
c0101ad9:	83 ec 08             	sub    $0x8,%esp
c0101adc:	50                   	push   %eax
c0101add:	68 28 60 10 c0       	push   $0xc0106028
c0101ae2:	e8 96 e7 ff ff       	call   c010027d <cprintf>
c0101ae7:	83 c4 10             	add    $0x10,%esp
    cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
c0101aea:	8b 45 08             	mov    0x8(%ebp),%eax
c0101aed:	8b 40 30             	mov    0x30(%eax),%eax
c0101af0:	83 ec 0c             	sub    $0xc,%esp
c0101af3:	50                   	push   %eax
c0101af4:	e8 16 ff ff ff       	call   c0101a0f <trapname>
c0101af9:	83 c4 10             	add    $0x10,%esp
c0101afc:	89 c2                	mov    %eax,%edx
c0101afe:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b01:	8b 40 30             	mov    0x30(%eax),%eax
c0101b04:	83 ec 04             	sub    $0x4,%esp
c0101b07:	52                   	push   %edx
c0101b08:	50                   	push   %eax
c0101b09:	68 3b 60 10 c0       	push   $0xc010603b
c0101b0e:	e8 6a e7 ff ff       	call   c010027d <cprintf>
c0101b13:	83 c4 10             	add    $0x10,%esp
    cprintf("  err  0x%08x\n", tf->tf_err);
c0101b16:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b19:	8b 40 34             	mov    0x34(%eax),%eax
c0101b1c:	83 ec 08             	sub    $0x8,%esp
c0101b1f:	50                   	push   %eax
c0101b20:	68 4d 60 10 c0       	push   $0xc010604d
c0101b25:	e8 53 e7 ff ff       	call   c010027d <cprintf>
c0101b2a:	83 c4 10             	add    $0x10,%esp
    cprintf("  eip  0x%08x\n", tf->tf_eip);
c0101b2d:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b30:	8b 40 38             	mov    0x38(%eax),%eax
c0101b33:	83 ec 08             	sub    $0x8,%esp
c0101b36:	50                   	push   %eax
c0101b37:	68 5c 60 10 c0       	push   $0xc010605c
c0101b3c:	e8 3c e7 ff ff       	call   c010027d <cprintf>
c0101b41:	83 c4 10             	add    $0x10,%esp
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
c0101b44:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b47:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101b4b:	0f b7 c0             	movzwl %ax,%eax
c0101b4e:	83 ec 08             	sub    $0x8,%esp
c0101b51:	50                   	push   %eax
c0101b52:	68 6b 60 10 c0       	push   $0xc010606b
c0101b57:	e8 21 e7 ff ff       	call   c010027d <cprintf>
c0101b5c:	83 c4 10             	add    $0x10,%esp
    cprintf("  flag 0x%08x ", tf->tf_eflags);
c0101b5f:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b62:	8b 40 40             	mov    0x40(%eax),%eax
c0101b65:	83 ec 08             	sub    $0x8,%esp
c0101b68:	50                   	push   %eax
c0101b69:	68 7e 60 10 c0       	push   $0xc010607e
c0101b6e:	e8 0a e7 ff ff       	call   c010027d <cprintf>
c0101b73:	83 c4 10             	add    $0x10,%esp

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
c0101b76:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0101b7d:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
c0101b84:	eb 3f                	jmp    c0101bc5 <print_trapframe+0x16f>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
c0101b86:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b89:	8b 50 40             	mov    0x40(%eax),%edx
c0101b8c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0101b8f:	21 d0                	and    %edx,%eax
c0101b91:	85 c0                	test   %eax,%eax
c0101b93:	74 29                	je     c0101bbe <print_trapframe+0x168>
c0101b95:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101b98:	8b 04 85 80 75 11 c0 	mov    -0x3fee8a80(,%eax,4),%eax
c0101b9f:	85 c0                	test   %eax,%eax
c0101ba1:	74 1b                	je     c0101bbe <print_trapframe+0x168>
            cprintf("%s,", IA32flags[i]);
c0101ba3:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101ba6:	8b 04 85 80 75 11 c0 	mov    -0x3fee8a80(,%eax,4),%eax
c0101bad:	83 ec 08             	sub    $0x8,%esp
c0101bb0:	50                   	push   %eax
c0101bb1:	68 8d 60 10 c0       	push   $0xc010608d
c0101bb6:	e8 c2 e6 ff ff       	call   c010027d <cprintf>
c0101bbb:	83 c4 10             	add    $0x10,%esp
    cprintf("  eip  0x%08x\n", tf->tf_eip);
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
    cprintf("  flag 0x%08x ", tf->tf_eflags);

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
c0101bbe:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0101bc2:	d1 65 f0             	shll   -0x10(%ebp)
c0101bc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101bc8:	83 f8 17             	cmp    $0x17,%eax
c0101bcb:	76 b9                	jbe    c0101b86 <print_trapframe+0x130>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
            cprintf("%s,", IA32flags[i]);
        }
    }
    cprintf("IOPL=%d\n", (tf->tf_eflags & FL_IOPL_MASK) >> 12);
c0101bcd:	8b 45 08             	mov    0x8(%ebp),%eax
c0101bd0:	8b 40 40             	mov    0x40(%eax),%eax
c0101bd3:	25 00 30 00 00       	and    $0x3000,%eax
c0101bd8:	c1 e8 0c             	shr    $0xc,%eax
c0101bdb:	83 ec 08             	sub    $0x8,%esp
c0101bde:	50                   	push   %eax
c0101bdf:	68 91 60 10 c0       	push   $0xc0106091
c0101be4:	e8 94 e6 ff ff       	call   c010027d <cprintf>
c0101be9:	83 c4 10             	add    $0x10,%esp

    if (!trap_in_kernel(tf)) {
c0101bec:	83 ec 0c             	sub    $0xc,%esp
c0101bef:	ff 75 08             	pushl  0x8(%ebp)
c0101bf2:	e8 49 fe ff ff       	call   c0101a40 <trap_in_kernel>
c0101bf7:	83 c4 10             	add    $0x10,%esp
c0101bfa:	85 c0                	test   %eax,%eax
c0101bfc:	75 32                	jne    c0101c30 <print_trapframe+0x1da>
        cprintf("  esp  0x%08x\n", tf->tf_esp);
c0101bfe:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c01:	8b 40 44             	mov    0x44(%eax),%eax
c0101c04:	83 ec 08             	sub    $0x8,%esp
c0101c07:	50                   	push   %eax
c0101c08:	68 9a 60 10 c0       	push   $0xc010609a
c0101c0d:	e8 6b e6 ff ff       	call   c010027d <cprintf>
c0101c12:	83 c4 10             	add    $0x10,%esp
        cprintf("  ss   0x----%04x\n", tf->tf_ss);
c0101c15:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c18:	0f b7 40 48          	movzwl 0x48(%eax),%eax
c0101c1c:	0f b7 c0             	movzwl %ax,%eax
c0101c1f:	83 ec 08             	sub    $0x8,%esp
c0101c22:	50                   	push   %eax
c0101c23:	68 a9 60 10 c0       	push   $0xc01060a9
c0101c28:	e8 50 e6 ff ff       	call   c010027d <cprintf>
c0101c2d:	83 c4 10             	add    $0x10,%esp
    }
}
c0101c30:	90                   	nop
c0101c31:	c9                   	leave  
c0101c32:	c3                   	ret    

c0101c33 <print_regs>:

void
print_regs(struct pushregs *regs) {
c0101c33:	55                   	push   %ebp
c0101c34:	89 e5                	mov    %esp,%ebp
c0101c36:	83 ec 08             	sub    $0x8,%esp
    cprintf("  edi  0x%08x\n", regs->reg_edi);
c0101c39:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c3c:	8b 00                	mov    (%eax),%eax
c0101c3e:	83 ec 08             	sub    $0x8,%esp
c0101c41:	50                   	push   %eax
c0101c42:	68 bc 60 10 c0       	push   $0xc01060bc
c0101c47:	e8 31 e6 ff ff       	call   c010027d <cprintf>
c0101c4c:	83 c4 10             	add    $0x10,%esp
    cprintf("  esi  0x%08x\n", regs->reg_esi);
c0101c4f:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c52:	8b 40 04             	mov    0x4(%eax),%eax
c0101c55:	83 ec 08             	sub    $0x8,%esp
c0101c58:	50                   	push   %eax
c0101c59:	68 cb 60 10 c0       	push   $0xc01060cb
c0101c5e:	e8 1a e6 ff ff       	call   c010027d <cprintf>
c0101c63:	83 c4 10             	add    $0x10,%esp
    cprintf("  ebp  0x%08x\n", regs->reg_ebp);
c0101c66:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c69:	8b 40 08             	mov    0x8(%eax),%eax
c0101c6c:	83 ec 08             	sub    $0x8,%esp
c0101c6f:	50                   	push   %eax
c0101c70:	68 da 60 10 c0       	push   $0xc01060da
c0101c75:	e8 03 e6 ff ff       	call   c010027d <cprintf>
c0101c7a:	83 c4 10             	add    $0x10,%esp
    cprintf("  oesp 0x%08x\n", regs->reg_oesp);
c0101c7d:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c80:	8b 40 0c             	mov    0xc(%eax),%eax
c0101c83:	83 ec 08             	sub    $0x8,%esp
c0101c86:	50                   	push   %eax
c0101c87:	68 e9 60 10 c0       	push   $0xc01060e9
c0101c8c:	e8 ec e5 ff ff       	call   c010027d <cprintf>
c0101c91:	83 c4 10             	add    $0x10,%esp
    cprintf("  ebx  0x%08x\n", regs->reg_ebx);
c0101c94:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c97:	8b 40 10             	mov    0x10(%eax),%eax
c0101c9a:	83 ec 08             	sub    $0x8,%esp
c0101c9d:	50                   	push   %eax
c0101c9e:	68 f8 60 10 c0       	push   $0xc01060f8
c0101ca3:	e8 d5 e5 ff ff       	call   c010027d <cprintf>
c0101ca8:	83 c4 10             	add    $0x10,%esp
    cprintf("  edx  0x%08x\n", regs->reg_edx);
c0101cab:	8b 45 08             	mov    0x8(%ebp),%eax
c0101cae:	8b 40 14             	mov    0x14(%eax),%eax
c0101cb1:	83 ec 08             	sub    $0x8,%esp
c0101cb4:	50                   	push   %eax
c0101cb5:	68 07 61 10 c0       	push   $0xc0106107
c0101cba:	e8 be e5 ff ff       	call   c010027d <cprintf>
c0101cbf:	83 c4 10             	add    $0x10,%esp
    cprintf("  ecx  0x%08x\n", regs->reg_ecx);
c0101cc2:	8b 45 08             	mov    0x8(%ebp),%eax
c0101cc5:	8b 40 18             	mov    0x18(%eax),%eax
c0101cc8:	83 ec 08             	sub    $0x8,%esp
c0101ccb:	50                   	push   %eax
c0101ccc:	68 16 61 10 c0       	push   $0xc0106116
c0101cd1:	e8 a7 e5 ff ff       	call   c010027d <cprintf>
c0101cd6:	83 c4 10             	add    $0x10,%esp
    cprintf("  eax  0x%08x\n", regs->reg_eax);
c0101cd9:	8b 45 08             	mov    0x8(%ebp),%eax
c0101cdc:	8b 40 1c             	mov    0x1c(%eax),%eax
c0101cdf:	83 ec 08             	sub    $0x8,%esp
c0101ce2:	50                   	push   %eax
c0101ce3:	68 25 61 10 c0       	push   $0xc0106125
c0101ce8:	e8 90 e5 ff ff       	call   c010027d <cprintf>
c0101ced:	83 c4 10             	add    $0x10,%esp
}
c0101cf0:	90                   	nop
c0101cf1:	c9                   	leave  
c0101cf2:	c3                   	ret    

c0101cf3 <trap_dispatch>:

/* trap_dispatch - dispatch based on what type of trap occurred */
static void
trap_dispatch(struct trapframe *tf) {
c0101cf3:	55                   	push   %ebp
c0101cf4:	89 e5                	mov    %esp,%ebp
c0101cf6:	83 ec 18             	sub    $0x18,%esp
    char c;

    switch (tf->tf_trapno) {
c0101cf9:	8b 45 08             	mov    0x8(%ebp),%eax
c0101cfc:	8b 40 30             	mov    0x30(%eax),%eax
c0101cff:	83 f8 2f             	cmp    $0x2f,%eax
c0101d02:	77 21                	ja     c0101d25 <trap_dispatch+0x32>
c0101d04:	83 f8 2e             	cmp    $0x2e,%eax
c0101d07:	0f 83 be 01 00 00    	jae    c0101ecb <trap_dispatch+0x1d8>
c0101d0d:	83 f8 21             	cmp    $0x21,%eax
c0101d10:	0f 84 91 00 00 00    	je     c0101da7 <trap_dispatch+0xb4>
c0101d16:	83 f8 24             	cmp    $0x24,%eax
c0101d19:	74 65                	je     c0101d80 <trap_dispatch+0x8d>
c0101d1b:	83 f8 20             	cmp    $0x20,%eax
c0101d1e:	74 1c                	je     c0101d3c <trap_dispatch+0x49>
c0101d20:	e9 70 01 00 00       	jmp    c0101e95 <trap_dispatch+0x1a2>
c0101d25:	83 f8 78             	cmp    $0x78,%eax
c0101d28:	0f 84 a0 00 00 00    	je     c0101dce <trap_dispatch+0xdb>
c0101d2e:	83 f8 79             	cmp    $0x79,%eax
c0101d31:	0f 84 fe 00 00 00    	je     c0101e35 <trap_dispatch+0x142>
c0101d37:	e9 59 01 00 00       	jmp    c0101e95 <trap_dispatch+0x1a2>
        /* handle the timer interrupt */
        /* (1) After a timer interrupt, you should record this event using a global variable (increase it), such as ticks in kern/driver/clock.c
         * (2) Every TICK_NUM cycle, you can print some info using a funciton, such as print_ticks().
         * (3) Too Simple? Yes, I think so!
         */
        ticks++;
c0101d3c:	a1 0c af 11 c0       	mov    0xc011af0c,%eax
c0101d41:	83 c0 01             	add    $0x1,%eax
c0101d44:	a3 0c af 11 c0       	mov    %eax,0xc011af0c
        if(ticks % TICK_NUM == 0){
c0101d49:	8b 0d 0c af 11 c0    	mov    0xc011af0c,%ecx
c0101d4f:	ba 1f 85 eb 51       	mov    $0x51eb851f,%edx
c0101d54:	89 c8                	mov    %ecx,%eax
c0101d56:	f7 e2                	mul    %edx
c0101d58:	89 d0                	mov    %edx,%eax
c0101d5a:	c1 e8 05             	shr    $0x5,%eax
c0101d5d:	6b c0 64             	imul   $0x64,%eax,%eax
c0101d60:	29 c1                	sub    %eax,%ecx
c0101d62:	89 c8                	mov    %ecx,%eax
c0101d64:	85 c0                	test   %eax,%eax
c0101d66:	0f 85 62 01 00 00    	jne    c0101ece <trap_dispatch+0x1db>
            print_ticks();
c0101d6c:	e8 15 fb ff ff       	call   c0101886 <print_ticks>
            ticks=0;
c0101d71:	c7 05 0c af 11 c0 00 	movl   $0x0,0xc011af0c
c0101d78:	00 00 00 
        }
        break;
c0101d7b:	e9 4e 01 00 00       	jmp    c0101ece <trap_dispatch+0x1db>
    case IRQ_OFFSET + IRQ_COM1:
        c = cons_getc();
c0101d80:	e8 be f8 ff ff       	call   c0101643 <cons_getc>
c0101d85:	88 45 f7             	mov    %al,-0x9(%ebp)
        cprintf("serial [%03d] %c\n", c, c);
c0101d88:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
c0101d8c:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c0101d90:	83 ec 04             	sub    $0x4,%esp
c0101d93:	52                   	push   %edx
c0101d94:	50                   	push   %eax
c0101d95:	68 34 61 10 c0       	push   $0xc0106134
c0101d9a:	e8 de e4 ff ff       	call   c010027d <cprintf>
c0101d9f:	83 c4 10             	add    $0x10,%esp
	
	
        break;
c0101da2:	e9 2e 01 00 00       	jmp    c0101ed5 <trap_dispatch+0x1e2>
    case IRQ_OFFSET + IRQ_KBD:
        c = cons_getc();
c0101da7:	e8 97 f8 ff ff       	call   c0101643 <cons_getc>
c0101dac:	88 45 f7             	mov    %al,-0x9(%ebp)
        cprintf("kbd [%03d] %c\n", c, c);
c0101daf:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
c0101db3:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c0101db7:	83 ec 04             	sub    $0x4,%esp
c0101dba:	52                   	push   %edx
c0101dbb:	50                   	push   %eax
c0101dbc:	68 46 61 10 c0       	push   $0xc0106146
c0101dc1:	e8 b7 e4 ff ff       	call   c010027d <cprintf>
c0101dc6:	83 c4 10             	add    $0x10,%esp
	   tf->tf_ds=tf->tf_gs=tf->tf_fs=tf->tf_es = KERNEL_DS;
	   tf->tf_eflags = tf->tf_eflags&(~FL_IOPL_MASK);
	   print_trapframe(tf);
	   }
	}*/
        break;
c0101dc9:	e9 07 01 00 00       	jmp    c0101ed5 <trap_dispatch+0x1e2>
    //LAB1 CHALLENGE 1 : YOUR CODE you should modify below codes.
    case T_SWITCH_TOU:
	if(tf->tf_cs !=USER_CS){
c0101dce:	8b 45 08             	mov    0x8(%ebp),%eax
c0101dd1:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101dd5:	66 83 f8 1b          	cmp    $0x1b,%ax
c0101dd9:	0f 84 f2 00 00 00    	je     c0101ed1 <trap_dispatch+0x1de>
	   tf->tf_cs=USER_CS;
c0101ddf:	8b 45 08             	mov    0x8(%ebp),%eax
c0101de2:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
	   tf->tf_ds=USER_DS;
c0101de8:	8b 45 08             	mov    0x8(%ebp),%eax
c0101deb:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
	   tf->tf_gs=tf->tf_fs=tf->tf_es = USER_DS;
c0101df1:	8b 45 08             	mov    0x8(%ebp),%eax
c0101df4:	66 c7 40 28 23 00    	movw   $0x23,0x28(%eax)
c0101dfa:	8b 45 08             	mov    0x8(%ebp),%eax
c0101dfd:	0f b7 50 28          	movzwl 0x28(%eax),%edx
c0101e01:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e04:	66 89 50 24          	mov    %dx,0x24(%eax)
c0101e08:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e0b:	0f b7 50 24          	movzwl 0x24(%eax),%edx
c0101e0f:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e12:	66 89 50 20          	mov    %dx,0x20(%eax)
	   tf->tf_eflags = tf->tf_eflags|FL_IOPL_MASK;
c0101e16:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e19:	8b 40 40             	mov    0x40(%eax),%eax
c0101e1c:	80 cc 30             	or     $0x30,%ah
c0101e1f:	89 c2                	mov    %eax,%edx
c0101e21:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e24:	89 50 40             	mov    %edx,0x40(%eax)
	   tf->tf_ss=USER_DS;
c0101e27:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e2a:	66 c7 40 48 23 00    	movw   $0x23,0x48(%eax)
	  }
	break;
c0101e30:	e9 9c 00 00 00       	jmp    c0101ed1 <trap_dispatch+0x1de>
    case T_SWITCH_TOK:
	if(tf->tf_cs !=KERNEL_CS){
c0101e35:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e38:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101e3c:	66 83 f8 08          	cmp    $0x8,%ax
c0101e40:	0f 84 8e 00 00 00    	je     c0101ed4 <trap_dispatch+0x1e1>
	   tf->tf_cs =KERNEL_CS;
c0101e46:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e49:	66 c7 40 3c 08 00    	movw   $0x8,0x3c(%eax)
	   tf->tf_ds=tf->tf_gs=tf->tf_fs=tf->tf_es = KERNEL_DS;
c0101e4f:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e52:	66 c7 40 28 10 00    	movw   $0x10,0x28(%eax)
c0101e58:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e5b:	0f b7 50 28          	movzwl 0x28(%eax),%edx
c0101e5f:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e62:	66 89 50 24          	mov    %dx,0x24(%eax)
c0101e66:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e69:	0f b7 50 24          	movzwl 0x24(%eax),%edx
c0101e6d:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e70:	66 89 50 20          	mov    %dx,0x20(%eax)
c0101e74:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e77:	0f b7 50 20          	movzwl 0x20(%eax),%edx
c0101e7b:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e7e:	66 89 50 2c          	mov    %dx,0x2c(%eax)
	   tf->tf_eflags = tf->tf_eflags&(~FL_IOPL_MASK);
c0101e82:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e85:	8b 40 40             	mov    0x40(%eax),%eax
c0101e88:	80 e4 cf             	and    $0xcf,%ah
c0101e8b:	89 c2                	mov    %eax,%edx
c0101e8d:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e90:	89 50 40             	mov    %edx,0x40(%eax)
	   
	}
        break;
c0101e93:	eb 3f                	jmp    c0101ed4 <trap_dispatch+0x1e1>
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
    default:
        // in kernel, it must be a mistake
        if ((tf->tf_cs & 3) == 0) {
c0101e95:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e98:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101e9c:	0f b7 c0             	movzwl %ax,%eax
c0101e9f:	83 e0 03             	and    $0x3,%eax
c0101ea2:	85 c0                	test   %eax,%eax
c0101ea4:	75 2f                	jne    c0101ed5 <trap_dispatch+0x1e2>
            print_trapframe(tf);
c0101ea6:	83 ec 0c             	sub    $0xc,%esp
c0101ea9:	ff 75 08             	pushl  0x8(%ebp)
c0101eac:	e8 a5 fb ff ff       	call   c0101a56 <print_trapframe>
c0101eb1:	83 c4 10             	add    $0x10,%esp
            panic("unexpected trap in kernel.\n");
c0101eb4:	83 ec 04             	sub    $0x4,%esp
c0101eb7:	68 55 61 10 c0       	push   $0xc0106155
c0101ebc:	68 da 00 00 00       	push   $0xda
c0101ec1:	68 71 61 10 c0       	push   $0xc0106171
c0101ec6:	e8 18 e5 ff ff       	call   c01003e3 <__panic>
	}
        break;
    case IRQ_OFFSET + IRQ_IDE1:
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
c0101ecb:	90                   	nop
c0101ecc:	eb 07                	jmp    c0101ed5 <trap_dispatch+0x1e2>
        ticks++;
        if(ticks % TICK_NUM == 0){
            print_ticks();
            ticks=0;
        }
        break;
c0101ece:	90                   	nop
c0101ecf:	eb 04                	jmp    c0101ed5 <trap_dispatch+0x1e2>
	   tf->tf_ds=USER_DS;
	   tf->tf_gs=tf->tf_fs=tf->tf_es = USER_DS;
	   tf->tf_eflags = tf->tf_eflags|FL_IOPL_MASK;
	   tf->tf_ss=USER_DS;
	  }
	break;
c0101ed1:	90                   	nop
c0101ed2:	eb 01                	jmp    c0101ed5 <trap_dispatch+0x1e2>
	   tf->tf_cs =KERNEL_CS;
	   tf->tf_ds=tf->tf_gs=tf->tf_fs=tf->tf_es = KERNEL_DS;
	   tf->tf_eflags = tf->tf_eflags&(~FL_IOPL_MASK);
	   
	}
        break;
c0101ed4:	90                   	nop
        if ((tf->tf_cs & 3) == 0) {
            print_trapframe(tf);
            panic("unexpected trap in kernel.\n");
        }
    }
}
c0101ed5:	90                   	nop
c0101ed6:	c9                   	leave  
c0101ed7:	c3                   	ret    

c0101ed8 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
c0101ed8:	55                   	push   %ebp
c0101ed9:	89 e5                	mov    %esp,%ebp
c0101edb:	83 ec 08             	sub    $0x8,%esp
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
c0101ede:	83 ec 0c             	sub    $0xc,%esp
c0101ee1:	ff 75 08             	pushl  0x8(%ebp)
c0101ee4:	e8 0a fe ff ff       	call   c0101cf3 <trap_dispatch>
c0101ee9:	83 c4 10             	add    $0x10,%esp
}
c0101eec:	90                   	nop
c0101eed:	c9                   	leave  
c0101eee:	c3                   	ret    

c0101eef <vector0>:
# handler
.text
.globl __alltraps
.globl vector0
vector0:
  pushl $0
c0101eef:	6a 00                	push   $0x0
  pushl $0
c0101ef1:	6a 00                	push   $0x0
  jmp __alltraps
c0101ef3:	e9 69 0a 00 00       	jmp    c0102961 <__alltraps>

c0101ef8 <vector1>:
.globl vector1
vector1:
  pushl $0
c0101ef8:	6a 00                	push   $0x0
  pushl $1
c0101efa:	6a 01                	push   $0x1
  jmp __alltraps
c0101efc:	e9 60 0a 00 00       	jmp    c0102961 <__alltraps>

c0101f01 <vector2>:
.globl vector2
vector2:
  pushl $0
c0101f01:	6a 00                	push   $0x0
  pushl $2
c0101f03:	6a 02                	push   $0x2
  jmp __alltraps
c0101f05:	e9 57 0a 00 00       	jmp    c0102961 <__alltraps>

c0101f0a <vector3>:
.globl vector3
vector3:
  pushl $0
c0101f0a:	6a 00                	push   $0x0
  pushl $3
c0101f0c:	6a 03                	push   $0x3
  jmp __alltraps
c0101f0e:	e9 4e 0a 00 00       	jmp    c0102961 <__alltraps>

c0101f13 <vector4>:
.globl vector4
vector4:
  pushl $0
c0101f13:	6a 00                	push   $0x0
  pushl $4
c0101f15:	6a 04                	push   $0x4
  jmp __alltraps
c0101f17:	e9 45 0a 00 00       	jmp    c0102961 <__alltraps>

c0101f1c <vector5>:
.globl vector5
vector5:
  pushl $0
c0101f1c:	6a 00                	push   $0x0
  pushl $5
c0101f1e:	6a 05                	push   $0x5
  jmp __alltraps
c0101f20:	e9 3c 0a 00 00       	jmp    c0102961 <__alltraps>

c0101f25 <vector6>:
.globl vector6
vector6:
  pushl $0
c0101f25:	6a 00                	push   $0x0
  pushl $6
c0101f27:	6a 06                	push   $0x6
  jmp __alltraps
c0101f29:	e9 33 0a 00 00       	jmp    c0102961 <__alltraps>

c0101f2e <vector7>:
.globl vector7
vector7:
  pushl $0
c0101f2e:	6a 00                	push   $0x0
  pushl $7
c0101f30:	6a 07                	push   $0x7
  jmp __alltraps
c0101f32:	e9 2a 0a 00 00       	jmp    c0102961 <__alltraps>

c0101f37 <vector8>:
.globl vector8
vector8:
  pushl $8
c0101f37:	6a 08                	push   $0x8
  jmp __alltraps
c0101f39:	e9 23 0a 00 00       	jmp    c0102961 <__alltraps>

c0101f3e <vector9>:
.globl vector9
vector9:
  pushl $0
c0101f3e:	6a 00                	push   $0x0
  pushl $9
c0101f40:	6a 09                	push   $0x9
  jmp __alltraps
c0101f42:	e9 1a 0a 00 00       	jmp    c0102961 <__alltraps>

c0101f47 <vector10>:
.globl vector10
vector10:
  pushl $10
c0101f47:	6a 0a                	push   $0xa
  jmp __alltraps
c0101f49:	e9 13 0a 00 00       	jmp    c0102961 <__alltraps>

c0101f4e <vector11>:
.globl vector11
vector11:
  pushl $11
c0101f4e:	6a 0b                	push   $0xb
  jmp __alltraps
c0101f50:	e9 0c 0a 00 00       	jmp    c0102961 <__alltraps>

c0101f55 <vector12>:
.globl vector12
vector12:
  pushl $12
c0101f55:	6a 0c                	push   $0xc
  jmp __alltraps
c0101f57:	e9 05 0a 00 00       	jmp    c0102961 <__alltraps>

c0101f5c <vector13>:
.globl vector13
vector13:
  pushl $13
c0101f5c:	6a 0d                	push   $0xd
  jmp __alltraps
c0101f5e:	e9 fe 09 00 00       	jmp    c0102961 <__alltraps>

c0101f63 <vector14>:
.globl vector14
vector14:
  pushl $14
c0101f63:	6a 0e                	push   $0xe
  jmp __alltraps
c0101f65:	e9 f7 09 00 00       	jmp    c0102961 <__alltraps>

c0101f6a <vector15>:
.globl vector15
vector15:
  pushl $0
c0101f6a:	6a 00                	push   $0x0
  pushl $15
c0101f6c:	6a 0f                	push   $0xf
  jmp __alltraps
c0101f6e:	e9 ee 09 00 00       	jmp    c0102961 <__alltraps>

c0101f73 <vector16>:
.globl vector16
vector16:
  pushl $0
c0101f73:	6a 00                	push   $0x0
  pushl $16
c0101f75:	6a 10                	push   $0x10
  jmp __alltraps
c0101f77:	e9 e5 09 00 00       	jmp    c0102961 <__alltraps>

c0101f7c <vector17>:
.globl vector17
vector17:
  pushl $17
c0101f7c:	6a 11                	push   $0x11
  jmp __alltraps
c0101f7e:	e9 de 09 00 00       	jmp    c0102961 <__alltraps>

c0101f83 <vector18>:
.globl vector18
vector18:
  pushl $0
c0101f83:	6a 00                	push   $0x0
  pushl $18
c0101f85:	6a 12                	push   $0x12
  jmp __alltraps
c0101f87:	e9 d5 09 00 00       	jmp    c0102961 <__alltraps>

c0101f8c <vector19>:
.globl vector19
vector19:
  pushl $0
c0101f8c:	6a 00                	push   $0x0
  pushl $19
c0101f8e:	6a 13                	push   $0x13
  jmp __alltraps
c0101f90:	e9 cc 09 00 00       	jmp    c0102961 <__alltraps>

c0101f95 <vector20>:
.globl vector20
vector20:
  pushl $0
c0101f95:	6a 00                	push   $0x0
  pushl $20
c0101f97:	6a 14                	push   $0x14
  jmp __alltraps
c0101f99:	e9 c3 09 00 00       	jmp    c0102961 <__alltraps>

c0101f9e <vector21>:
.globl vector21
vector21:
  pushl $0
c0101f9e:	6a 00                	push   $0x0
  pushl $21
c0101fa0:	6a 15                	push   $0x15
  jmp __alltraps
c0101fa2:	e9 ba 09 00 00       	jmp    c0102961 <__alltraps>

c0101fa7 <vector22>:
.globl vector22
vector22:
  pushl $0
c0101fa7:	6a 00                	push   $0x0
  pushl $22
c0101fa9:	6a 16                	push   $0x16
  jmp __alltraps
c0101fab:	e9 b1 09 00 00       	jmp    c0102961 <__alltraps>

c0101fb0 <vector23>:
.globl vector23
vector23:
  pushl $0
c0101fb0:	6a 00                	push   $0x0
  pushl $23
c0101fb2:	6a 17                	push   $0x17
  jmp __alltraps
c0101fb4:	e9 a8 09 00 00       	jmp    c0102961 <__alltraps>

c0101fb9 <vector24>:
.globl vector24
vector24:
  pushl $0
c0101fb9:	6a 00                	push   $0x0
  pushl $24
c0101fbb:	6a 18                	push   $0x18
  jmp __alltraps
c0101fbd:	e9 9f 09 00 00       	jmp    c0102961 <__alltraps>

c0101fc2 <vector25>:
.globl vector25
vector25:
  pushl $0
c0101fc2:	6a 00                	push   $0x0
  pushl $25
c0101fc4:	6a 19                	push   $0x19
  jmp __alltraps
c0101fc6:	e9 96 09 00 00       	jmp    c0102961 <__alltraps>

c0101fcb <vector26>:
.globl vector26
vector26:
  pushl $0
c0101fcb:	6a 00                	push   $0x0
  pushl $26
c0101fcd:	6a 1a                	push   $0x1a
  jmp __alltraps
c0101fcf:	e9 8d 09 00 00       	jmp    c0102961 <__alltraps>

c0101fd4 <vector27>:
.globl vector27
vector27:
  pushl $0
c0101fd4:	6a 00                	push   $0x0
  pushl $27
c0101fd6:	6a 1b                	push   $0x1b
  jmp __alltraps
c0101fd8:	e9 84 09 00 00       	jmp    c0102961 <__alltraps>

c0101fdd <vector28>:
.globl vector28
vector28:
  pushl $0
c0101fdd:	6a 00                	push   $0x0
  pushl $28
c0101fdf:	6a 1c                	push   $0x1c
  jmp __alltraps
c0101fe1:	e9 7b 09 00 00       	jmp    c0102961 <__alltraps>

c0101fe6 <vector29>:
.globl vector29
vector29:
  pushl $0
c0101fe6:	6a 00                	push   $0x0
  pushl $29
c0101fe8:	6a 1d                	push   $0x1d
  jmp __alltraps
c0101fea:	e9 72 09 00 00       	jmp    c0102961 <__alltraps>

c0101fef <vector30>:
.globl vector30
vector30:
  pushl $0
c0101fef:	6a 00                	push   $0x0
  pushl $30
c0101ff1:	6a 1e                	push   $0x1e
  jmp __alltraps
c0101ff3:	e9 69 09 00 00       	jmp    c0102961 <__alltraps>

c0101ff8 <vector31>:
.globl vector31
vector31:
  pushl $0
c0101ff8:	6a 00                	push   $0x0
  pushl $31
c0101ffa:	6a 1f                	push   $0x1f
  jmp __alltraps
c0101ffc:	e9 60 09 00 00       	jmp    c0102961 <__alltraps>

c0102001 <vector32>:
.globl vector32
vector32:
  pushl $0
c0102001:	6a 00                	push   $0x0
  pushl $32
c0102003:	6a 20                	push   $0x20
  jmp __alltraps
c0102005:	e9 57 09 00 00       	jmp    c0102961 <__alltraps>

c010200a <vector33>:
.globl vector33
vector33:
  pushl $0
c010200a:	6a 00                	push   $0x0
  pushl $33
c010200c:	6a 21                	push   $0x21
  jmp __alltraps
c010200e:	e9 4e 09 00 00       	jmp    c0102961 <__alltraps>

c0102013 <vector34>:
.globl vector34
vector34:
  pushl $0
c0102013:	6a 00                	push   $0x0
  pushl $34
c0102015:	6a 22                	push   $0x22
  jmp __alltraps
c0102017:	e9 45 09 00 00       	jmp    c0102961 <__alltraps>

c010201c <vector35>:
.globl vector35
vector35:
  pushl $0
c010201c:	6a 00                	push   $0x0
  pushl $35
c010201e:	6a 23                	push   $0x23
  jmp __alltraps
c0102020:	e9 3c 09 00 00       	jmp    c0102961 <__alltraps>

c0102025 <vector36>:
.globl vector36
vector36:
  pushl $0
c0102025:	6a 00                	push   $0x0
  pushl $36
c0102027:	6a 24                	push   $0x24
  jmp __alltraps
c0102029:	e9 33 09 00 00       	jmp    c0102961 <__alltraps>

c010202e <vector37>:
.globl vector37
vector37:
  pushl $0
c010202e:	6a 00                	push   $0x0
  pushl $37
c0102030:	6a 25                	push   $0x25
  jmp __alltraps
c0102032:	e9 2a 09 00 00       	jmp    c0102961 <__alltraps>

c0102037 <vector38>:
.globl vector38
vector38:
  pushl $0
c0102037:	6a 00                	push   $0x0
  pushl $38
c0102039:	6a 26                	push   $0x26
  jmp __alltraps
c010203b:	e9 21 09 00 00       	jmp    c0102961 <__alltraps>

c0102040 <vector39>:
.globl vector39
vector39:
  pushl $0
c0102040:	6a 00                	push   $0x0
  pushl $39
c0102042:	6a 27                	push   $0x27
  jmp __alltraps
c0102044:	e9 18 09 00 00       	jmp    c0102961 <__alltraps>

c0102049 <vector40>:
.globl vector40
vector40:
  pushl $0
c0102049:	6a 00                	push   $0x0
  pushl $40
c010204b:	6a 28                	push   $0x28
  jmp __alltraps
c010204d:	e9 0f 09 00 00       	jmp    c0102961 <__alltraps>

c0102052 <vector41>:
.globl vector41
vector41:
  pushl $0
c0102052:	6a 00                	push   $0x0
  pushl $41
c0102054:	6a 29                	push   $0x29
  jmp __alltraps
c0102056:	e9 06 09 00 00       	jmp    c0102961 <__alltraps>

c010205b <vector42>:
.globl vector42
vector42:
  pushl $0
c010205b:	6a 00                	push   $0x0
  pushl $42
c010205d:	6a 2a                	push   $0x2a
  jmp __alltraps
c010205f:	e9 fd 08 00 00       	jmp    c0102961 <__alltraps>

c0102064 <vector43>:
.globl vector43
vector43:
  pushl $0
c0102064:	6a 00                	push   $0x0
  pushl $43
c0102066:	6a 2b                	push   $0x2b
  jmp __alltraps
c0102068:	e9 f4 08 00 00       	jmp    c0102961 <__alltraps>

c010206d <vector44>:
.globl vector44
vector44:
  pushl $0
c010206d:	6a 00                	push   $0x0
  pushl $44
c010206f:	6a 2c                	push   $0x2c
  jmp __alltraps
c0102071:	e9 eb 08 00 00       	jmp    c0102961 <__alltraps>

c0102076 <vector45>:
.globl vector45
vector45:
  pushl $0
c0102076:	6a 00                	push   $0x0
  pushl $45
c0102078:	6a 2d                	push   $0x2d
  jmp __alltraps
c010207a:	e9 e2 08 00 00       	jmp    c0102961 <__alltraps>

c010207f <vector46>:
.globl vector46
vector46:
  pushl $0
c010207f:	6a 00                	push   $0x0
  pushl $46
c0102081:	6a 2e                	push   $0x2e
  jmp __alltraps
c0102083:	e9 d9 08 00 00       	jmp    c0102961 <__alltraps>

c0102088 <vector47>:
.globl vector47
vector47:
  pushl $0
c0102088:	6a 00                	push   $0x0
  pushl $47
c010208a:	6a 2f                	push   $0x2f
  jmp __alltraps
c010208c:	e9 d0 08 00 00       	jmp    c0102961 <__alltraps>

c0102091 <vector48>:
.globl vector48
vector48:
  pushl $0
c0102091:	6a 00                	push   $0x0
  pushl $48
c0102093:	6a 30                	push   $0x30
  jmp __alltraps
c0102095:	e9 c7 08 00 00       	jmp    c0102961 <__alltraps>

c010209a <vector49>:
.globl vector49
vector49:
  pushl $0
c010209a:	6a 00                	push   $0x0
  pushl $49
c010209c:	6a 31                	push   $0x31
  jmp __alltraps
c010209e:	e9 be 08 00 00       	jmp    c0102961 <__alltraps>

c01020a3 <vector50>:
.globl vector50
vector50:
  pushl $0
c01020a3:	6a 00                	push   $0x0
  pushl $50
c01020a5:	6a 32                	push   $0x32
  jmp __alltraps
c01020a7:	e9 b5 08 00 00       	jmp    c0102961 <__alltraps>

c01020ac <vector51>:
.globl vector51
vector51:
  pushl $0
c01020ac:	6a 00                	push   $0x0
  pushl $51
c01020ae:	6a 33                	push   $0x33
  jmp __alltraps
c01020b0:	e9 ac 08 00 00       	jmp    c0102961 <__alltraps>

c01020b5 <vector52>:
.globl vector52
vector52:
  pushl $0
c01020b5:	6a 00                	push   $0x0
  pushl $52
c01020b7:	6a 34                	push   $0x34
  jmp __alltraps
c01020b9:	e9 a3 08 00 00       	jmp    c0102961 <__alltraps>

c01020be <vector53>:
.globl vector53
vector53:
  pushl $0
c01020be:	6a 00                	push   $0x0
  pushl $53
c01020c0:	6a 35                	push   $0x35
  jmp __alltraps
c01020c2:	e9 9a 08 00 00       	jmp    c0102961 <__alltraps>

c01020c7 <vector54>:
.globl vector54
vector54:
  pushl $0
c01020c7:	6a 00                	push   $0x0
  pushl $54
c01020c9:	6a 36                	push   $0x36
  jmp __alltraps
c01020cb:	e9 91 08 00 00       	jmp    c0102961 <__alltraps>

c01020d0 <vector55>:
.globl vector55
vector55:
  pushl $0
c01020d0:	6a 00                	push   $0x0
  pushl $55
c01020d2:	6a 37                	push   $0x37
  jmp __alltraps
c01020d4:	e9 88 08 00 00       	jmp    c0102961 <__alltraps>

c01020d9 <vector56>:
.globl vector56
vector56:
  pushl $0
c01020d9:	6a 00                	push   $0x0
  pushl $56
c01020db:	6a 38                	push   $0x38
  jmp __alltraps
c01020dd:	e9 7f 08 00 00       	jmp    c0102961 <__alltraps>

c01020e2 <vector57>:
.globl vector57
vector57:
  pushl $0
c01020e2:	6a 00                	push   $0x0
  pushl $57
c01020e4:	6a 39                	push   $0x39
  jmp __alltraps
c01020e6:	e9 76 08 00 00       	jmp    c0102961 <__alltraps>

c01020eb <vector58>:
.globl vector58
vector58:
  pushl $0
c01020eb:	6a 00                	push   $0x0
  pushl $58
c01020ed:	6a 3a                	push   $0x3a
  jmp __alltraps
c01020ef:	e9 6d 08 00 00       	jmp    c0102961 <__alltraps>

c01020f4 <vector59>:
.globl vector59
vector59:
  pushl $0
c01020f4:	6a 00                	push   $0x0
  pushl $59
c01020f6:	6a 3b                	push   $0x3b
  jmp __alltraps
c01020f8:	e9 64 08 00 00       	jmp    c0102961 <__alltraps>

c01020fd <vector60>:
.globl vector60
vector60:
  pushl $0
c01020fd:	6a 00                	push   $0x0
  pushl $60
c01020ff:	6a 3c                	push   $0x3c
  jmp __alltraps
c0102101:	e9 5b 08 00 00       	jmp    c0102961 <__alltraps>

c0102106 <vector61>:
.globl vector61
vector61:
  pushl $0
c0102106:	6a 00                	push   $0x0
  pushl $61
c0102108:	6a 3d                	push   $0x3d
  jmp __alltraps
c010210a:	e9 52 08 00 00       	jmp    c0102961 <__alltraps>

c010210f <vector62>:
.globl vector62
vector62:
  pushl $0
c010210f:	6a 00                	push   $0x0
  pushl $62
c0102111:	6a 3e                	push   $0x3e
  jmp __alltraps
c0102113:	e9 49 08 00 00       	jmp    c0102961 <__alltraps>

c0102118 <vector63>:
.globl vector63
vector63:
  pushl $0
c0102118:	6a 00                	push   $0x0
  pushl $63
c010211a:	6a 3f                	push   $0x3f
  jmp __alltraps
c010211c:	e9 40 08 00 00       	jmp    c0102961 <__alltraps>

c0102121 <vector64>:
.globl vector64
vector64:
  pushl $0
c0102121:	6a 00                	push   $0x0
  pushl $64
c0102123:	6a 40                	push   $0x40
  jmp __alltraps
c0102125:	e9 37 08 00 00       	jmp    c0102961 <__alltraps>

c010212a <vector65>:
.globl vector65
vector65:
  pushl $0
c010212a:	6a 00                	push   $0x0
  pushl $65
c010212c:	6a 41                	push   $0x41
  jmp __alltraps
c010212e:	e9 2e 08 00 00       	jmp    c0102961 <__alltraps>

c0102133 <vector66>:
.globl vector66
vector66:
  pushl $0
c0102133:	6a 00                	push   $0x0
  pushl $66
c0102135:	6a 42                	push   $0x42
  jmp __alltraps
c0102137:	e9 25 08 00 00       	jmp    c0102961 <__alltraps>

c010213c <vector67>:
.globl vector67
vector67:
  pushl $0
c010213c:	6a 00                	push   $0x0
  pushl $67
c010213e:	6a 43                	push   $0x43
  jmp __alltraps
c0102140:	e9 1c 08 00 00       	jmp    c0102961 <__alltraps>

c0102145 <vector68>:
.globl vector68
vector68:
  pushl $0
c0102145:	6a 00                	push   $0x0
  pushl $68
c0102147:	6a 44                	push   $0x44
  jmp __alltraps
c0102149:	e9 13 08 00 00       	jmp    c0102961 <__alltraps>

c010214e <vector69>:
.globl vector69
vector69:
  pushl $0
c010214e:	6a 00                	push   $0x0
  pushl $69
c0102150:	6a 45                	push   $0x45
  jmp __alltraps
c0102152:	e9 0a 08 00 00       	jmp    c0102961 <__alltraps>

c0102157 <vector70>:
.globl vector70
vector70:
  pushl $0
c0102157:	6a 00                	push   $0x0
  pushl $70
c0102159:	6a 46                	push   $0x46
  jmp __alltraps
c010215b:	e9 01 08 00 00       	jmp    c0102961 <__alltraps>

c0102160 <vector71>:
.globl vector71
vector71:
  pushl $0
c0102160:	6a 00                	push   $0x0
  pushl $71
c0102162:	6a 47                	push   $0x47
  jmp __alltraps
c0102164:	e9 f8 07 00 00       	jmp    c0102961 <__alltraps>

c0102169 <vector72>:
.globl vector72
vector72:
  pushl $0
c0102169:	6a 00                	push   $0x0
  pushl $72
c010216b:	6a 48                	push   $0x48
  jmp __alltraps
c010216d:	e9 ef 07 00 00       	jmp    c0102961 <__alltraps>

c0102172 <vector73>:
.globl vector73
vector73:
  pushl $0
c0102172:	6a 00                	push   $0x0
  pushl $73
c0102174:	6a 49                	push   $0x49
  jmp __alltraps
c0102176:	e9 e6 07 00 00       	jmp    c0102961 <__alltraps>

c010217b <vector74>:
.globl vector74
vector74:
  pushl $0
c010217b:	6a 00                	push   $0x0
  pushl $74
c010217d:	6a 4a                	push   $0x4a
  jmp __alltraps
c010217f:	e9 dd 07 00 00       	jmp    c0102961 <__alltraps>

c0102184 <vector75>:
.globl vector75
vector75:
  pushl $0
c0102184:	6a 00                	push   $0x0
  pushl $75
c0102186:	6a 4b                	push   $0x4b
  jmp __alltraps
c0102188:	e9 d4 07 00 00       	jmp    c0102961 <__alltraps>

c010218d <vector76>:
.globl vector76
vector76:
  pushl $0
c010218d:	6a 00                	push   $0x0
  pushl $76
c010218f:	6a 4c                	push   $0x4c
  jmp __alltraps
c0102191:	e9 cb 07 00 00       	jmp    c0102961 <__alltraps>

c0102196 <vector77>:
.globl vector77
vector77:
  pushl $0
c0102196:	6a 00                	push   $0x0
  pushl $77
c0102198:	6a 4d                	push   $0x4d
  jmp __alltraps
c010219a:	e9 c2 07 00 00       	jmp    c0102961 <__alltraps>

c010219f <vector78>:
.globl vector78
vector78:
  pushl $0
c010219f:	6a 00                	push   $0x0
  pushl $78
c01021a1:	6a 4e                	push   $0x4e
  jmp __alltraps
c01021a3:	e9 b9 07 00 00       	jmp    c0102961 <__alltraps>

c01021a8 <vector79>:
.globl vector79
vector79:
  pushl $0
c01021a8:	6a 00                	push   $0x0
  pushl $79
c01021aa:	6a 4f                	push   $0x4f
  jmp __alltraps
c01021ac:	e9 b0 07 00 00       	jmp    c0102961 <__alltraps>

c01021b1 <vector80>:
.globl vector80
vector80:
  pushl $0
c01021b1:	6a 00                	push   $0x0
  pushl $80
c01021b3:	6a 50                	push   $0x50
  jmp __alltraps
c01021b5:	e9 a7 07 00 00       	jmp    c0102961 <__alltraps>

c01021ba <vector81>:
.globl vector81
vector81:
  pushl $0
c01021ba:	6a 00                	push   $0x0
  pushl $81
c01021bc:	6a 51                	push   $0x51
  jmp __alltraps
c01021be:	e9 9e 07 00 00       	jmp    c0102961 <__alltraps>

c01021c3 <vector82>:
.globl vector82
vector82:
  pushl $0
c01021c3:	6a 00                	push   $0x0
  pushl $82
c01021c5:	6a 52                	push   $0x52
  jmp __alltraps
c01021c7:	e9 95 07 00 00       	jmp    c0102961 <__alltraps>

c01021cc <vector83>:
.globl vector83
vector83:
  pushl $0
c01021cc:	6a 00                	push   $0x0
  pushl $83
c01021ce:	6a 53                	push   $0x53
  jmp __alltraps
c01021d0:	e9 8c 07 00 00       	jmp    c0102961 <__alltraps>

c01021d5 <vector84>:
.globl vector84
vector84:
  pushl $0
c01021d5:	6a 00                	push   $0x0
  pushl $84
c01021d7:	6a 54                	push   $0x54
  jmp __alltraps
c01021d9:	e9 83 07 00 00       	jmp    c0102961 <__alltraps>

c01021de <vector85>:
.globl vector85
vector85:
  pushl $0
c01021de:	6a 00                	push   $0x0
  pushl $85
c01021e0:	6a 55                	push   $0x55
  jmp __alltraps
c01021e2:	e9 7a 07 00 00       	jmp    c0102961 <__alltraps>

c01021e7 <vector86>:
.globl vector86
vector86:
  pushl $0
c01021e7:	6a 00                	push   $0x0
  pushl $86
c01021e9:	6a 56                	push   $0x56
  jmp __alltraps
c01021eb:	e9 71 07 00 00       	jmp    c0102961 <__alltraps>

c01021f0 <vector87>:
.globl vector87
vector87:
  pushl $0
c01021f0:	6a 00                	push   $0x0
  pushl $87
c01021f2:	6a 57                	push   $0x57
  jmp __alltraps
c01021f4:	e9 68 07 00 00       	jmp    c0102961 <__alltraps>

c01021f9 <vector88>:
.globl vector88
vector88:
  pushl $0
c01021f9:	6a 00                	push   $0x0
  pushl $88
c01021fb:	6a 58                	push   $0x58
  jmp __alltraps
c01021fd:	e9 5f 07 00 00       	jmp    c0102961 <__alltraps>

c0102202 <vector89>:
.globl vector89
vector89:
  pushl $0
c0102202:	6a 00                	push   $0x0
  pushl $89
c0102204:	6a 59                	push   $0x59
  jmp __alltraps
c0102206:	e9 56 07 00 00       	jmp    c0102961 <__alltraps>

c010220b <vector90>:
.globl vector90
vector90:
  pushl $0
c010220b:	6a 00                	push   $0x0
  pushl $90
c010220d:	6a 5a                	push   $0x5a
  jmp __alltraps
c010220f:	e9 4d 07 00 00       	jmp    c0102961 <__alltraps>

c0102214 <vector91>:
.globl vector91
vector91:
  pushl $0
c0102214:	6a 00                	push   $0x0
  pushl $91
c0102216:	6a 5b                	push   $0x5b
  jmp __alltraps
c0102218:	e9 44 07 00 00       	jmp    c0102961 <__alltraps>

c010221d <vector92>:
.globl vector92
vector92:
  pushl $0
c010221d:	6a 00                	push   $0x0
  pushl $92
c010221f:	6a 5c                	push   $0x5c
  jmp __alltraps
c0102221:	e9 3b 07 00 00       	jmp    c0102961 <__alltraps>

c0102226 <vector93>:
.globl vector93
vector93:
  pushl $0
c0102226:	6a 00                	push   $0x0
  pushl $93
c0102228:	6a 5d                	push   $0x5d
  jmp __alltraps
c010222a:	e9 32 07 00 00       	jmp    c0102961 <__alltraps>

c010222f <vector94>:
.globl vector94
vector94:
  pushl $0
c010222f:	6a 00                	push   $0x0
  pushl $94
c0102231:	6a 5e                	push   $0x5e
  jmp __alltraps
c0102233:	e9 29 07 00 00       	jmp    c0102961 <__alltraps>

c0102238 <vector95>:
.globl vector95
vector95:
  pushl $0
c0102238:	6a 00                	push   $0x0
  pushl $95
c010223a:	6a 5f                	push   $0x5f
  jmp __alltraps
c010223c:	e9 20 07 00 00       	jmp    c0102961 <__alltraps>

c0102241 <vector96>:
.globl vector96
vector96:
  pushl $0
c0102241:	6a 00                	push   $0x0
  pushl $96
c0102243:	6a 60                	push   $0x60
  jmp __alltraps
c0102245:	e9 17 07 00 00       	jmp    c0102961 <__alltraps>

c010224a <vector97>:
.globl vector97
vector97:
  pushl $0
c010224a:	6a 00                	push   $0x0
  pushl $97
c010224c:	6a 61                	push   $0x61
  jmp __alltraps
c010224e:	e9 0e 07 00 00       	jmp    c0102961 <__alltraps>

c0102253 <vector98>:
.globl vector98
vector98:
  pushl $0
c0102253:	6a 00                	push   $0x0
  pushl $98
c0102255:	6a 62                	push   $0x62
  jmp __alltraps
c0102257:	e9 05 07 00 00       	jmp    c0102961 <__alltraps>

c010225c <vector99>:
.globl vector99
vector99:
  pushl $0
c010225c:	6a 00                	push   $0x0
  pushl $99
c010225e:	6a 63                	push   $0x63
  jmp __alltraps
c0102260:	e9 fc 06 00 00       	jmp    c0102961 <__alltraps>

c0102265 <vector100>:
.globl vector100
vector100:
  pushl $0
c0102265:	6a 00                	push   $0x0
  pushl $100
c0102267:	6a 64                	push   $0x64
  jmp __alltraps
c0102269:	e9 f3 06 00 00       	jmp    c0102961 <__alltraps>

c010226e <vector101>:
.globl vector101
vector101:
  pushl $0
c010226e:	6a 00                	push   $0x0
  pushl $101
c0102270:	6a 65                	push   $0x65
  jmp __alltraps
c0102272:	e9 ea 06 00 00       	jmp    c0102961 <__alltraps>

c0102277 <vector102>:
.globl vector102
vector102:
  pushl $0
c0102277:	6a 00                	push   $0x0
  pushl $102
c0102279:	6a 66                	push   $0x66
  jmp __alltraps
c010227b:	e9 e1 06 00 00       	jmp    c0102961 <__alltraps>

c0102280 <vector103>:
.globl vector103
vector103:
  pushl $0
c0102280:	6a 00                	push   $0x0
  pushl $103
c0102282:	6a 67                	push   $0x67
  jmp __alltraps
c0102284:	e9 d8 06 00 00       	jmp    c0102961 <__alltraps>

c0102289 <vector104>:
.globl vector104
vector104:
  pushl $0
c0102289:	6a 00                	push   $0x0
  pushl $104
c010228b:	6a 68                	push   $0x68
  jmp __alltraps
c010228d:	e9 cf 06 00 00       	jmp    c0102961 <__alltraps>

c0102292 <vector105>:
.globl vector105
vector105:
  pushl $0
c0102292:	6a 00                	push   $0x0
  pushl $105
c0102294:	6a 69                	push   $0x69
  jmp __alltraps
c0102296:	e9 c6 06 00 00       	jmp    c0102961 <__alltraps>

c010229b <vector106>:
.globl vector106
vector106:
  pushl $0
c010229b:	6a 00                	push   $0x0
  pushl $106
c010229d:	6a 6a                	push   $0x6a
  jmp __alltraps
c010229f:	e9 bd 06 00 00       	jmp    c0102961 <__alltraps>

c01022a4 <vector107>:
.globl vector107
vector107:
  pushl $0
c01022a4:	6a 00                	push   $0x0
  pushl $107
c01022a6:	6a 6b                	push   $0x6b
  jmp __alltraps
c01022a8:	e9 b4 06 00 00       	jmp    c0102961 <__alltraps>

c01022ad <vector108>:
.globl vector108
vector108:
  pushl $0
c01022ad:	6a 00                	push   $0x0
  pushl $108
c01022af:	6a 6c                	push   $0x6c
  jmp __alltraps
c01022b1:	e9 ab 06 00 00       	jmp    c0102961 <__alltraps>

c01022b6 <vector109>:
.globl vector109
vector109:
  pushl $0
c01022b6:	6a 00                	push   $0x0
  pushl $109
c01022b8:	6a 6d                	push   $0x6d
  jmp __alltraps
c01022ba:	e9 a2 06 00 00       	jmp    c0102961 <__alltraps>

c01022bf <vector110>:
.globl vector110
vector110:
  pushl $0
c01022bf:	6a 00                	push   $0x0
  pushl $110
c01022c1:	6a 6e                	push   $0x6e
  jmp __alltraps
c01022c3:	e9 99 06 00 00       	jmp    c0102961 <__alltraps>

c01022c8 <vector111>:
.globl vector111
vector111:
  pushl $0
c01022c8:	6a 00                	push   $0x0
  pushl $111
c01022ca:	6a 6f                	push   $0x6f
  jmp __alltraps
c01022cc:	e9 90 06 00 00       	jmp    c0102961 <__alltraps>

c01022d1 <vector112>:
.globl vector112
vector112:
  pushl $0
c01022d1:	6a 00                	push   $0x0
  pushl $112
c01022d3:	6a 70                	push   $0x70
  jmp __alltraps
c01022d5:	e9 87 06 00 00       	jmp    c0102961 <__alltraps>

c01022da <vector113>:
.globl vector113
vector113:
  pushl $0
c01022da:	6a 00                	push   $0x0
  pushl $113
c01022dc:	6a 71                	push   $0x71
  jmp __alltraps
c01022de:	e9 7e 06 00 00       	jmp    c0102961 <__alltraps>

c01022e3 <vector114>:
.globl vector114
vector114:
  pushl $0
c01022e3:	6a 00                	push   $0x0
  pushl $114
c01022e5:	6a 72                	push   $0x72
  jmp __alltraps
c01022e7:	e9 75 06 00 00       	jmp    c0102961 <__alltraps>

c01022ec <vector115>:
.globl vector115
vector115:
  pushl $0
c01022ec:	6a 00                	push   $0x0
  pushl $115
c01022ee:	6a 73                	push   $0x73
  jmp __alltraps
c01022f0:	e9 6c 06 00 00       	jmp    c0102961 <__alltraps>

c01022f5 <vector116>:
.globl vector116
vector116:
  pushl $0
c01022f5:	6a 00                	push   $0x0
  pushl $116
c01022f7:	6a 74                	push   $0x74
  jmp __alltraps
c01022f9:	e9 63 06 00 00       	jmp    c0102961 <__alltraps>

c01022fe <vector117>:
.globl vector117
vector117:
  pushl $0
c01022fe:	6a 00                	push   $0x0
  pushl $117
c0102300:	6a 75                	push   $0x75
  jmp __alltraps
c0102302:	e9 5a 06 00 00       	jmp    c0102961 <__alltraps>

c0102307 <vector118>:
.globl vector118
vector118:
  pushl $0
c0102307:	6a 00                	push   $0x0
  pushl $118
c0102309:	6a 76                	push   $0x76
  jmp __alltraps
c010230b:	e9 51 06 00 00       	jmp    c0102961 <__alltraps>

c0102310 <vector119>:
.globl vector119
vector119:
  pushl $0
c0102310:	6a 00                	push   $0x0
  pushl $119
c0102312:	6a 77                	push   $0x77
  jmp __alltraps
c0102314:	e9 48 06 00 00       	jmp    c0102961 <__alltraps>

c0102319 <vector120>:
.globl vector120
vector120:
  pushl $0
c0102319:	6a 00                	push   $0x0
  pushl $120
c010231b:	6a 78                	push   $0x78
  jmp __alltraps
c010231d:	e9 3f 06 00 00       	jmp    c0102961 <__alltraps>

c0102322 <vector121>:
.globl vector121
vector121:
  pushl $0
c0102322:	6a 00                	push   $0x0
  pushl $121
c0102324:	6a 79                	push   $0x79
  jmp __alltraps
c0102326:	e9 36 06 00 00       	jmp    c0102961 <__alltraps>

c010232b <vector122>:
.globl vector122
vector122:
  pushl $0
c010232b:	6a 00                	push   $0x0
  pushl $122
c010232d:	6a 7a                	push   $0x7a
  jmp __alltraps
c010232f:	e9 2d 06 00 00       	jmp    c0102961 <__alltraps>

c0102334 <vector123>:
.globl vector123
vector123:
  pushl $0
c0102334:	6a 00                	push   $0x0
  pushl $123
c0102336:	6a 7b                	push   $0x7b
  jmp __alltraps
c0102338:	e9 24 06 00 00       	jmp    c0102961 <__alltraps>

c010233d <vector124>:
.globl vector124
vector124:
  pushl $0
c010233d:	6a 00                	push   $0x0
  pushl $124
c010233f:	6a 7c                	push   $0x7c
  jmp __alltraps
c0102341:	e9 1b 06 00 00       	jmp    c0102961 <__alltraps>

c0102346 <vector125>:
.globl vector125
vector125:
  pushl $0
c0102346:	6a 00                	push   $0x0
  pushl $125
c0102348:	6a 7d                	push   $0x7d
  jmp __alltraps
c010234a:	e9 12 06 00 00       	jmp    c0102961 <__alltraps>

c010234f <vector126>:
.globl vector126
vector126:
  pushl $0
c010234f:	6a 00                	push   $0x0
  pushl $126
c0102351:	6a 7e                	push   $0x7e
  jmp __alltraps
c0102353:	e9 09 06 00 00       	jmp    c0102961 <__alltraps>

c0102358 <vector127>:
.globl vector127
vector127:
  pushl $0
c0102358:	6a 00                	push   $0x0
  pushl $127
c010235a:	6a 7f                	push   $0x7f
  jmp __alltraps
c010235c:	e9 00 06 00 00       	jmp    c0102961 <__alltraps>

c0102361 <vector128>:
.globl vector128
vector128:
  pushl $0
c0102361:	6a 00                	push   $0x0
  pushl $128
c0102363:	68 80 00 00 00       	push   $0x80
  jmp __alltraps
c0102368:	e9 f4 05 00 00       	jmp    c0102961 <__alltraps>

c010236d <vector129>:
.globl vector129
vector129:
  pushl $0
c010236d:	6a 00                	push   $0x0
  pushl $129
c010236f:	68 81 00 00 00       	push   $0x81
  jmp __alltraps
c0102374:	e9 e8 05 00 00       	jmp    c0102961 <__alltraps>

c0102379 <vector130>:
.globl vector130
vector130:
  pushl $0
c0102379:	6a 00                	push   $0x0
  pushl $130
c010237b:	68 82 00 00 00       	push   $0x82
  jmp __alltraps
c0102380:	e9 dc 05 00 00       	jmp    c0102961 <__alltraps>

c0102385 <vector131>:
.globl vector131
vector131:
  pushl $0
c0102385:	6a 00                	push   $0x0
  pushl $131
c0102387:	68 83 00 00 00       	push   $0x83
  jmp __alltraps
c010238c:	e9 d0 05 00 00       	jmp    c0102961 <__alltraps>

c0102391 <vector132>:
.globl vector132
vector132:
  pushl $0
c0102391:	6a 00                	push   $0x0
  pushl $132
c0102393:	68 84 00 00 00       	push   $0x84
  jmp __alltraps
c0102398:	e9 c4 05 00 00       	jmp    c0102961 <__alltraps>

c010239d <vector133>:
.globl vector133
vector133:
  pushl $0
c010239d:	6a 00                	push   $0x0
  pushl $133
c010239f:	68 85 00 00 00       	push   $0x85
  jmp __alltraps
c01023a4:	e9 b8 05 00 00       	jmp    c0102961 <__alltraps>

c01023a9 <vector134>:
.globl vector134
vector134:
  pushl $0
c01023a9:	6a 00                	push   $0x0
  pushl $134
c01023ab:	68 86 00 00 00       	push   $0x86
  jmp __alltraps
c01023b0:	e9 ac 05 00 00       	jmp    c0102961 <__alltraps>

c01023b5 <vector135>:
.globl vector135
vector135:
  pushl $0
c01023b5:	6a 00                	push   $0x0
  pushl $135
c01023b7:	68 87 00 00 00       	push   $0x87
  jmp __alltraps
c01023bc:	e9 a0 05 00 00       	jmp    c0102961 <__alltraps>

c01023c1 <vector136>:
.globl vector136
vector136:
  pushl $0
c01023c1:	6a 00                	push   $0x0
  pushl $136
c01023c3:	68 88 00 00 00       	push   $0x88
  jmp __alltraps
c01023c8:	e9 94 05 00 00       	jmp    c0102961 <__alltraps>

c01023cd <vector137>:
.globl vector137
vector137:
  pushl $0
c01023cd:	6a 00                	push   $0x0
  pushl $137
c01023cf:	68 89 00 00 00       	push   $0x89
  jmp __alltraps
c01023d4:	e9 88 05 00 00       	jmp    c0102961 <__alltraps>

c01023d9 <vector138>:
.globl vector138
vector138:
  pushl $0
c01023d9:	6a 00                	push   $0x0
  pushl $138
c01023db:	68 8a 00 00 00       	push   $0x8a
  jmp __alltraps
c01023e0:	e9 7c 05 00 00       	jmp    c0102961 <__alltraps>

c01023e5 <vector139>:
.globl vector139
vector139:
  pushl $0
c01023e5:	6a 00                	push   $0x0
  pushl $139
c01023e7:	68 8b 00 00 00       	push   $0x8b
  jmp __alltraps
c01023ec:	e9 70 05 00 00       	jmp    c0102961 <__alltraps>

c01023f1 <vector140>:
.globl vector140
vector140:
  pushl $0
c01023f1:	6a 00                	push   $0x0
  pushl $140
c01023f3:	68 8c 00 00 00       	push   $0x8c
  jmp __alltraps
c01023f8:	e9 64 05 00 00       	jmp    c0102961 <__alltraps>

c01023fd <vector141>:
.globl vector141
vector141:
  pushl $0
c01023fd:	6a 00                	push   $0x0
  pushl $141
c01023ff:	68 8d 00 00 00       	push   $0x8d
  jmp __alltraps
c0102404:	e9 58 05 00 00       	jmp    c0102961 <__alltraps>

c0102409 <vector142>:
.globl vector142
vector142:
  pushl $0
c0102409:	6a 00                	push   $0x0
  pushl $142
c010240b:	68 8e 00 00 00       	push   $0x8e
  jmp __alltraps
c0102410:	e9 4c 05 00 00       	jmp    c0102961 <__alltraps>

c0102415 <vector143>:
.globl vector143
vector143:
  pushl $0
c0102415:	6a 00                	push   $0x0
  pushl $143
c0102417:	68 8f 00 00 00       	push   $0x8f
  jmp __alltraps
c010241c:	e9 40 05 00 00       	jmp    c0102961 <__alltraps>

c0102421 <vector144>:
.globl vector144
vector144:
  pushl $0
c0102421:	6a 00                	push   $0x0
  pushl $144
c0102423:	68 90 00 00 00       	push   $0x90
  jmp __alltraps
c0102428:	e9 34 05 00 00       	jmp    c0102961 <__alltraps>

c010242d <vector145>:
.globl vector145
vector145:
  pushl $0
c010242d:	6a 00                	push   $0x0
  pushl $145
c010242f:	68 91 00 00 00       	push   $0x91
  jmp __alltraps
c0102434:	e9 28 05 00 00       	jmp    c0102961 <__alltraps>

c0102439 <vector146>:
.globl vector146
vector146:
  pushl $0
c0102439:	6a 00                	push   $0x0
  pushl $146
c010243b:	68 92 00 00 00       	push   $0x92
  jmp __alltraps
c0102440:	e9 1c 05 00 00       	jmp    c0102961 <__alltraps>

c0102445 <vector147>:
.globl vector147
vector147:
  pushl $0
c0102445:	6a 00                	push   $0x0
  pushl $147
c0102447:	68 93 00 00 00       	push   $0x93
  jmp __alltraps
c010244c:	e9 10 05 00 00       	jmp    c0102961 <__alltraps>

c0102451 <vector148>:
.globl vector148
vector148:
  pushl $0
c0102451:	6a 00                	push   $0x0
  pushl $148
c0102453:	68 94 00 00 00       	push   $0x94
  jmp __alltraps
c0102458:	e9 04 05 00 00       	jmp    c0102961 <__alltraps>

c010245d <vector149>:
.globl vector149
vector149:
  pushl $0
c010245d:	6a 00                	push   $0x0
  pushl $149
c010245f:	68 95 00 00 00       	push   $0x95
  jmp __alltraps
c0102464:	e9 f8 04 00 00       	jmp    c0102961 <__alltraps>

c0102469 <vector150>:
.globl vector150
vector150:
  pushl $0
c0102469:	6a 00                	push   $0x0
  pushl $150
c010246b:	68 96 00 00 00       	push   $0x96
  jmp __alltraps
c0102470:	e9 ec 04 00 00       	jmp    c0102961 <__alltraps>

c0102475 <vector151>:
.globl vector151
vector151:
  pushl $0
c0102475:	6a 00                	push   $0x0
  pushl $151
c0102477:	68 97 00 00 00       	push   $0x97
  jmp __alltraps
c010247c:	e9 e0 04 00 00       	jmp    c0102961 <__alltraps>

c0102481 <vector152>:
.globl vector152
vector152:
  pushl $0
c0102481:	6a 00                	push   $0x0
  pushl $152
c0102483:	68 98 00 00 00       	push   $0x98
  jmp __alltraps
c0102488:	e9 d4 04 00 00       	jmp    c0102961 <__alltraps>

c010248d <vector153>:
.globl vector153
vector153:
  pushl $0
c010248d:	6a 00                	push   $0x0
  pushl $153
c010248f:	68 99 00 00 00       	push   $0x99
  jmp __alltraps
c0102494:	e9 c8 04 00 00       	jmp    c0102961 <__alltraps>

c0102499 <vector154>:
.globl vector154
vector154:
  pushl $0
c0102499:	6a 00                	push   $0x0
  pushl $154
c010249b:	68 9a 00 00 00       	push   $0x9a
  jmp __alltraps
c01024a0:	e9 bc 04 00 00       	jmp    c0102961 <__alltraps>

c01024a5 <vector155>:
.globl vector155
vector155:
  pushl $0
c01024a5:	6a 00                	push   $0x0
  pushl $155
c01024a7:	68 9b 00 00 00       	push   $0x9b
  jmp __alltraps
c01024ac:	e9 b0 04 00 00       	jmp    c0102961 <__alltraps>

c01024b1 <vector156>:
.globl vector156
vector156:
  pushl $0
c01024b1:	6a 00                	push   $0x0
  pushl $156
c01024b3:	68 9c 00 00 00       	push   $0x9c
  jmp __alltraps
c01024b8:	e9 a4 04 00 00       	jmp    c0102961 <__alltraps>

c01024bd <vector157>:
.globl vector157
vector157:
  pushl $0
c01024bd:	6a 00                	push   $0x0
  pushl $157
c01024bf:	68 9d 00 00 00       	push   $0x9d
  jmp __alltraps
c01024c4:	e9 98 04 00 00       	jmp    c0102961 <__alltraps>

c01024c9 <vector158>:
.globl vector158
vector158:
  pushl $0
c01024c9:	6a 00                	push   $0x0
  pushl $158
c01024cb:	68 9e 00 00 00       	push   $0x9e
  jmp __alltraps
c01024d0:	e9 8c 04 00 00       	jmp    c0102961 <__alltraps>

c01024d5 <vector159>:
.globl vector159
vector159:
  pushl $0
c01024d5:	6a 00                	push   $0x0
  pushl $159
c01024d7:	68 9f 00 00 00       	push   $0x9f
  jmp __alltraps
c01024dc:	e9 80 04 00 00       	jmp    c0102961 <__alltraps>

c01024e1 <vector160>:
.globl vector160
vector160:
  pushl $0
c01024e1:	6a 00                	push   $0x0
  pushl $160
c01024e3:	68 a0 00 00 00       	push   $0xa0
  jmp __alltraps
c01024e8:	e9 74 04 00 00       	jmp    c0102961 <__alltraps>

c01024ed <vector161>:
.globl vector161
vector161:
  pushl $0
c01024ed:	6a 00                	push   $0x0
  pushl $161
c01024ef:	68 a1 00 00 00       	push   $0xa1
  jmp __alltraps
c01024f4:	e9 68 04 00 00       	jmp    c0102961 <__alltraps>

c01024f9 <vector162>:
.globl vector162
vector162:
  pushl $0
c01024f9:	6a 00                	push   $0x0
  pushl $162
c01024fb:	68 a2 00 00 00       	push   $0xa2
  jmp __alltraps
c0102500:	e9 5c 04 00 00       	jmp    c0102961 <__alltraps>

c0102505 <vector163>:
.globl vector163
vector163:
  pushl $0
c0102505:	6a 00                	push   $0x0
  pushl $163
c0102507:	68 a3 00 00 00       	push   $0xa3
  jmp __alltraps
c010250c:	e9 50 04 00 00       	jmp    c0102961 <__alltraps>

c0102511 <vector164>:
.globl vector164
vector164:
  pushl $0
c0102511:	6a 00                	push   $0x0
  pushl $164
c0102513:	68 a4 00 00 00       	push   $0xa4
  jmp __alltraps
c0102518:	e9 44 04 00 00       	jmp    c0102961 <__alltraps>

c010251d <vector165>:
.globl vector165
vector165:
  pushl $0
c010251d:	6a 00                	push   $0x0
  pushl $165
c010251f:	68 a5 00 00 00       	push   $0xa5
  jmp __alltraps
c0102524:	e9 38 04 00 00       	jmp    c0102961 <__alltraps>

c0102529 <vector166>:
.globl vector166
vector166:
  pushl $0
c0102529:	6a 00                	push   $0x0
  pushl $166
c010252b:	68 a6 00 00 00       	push   $0xa6
  jmp __alltraps
c0102530:	e9 2c 04 00 00       	jmp    c0102961 <__alltraps>

c0102535 <vector167>:
.globl vector167
vector167:
  pushl $0
c0102535:	6a 00                	push   $0x0
  pushl $167
c0102537:	68 a7 00 00 00       	push   $0xa7
  jmp __alltraps
c010253c:	e9 20 04 00 00       	jmp    c0102961 <__alltraps>

c0102541 <vector168>:
.globl vector168
vector168:
  pushl $0
c0102541:	6a 00                	push   $0x0
  pushl $168
c0102543:	68 a8 00 00 00       	push   $0xa8
  jmp __alltraps
c0102548:	e9 14 04 00 00       	jmp    c0102961 <__alltraps>

c010254d <vector169>:
.globl vector169
vector169:
  pushl $0
c010254d:	6a 00                	push   $0x0
  pushl $169
c010254f:	68 a9 00 00 00       	push   $0xa9
  jmp __alltraps
c0102554:	e9 08 04 00 00       	jmp    c0102961 <__alltraps>

c0102559 <vector170>:
.globl vector170
vector170:
  pushl $0
c0102559:	6a 00                	push   $0x0
  pushl $170
c010255b:	68 aa 00 00 00       	push   $0xaa
  jmp __alltraps
c0102560:	e9 fc 03 00 00       	jmp    c0102961 <__alltraps>

c0102565 <vector171>:
.globl vector171
vector171:
  pushl $0
c0102565:	6a 00                	push   $0x0
  pushl $171
c0102567:	68 ab 00 00 00       	push   $0xab
  jmp __alltraps
c010256c:	e9 f0 03 00 00       	jmp    c0102961 <__alltraps>

c0102571 <vector172>:
.globl vector172
vector172:
  pushl $0
c0102571:	6a 00                	push   $0x0
  pushl $172
c0102573:	68 ac 00 00 00       	push   $0xac
  jmp __alltraps
c0102578:	e9 e4 03 00 00       	jmp    c0102961 <__alltraps>

c010257d <vector173>:
.globl vector173
vector173:
  pushl $0
c010257d:	6a 00                	push   $0x0
  pushl $173
c010257f:	68 ad 00 00 00       	push   $0xad
  jmp __alltraps
c0102584:	e9 d8 03 00 00       	jmp    c0102961 <__alltraps>

c0102589 <vector174>:
.globl vector174
vector174:
  pushl $0
c0102589:	6a 00                	push   $0x0
  pushl $174
c010258b:	68 ae 00 00 00       	push   $0xae
  jmp __alltraps
c0102590:	e9 cc 03 00 00       	jmp    c0102961 <__alltraps>

c0102595 <vector175>:
.globl vector175
vector175:
  pushl $0
c0102595:	6a 00                	push   $0x0
  pushl $175
c0102597:	68 af 00 00 00       	push   $0xaf
  jmp __alltraps
c010259c:	e9 c0 03 00 00       	jmp    c0102961 <__alltraps>

c01025a1 <vector176>:
.globl vector176
vector176:
  pushl $0
c01025a1:	6a 00                	push   $0x0
  pushl $176
c01025a3:	68 b0 00 00 00       	push   $0xb0
  jmp __alltraps
c01025a8:	e9 b4 03 00 00       	jmp    c0102961 <__alltraps>

c01025ad <vector177>:
.globl vector177
vector177:
  pushl $0
c01025ad:	6a 00                	push   $0x0
  pushl $177
c01025af:	68 b1 00 00 00       	push   $0xb1
  jmp __alltraps
c01025b4:	e9 a8 03 00 00       	jmp    c0102961 <__alltraps>

c01025b9 <vector178>:
.globl vector178
vector178:
  pushl $0
c01025b9:	6a 00                	push   $0x0
  pushl $178
c01025bb:	68 b2 00 00 00       	push   $0xb2
  jmp __alltraps
c01025c0:	e9 9c 03 00 00       	jmp    c0102961 <__alltraps>

c01025c5 <vector179>:
.globl vector179
vector179:
  pushl $0
c01025c5:	6a 00                	push   $0x0
  pushl $179
c01025c7:	68 b3 00 00 00       	push   $0xb3
  jmp __alltraps
c01025cc:	e9 90 03 00 00       	jmp    c0102961 <__alltraps>

c01025d1 <vector180>:
.globl vector180
vector180:
  pushl $0
c01025d1:	6a 00                	push   $0x0
  pushl $180
c01025d3:	68 b4 00 00 00       	push   $0xb4
  jmp __alltraps
c01025d8:	e9 84 03 00 00       	jmp    c0102961 <__alltraps>

c01025dd <vector181>:
.globl vector181
vector181:
  pushl $0
c01025dd:	6a 00                	push   $0x0
  pushl $181
c01025df:	68 b5 00 00 00       	push   $0xb5
  jmp __alltraps
c01025e4:	e9 78 03 00 00       	jmp    c0102961 <__alltraps>

c01025e9 <vector182>:
.globl vector182
vector182:
  pushl $0
c01025e9:	6a 00                	push   $0x0
  pushl $182
c01025eb:	68 b6 00 00 00       	push   $0xb6
  jmp __alltraps
c01025f0:	e9 6c 03 00 00       	jmp    c0102961 <__alltraps>

c01025f5 <vector183>:
.globl vector183
vector183:
  pushl $0
c01025f5:	6a 00                	push   $0x0
  pushl $183
c01025f7:	68 b7 00 00 00       	push   $0xb7
  jmp __alltraps
c01025fc:	e9 60 03 00 00       	jmp    c0102961 <__alltraps>

c0102601 <vector184>:
.globl vector184
vector184:
  pushl $0
c0102601:	6a 00                	push   $0x0
  pushl $184
c0102603:	68 b8 00 00 00       	push   $0xb8
  jmp __alltraps
c0102608:	e9 54 03 00 00       	jmp    c0102961 <__alltraps>

c010260d <vector185>:
.globl vector185
vector185:
  pushl $0
c010260d:	6a 00                	push   $0x0
  pushl $185
c010260f:	68 b9 00 00 00       	push   $0xb9
  jmp __alltraps
c0102614:	e9 48 03 00 00       	jmp    c0102961 <__alltraps>

c0102619 <vector186>:
.globl vector186
vector186:
  pushl $0
c0102619:	6a 00                	push   $0x0
  pushl $186
c010261b:	68 ba 00 00 00       	push   $0xba
  jmp __alltraps
c0102620:	e9 3c 03 00 00       	jmp    c0102961 <__alltraps>

c0102625 <vector187>:
.globl vector187
vector187:
  pushl $0
c0102625:	6a 00                	push   $0x0
  pushl $187
c0102627:	68 bb 00 00 00       	push   $0xbb
  jmp __alltraps
c010262c:	e9 30 03 00 00       	jmp    c0102961 <__alltraps>

c0102631 <vector188>:
.globl vector188
vector188:
  pushl $0
c0102631:	6a 00                	push   $0x0
  pushl $188
c0102633:	68 bc 00 00 00       	push   $0xbc
  jmp __alltraps
c0102638:	e9 24 03 00 00       	jmp    c0102961 <__alltraps>

c010263d <vector189>:
.globl vector189
vector189:
  pushl $0
c010263d:	6a 00                	push   $0x0
  pushl $189
c010263f:	68 bd 00 00 00       	push   $0xbd
  jmp __alltraps
c0102644:	e9 18 03 00 00       	jmp    c0102961 <__alltraps>

c0102649 <vector190>:
.globl vector190
vector190:
  pushl $0
c0102649:	6a 00                	push   $0x0
  pushl $190
c010264b:	68 be 00 00 00       	push   $0xbe
  jmp __alltraps
c0102650:	e9 0c 03 00 00       	jmp    c0102961 <__alltraps>

c0102655 <vector191>:
.globl vector191
vector191:
  pushl $0
c0102655:	6a 00                	push   $0x0
  pushl $191
c0102657:	68 bf 00 00 00       	push   $0xbf
  jmp __alltraps
c010265c:	e9 00 03 00 00       	jmp    c0102961 <__alltraps>

c0102661 <vector192>:
.globl vector192
vector192:
  pushl $0
c0102661:	6a 00                	push   $0x0
  pushl $192
c0102663:	68 c0 00 00 00       	push   $0xc0
  jmp __alltraps
c0102668:	e9 f4 02 00 00       	jmp    c0102961 <__alltraps>

c010266d <vector193>:
.globl vector193
vector193:
  pushl $0
c010266d:	6a 00                	push   $0x0
  pushl $193
c010266f:	68 c1 00 00 00       	push   $0xc1
  jmp __alltraps
c0102674:	e9 e8 02 00 00       	jmp    c0102961 <__alltraps>

c0102679 <vector194>:
.globl vector194
vector194:
  pushl $0
c0102679:	6a 00                	push   $0x0
  pushl $194
c010267b:	68 c2 00 00 00       	push   $0xc2
  jmp __alltraps
c0102680:	e9 dc 02 00 00       	jmp    c0102961 <__alltraps>

c0102685 <vector195>:
.globl vector195
vector195:
  pushl $0
c0102685:	6a 00                	push   $0x0
  pushl $195
c0102687:	68 c3 00 00 00       	push   $0xc3
  jmp __alltraps
c010268c:	e9 d0 02 00 00       	jmp    c0102961 <__alltraps>

c0102691 <vector196>:
.globl vector196
vector196:
  pushl $0
c0102691:	6a 00                	push   $0x0
  pushl $196
c0102693:	68 c4 00 00 00       	push   $0xc4
  jmp __alltraps
c0102698:	e9 c4 02 00 00       	jmp    c0102961 <__alltraps>

c010269d <vector197>:
.globl vector197
vector197:
  pushl $0
c010269d:	6a 00                	push   $0x0
  pushl $197
c010269f:	68 c5 00 00 00       	push   $0xc5
  jmp __alltraps
c01026a4:	e9 b8 02 00 00       	jmp    c0102961 <__alltraps>

c01026a9 <vector198>:
.globl vector198
vector198:
  pushl $0
c01026a9:	6a 00                	push   $0x0
  pushl $198
c01026ab:	68 c6 00 00 00       	push   $0xc6
  jmp __alltraps
c01026b0:	e9 ac 02 00 00       	jmp    c0102961 <__alltraps>

c01026b5 <vector199>:
.globl vector199
vector199:
  pushl $0
c01026b5:	6a 00                	push   $0x0
  pushl $199
c01026b7:	68 c7 00 00 00       	push   $0xc7
  jmp __alltraps
c01026bc:	e9 a0 02 00 00       	jmp    c0102961 <__alltraps>

c01026c1 <vector200>:
.globl vector200
vector200:
  pushl $0
c01026c1:	6a 00                	push   $0x0
  pushl $200
c01026c3:	68 c8 00 00 00       	push   $0xc8
  jmp __alltraps
c01026c8:	e9 94 02 00 00       	jmp    c0102961 <__alltraps>

c01026cd <vector201>:
.globl vector201
vector201:
  pushl $0
c01026cd:	6a 00                	push   $0x0
  pushl $201
c01026cf:	68 c9 00 00 00       	push   $0xc9
  jmp __alltraps
c01026d4:	e9 88 02 00 00       	jmp    c0102961 <__alltraps>

c01026d9 <vector202>:
.globl vector202
vector202:
  pushl $0
c01026d9:	6a 00                	push   $0x0
  pushl $202
c01026db:	68 ca 00 00 00       	push   $0xca
  jmp __alltraps
c01026e0:	e9 7c 02 00 00       	jmp    c0102961 <__alltraps>

c01026e5 <vector203>:
.globl vector203
vector203:
  pushl $0
c01026e5:	6a 00                	push   $0x0
  pushl $203
c01026e7:	68 cb 00 00 00       	push   $0xcb
  jmp __alltraps
c01026ec:	e9 70 02 00 00       	jmp    c0102961 <__alltraps>

c01026f1 <vector204>:
.globl vector204
vector204:
  pushl $0
c01026f1:	6a 00                	push   $0x0
  pushl $204
c01026f3:	68 cc 00 00 00       	push   $0xcc
  jmp __alltraps
c01026f8:	e9 64 02 00 00       	jmp    c0102961 <__alltraps>

c01026fd <vector205>:
.globl vector205
vector205:
  pushl $0
c01026fd:	6a 00                	push   $0x0
  pushl $205
c01026ff:	68 cd 00 00 00       	push   $0xcd
  jmp __alltraps
c0102704:	e9 58 02 00 00       	jmp    c0102961 <__alltraps>

c0102709 <vector206>:
.globl vector206
vector206:
  pushl $0
c0102709:	6a 00                	push   $0x0
  pushl $206
c010270b:	68 ce 00 00 00       	push   $0xce
  jmp __alltraps
c0102710:	e9 4c 02 00 00       	jmp    c0102961 <__alltraps>

c0102715 <vector207>:
.globl vector207
vector207:
  pushl $0
c0102715:	6a 00                	push   $0x0
  pushl $207
c0102717:	68 cf 00 00 00       	push   $0xcf
  jmp __alltraps
c010271c:	e9 40 02 00 00       	jmp    c0102961 <__alltraps>

c0102721 <vector208>:
.globl vector208
vector208:
  pushl $0
c0102721:	6a 00                	push   $0x0
  pushl $208
c0102723:	68 d0 00 00 00       	push   $0xd0
  jmp __alltraps
c0102728:	e9 34 02 00 00       	jmp    c0102961 <__alltraps>

c010272d <vector209>:
.globl vector209
vector209:
  pushl $0
c010272d:	6a 00                	push   $0x0
  pushl $209
c010272f:	68 d1 00 00 00       	push   $0xd1
  jmp __alltraps
c0102734:	e9 28 02 00 00       	jmp    c0102961 <__alltraps>

c0102739 <vector210>:
.globl vector210
vector210:
  pushl $0
c0102739:	6a 00                	push   $0x0
  pushl $210
c010273b:	68 d2 00 00 00       	push   $0xd2
  jmp __alltraps
c0102740:	e9 1c 02 00 00       	jmp    c0102961 <__alltraps>

c0102745 <vector211>:
.globl vector211
vector211:
  pushl $0
c0102745:	6a 00                	push   $0x0
  pushl $211
c0102747:	68 d3 00 00 00       	push   $0xd3
  jmp __alltraps
c010274c:	e9 10 02 00 00       	jmp    c0102961 <__alltraps>

c0102751 <vector212>:
.globl vector212
vector212:
  pushl $0
c0102751:	6a 00                	push   $0x0
  pushl $212
c0102753:	68 d4 00 00 00       	push   $0xd4
  jmp __alltraps
c0102758:	e9 04 02 00 00       	jmp    c0102961 <__alltraps>

c010275d <vector213>:
.globl vector213
vector213:
  pushl $0
c010275d:	6a 00                	push   $0x0
  pushl $213
c010275f:	68 d5 00 00 00       	push   $0xd5
  jmp __alltraps
c0102764:	e9 f8 01 00 00       	jmp    c0102961 <__alltraps>

c0102769 <vector214>:
.globl vector214
vector214:
  pushl $0
c0102769:	6a 00                	push   $0x0
  pushl $214
c010276b:	68 d6 00 00 00       	push   $0xd6
  jmp __alltraps
c0102770:	e9 ec 01 00 00       	jmp    c0102961 <__alltraps>

c0102775 <vector215>:
.globl vector215
vector215:
  pushl $0
c0102775:	6a 00                	push   $0x0
  pushl $215
c0102777:	68 d7 00 00 00       	push   $0xd7
  jmp __alltraps
c010277c:	e9 e0 01 00 00       	jmp    c0102961 <__alltraps>

c0102781 <vector216>:
.globl vector216
vector216:
  pushl $0
c0102781:	6a 00                	push   $0x0
  pushl $216
c0102783:	68 d8 00 00 00       	push   $0xd8
  jmp __alltraps
c0102788:	e9 d4 01 00 00       	jmp    c0102961 <__alltraps>

c010278d <vector217>:
.globl vector217
vector217:
  pushl $0
c010278d:	6a 00                	push   $0x0
  pushl $217
c010278f:	68 d9 00 00 00       	push   $0xd9
  jmp __alltraps
c0102794:	e9 c8 01 00 00       	jmp    c0102961 <__alltraps>

c0102799 <vector218>:
.globl vector218
vector218:
  pushl $0
c0102799:	6a 00                	push   $0x0
  pushl $218
c010279b:	68 da 00 00 00       	push   $0xda
  jmp __alltraps
c01027a0:	e9 bc 01 00 00       	jmp    c0102961 <__alltraps>

c01027a5 <vector219>:
.globl vector219
vector219:
  pushl $0
c01027a5:	6a 00                	push   $0x0
  pushl $219
c01027a7:	68 db 00 00 00       	push   $0xdb
  jmp __alltraps
c01027ac:	e9 b0 01 00 00       	jmp    c0102961 <__alltraps>

c01027b1 <vector220>:
.globl vector220
vector220:
  pushl $0
c01027b1:	6a 00                	push   $0x0
  pushl $220
c01027b3:	68 dc 00 00 00       	push   $0xdc
  jmp __alltraps
c01027b8:	e9 a4 01 00 00       	jmp    c0102961 <__alltraps>

c01027bd <vector221>:
.globl vector221
vector221:
  pushl $0
c01027bd:	6a 00                	push   $0x0
  pushl $221
c01027bf:	68 dd 00 00 00       	push   $0xdd
  jmp __alltraps
c01027c4:	e9 98 01 00 00       	jmp    c0102961 <__alltraps>

c01027c9 <vector222>:
.globl vector222
vector222:
  pushl $0
c01027c9:	6a 00                	push   $0x0
  pushl $222
c01027cb:	68 de 00 00 00       	push   $0xde
  jmp __alltraps
c01027d0:	e9 8c 01 00 00       	jmp    c0102961 <__alltraps>

c01027d5 <vector223>:
.globl vector223
vector223:
  pushl $0
c01027d5:	6a 00                	push   $0x0
  pushl $223
c01027d7:	68 df 00 00 00       	push   $0xdf
  jmp __alltraps
c01027dc:	e9 80 01 00 00       	jmp    c0102961 <__alltraps>

c01027e1 <vector224>:
.globl vector224
vector224:
  pushl $0
c01027e1:	6a 00                	push   $0x0
  pushl $224
c01027e3:	68 e0 00 00 00       	push   $0xe0
  jmp __alltraps
c01027e8:	e9 74 01 00 00       	jmp    c0102961 <__alltraps>

c01027ed <vector225>:
.globl vector225
vector225:
  pushl $0
c01027ed:	6a 00                	push   $0x0
  pushl $225
c01027ef:	68 e1 00 00 00       	push   $0xe1
  jmp __alltraps
c01027f4:	e9 68 01 00 00       	jmp    c0102961 <__alltraps>

c01027f9 <vector226>:
.globl vector226
vector226:
  pushl $0
c01027f9:	6a 00                	push   $0x0
  pushl $226
c01027fb:	68 e2 00 00 00       	push   $0xe2
  jmp __alltraps
c0102800:	e9 5c 01 00 00       	jmp    c0102961 <__alltraps>

c0102805 <vector227>:
.globl vector227
vector227:
  pushl $0
c0102805:	6a 00                	push   $0x0
  pushl $227
c0102807:	68 e3 00 00 00       	push   $0xe3
  jmp __alltraps
c010280c:	e9 50 01 00 00       	jmp    c0102961 <__alltraps>

c0102811 <vector228>:
.globl vector228
vector228:
  pushl $0
c0102811:	6a 00                	push   $0x0
  pushl $228
c0102813:	68 e4 00 00 00       	push   $0xe4
  jmp __alltraps
c0102818:	e9 44 01 00 00       	jmp    c0102961 <__alltraps>

c010281d <vector229>:
.globl vector229
vector229:
  pushl $0
c010281d:	6a 00                	push   $0x0
  pushl $229
c010281f:	68 e5 00 00 00       	push   $0xe5
  jmp __alltraps
c0102824:	e9 38 01 00 00       	jmp    c0102961 <__alltraps>

c0102829 <vector230>:
.globl vector230
vector230:
  pushl $0
c0102829:	6a 00                	push   $0x0
  pushl $230
c010282b:	68 e6 00 00 00       	push   $0xe6
  jmp __alltraps
c0102830:	e9 2c 01 00 00       	jmp    c0102961 <__alltraps>

c0102835 <vector231>:
.globl vector231
vector231:
  pushl $0
c0102835:	6a 00                	push   $0x0
  pushl $231
c0102837:	68 e7 00 00 00       	push   $0xe7
  jmp __alltraps
c010283c:	e9 20 01 00 00       	jmp    c0102961 <__alltraps>

c0102841 <vector232>:
.globl vector232
vector232:
  pushl $0
c0102841:	6a 00                	push   $0x0
  pushl $232
c0102843:	68 e8 00 00 00       	push   $0xe8
  jmp __alltraps
c0102848:	e9 14 01 00 00       	jmp    c0102961 <__alltraps>

c010284d <vector233>:
.globl vector233
vector233:
  pushl $0
c010284d:	6a 00                	push   $0x0
  pushl $233
c010284f:	68 e9 00 00 00       	push   $0xe9
  jmp __alltraps
c0102854:	e9 08 01 00 00       	jmp    c0102961 <__alltraps>

c0102859 <vector234>:
.globl vector234
vector234:
  pushl $0
c0102859:	6a 00                	push   $0x0
  pushl $234
c010285b:	68 ea 00 00 00       	push   $0xea
  jmp __alltraps
c0102860:	e9 fc 00 00 00       	jmp    c0102961 <__alltraps>

c0102865 <vector235>:
.globl vector235
vector235:
  pushl $0
c0102865:	6a 00                	push   $0x0
  pushl $235
c0102867:	68 eb 00 00 00       	push   $0xeb
  jmp __alltraps
c010286c:	e9 f0 00 00 00       	jmp    c0102961 <__alltraps>

c0102871 <vector236>:
.globl vector236
vector236:
  pushl $0
c0102871:	6a 00                	push   $0x0
  pushl $236
c0102873:	68 ec 00 00 00       	push   $0xec
  jmp __alltraps
c0102878:	e9 e4 00 00 00       	jmp    c0102961 <__alltraps>

c010287d <vector237>:
.globl vector237
vector237:
  pushl $0
c010287d:	6a 00                	push   $0x0
  pushl $237
c010287f:	68 ed 00 00 00       	push   $0xed
  jmp __alltraps
c0102884:	e9 d8 00 00 00       	jmp    c0102961 <__alltraps>

c0102889 <vector238>:
.globl vector238
vector238:
  pushl $0
c0102889:	6a 00                	push   $0x0
  pushl $238
c010288b:	68 ee 00 00 00       	push   $0xee
  jmp __alltraps
c0102890:	e9 cc 00 00 00       	jmp    c0102961 <__alltraps>

c0102895 <vector239>:
.globl vector239
vector239:
  pushl $0
c0102895:	6a 00                	push   $0x0
  pushl $239
c0102897:	68 ef 00 00 00       	push   $0xef
  jmp __alltraps
c010289c:	e9 c0 00 00 00       	jmp    c0102961 <__alltraps>

c01028a1 <vector240>:
.globl vector240
vector240:
  pushl $0
c01028a1:	6a 00                	push   $0x0
  pushl $240
c01028a3:	68 f0 00 00 00       	push   $0xf0
  jmp __alltraps
c01028a8:	e9 b4 00 00 00       	jmp    c0102961 <__alltraps>

c01028ad <vector241>:
.globl vector241
vector241:
  pushl $0
c01028ad:	6a 00                	push   $0x0
  pushl $241
c01028af:	68 f1 00 00 00       	push   $0xf1
  jmp __alltraps
c01028b4:	e9 a8 00 00 00       	jmp    c0102961 <__alltraps>

c01028b9 <vector242>:
.globl vector242
vector242:
  pushl $0
c01028b9:	6a 00                	push   $0x0
  pushl $242
c01028bb:	68 f2 00 00 00       	push   $0xf2
  jmp __alltraps
c01028c0:	e9 9c 00 00 00       	jmp    c0102961 <__alltraps>

c01028c5 <vector243>:
.globl vector243
vector243:
  pushl $0
c01028c5:	6a 00                	push   $0x0
  pushl $243
c01028c7:	68 f3 00 00 00       	push   $0xf3
  jmp __alltraps
c01028cc:	e9 90 00 00 00       	jmp    c0102961 <__alltraps>

c01028d1 <vector244>:
.globl vector244
vector244:
  pushl $0
c01028d1:	6a 00                	push   $0x0
  pushl $244
c01028d3:	68 f4 00 00 00       	push   $0xf4
  jmp __alltraps
c01028d8:	e9 84 00 00 00       	jmp    c0102961 <__alltraps>

c01028dd <vector245>:
.globl vector245
vector245:
  pushl $0
c01028dd:	6a 00                	push   $0x0
  pushl $245
c01028df:	68 f5 00 00 00       	push   $0xf5
  jmp __alltraps
c01028e4:	e9 78 00 00 00       	jmp    c0102961 <__alltraps>

c01028e9 <vector246>:
.globl vector246
vector246:
  pushl $0
c01028e9:	6a 00                	push   $0x0
  pushl $246
c01028eb:	68 f6 00 00 00       	push   $0xf6
  jmp __alltraps
c01028f0:	e9 6c 00 00 00       	jmp    c0102961 <__alltraps>

c01028f5 <vector247>:
.globl vector247
vector247:
  pushl $0
c01028f5:	6a 00                	push   $0x0
  pushl $247
c01028f7:	68 f7 00 00 00       	push   $0xf7
  jmp __alltraps
c01028fc:	e9 60 00 00 00       	jmp    c0102961 <__alltraps>

c0102901 <vector248>:
.globl vector248
vector248:
  pushl $0
c0102901:	6a 00                	push   $0x0
  pushl $248
c0102903:	68 f8 00 00 00       	push   $0xf8
  jmp __alltraps
c0102908:	e9 54 00 00 00       	jmp    c0102961 <__alltraps>

c010290d <vector249>:
.globl vector249
vector249:
  pushl $0
c010290d:	6a 00                	push   $0x0
  pushl $249
c010290f:	68 f9 00 00 00       	push   $0xf9
  jmp __alltraps
c0102914:	e9 48 00 00 00       	jmp    c0102961 <__alltraps>

c0102919 <vector250>:
.globl vector250
vector250:
  pushl $0
c0102919:	6a 00                	push   $0x0
  pushl $250
c010291b:	68 fa 00 00 00       	push   $0xfa
  jmp __alltraps
c0102920:	e9 3c 00 00 00       	jmp    c0102961 <__alltraps>

c0102925 <vector251>:
.globl vector251
vector251:
  pushl $0
c0102925:	6a 00                	push   $0x0
  pushl $251
c0102927:	68 fb 00 00 00       	push   $0xfb
  jmp __alltraps
c010292c:	e9 30 00 00 00       	jmp    c0102961 <__alltraps>

c0102931 <vector252>:
.globl vector252
vector252:
  pushl $0
c0102931:	6a 00                	push   $0x0
  pushl $252
c0102933:	68 fc 00 00 00       	push   $0xfc
  jmp __alltraps
c0102938:	e9 24 00 00 00       	jmp    c0102961 <__alltraps>

c010293d <vector253>:
.globl vector253
vector253:
  pushl $0
c010293d:	6a 00                	push   $0x0
  pushl $253
c010293f:	68 fd 00 00 00       	push   $0xfd
  jmp __alltraps
c0102944:	e9 18 00 00 00       	jmp    c0102961 <__alltraps>

c0102949 <vector254>:
.globl vector254
vector254:
  pushl $0
c0102949:	6a 00                	push   $0x0
  pushl $254
c010294b:	68 fe 00 00 00       	push   $0xfe
  jmp __alltraps
c0102950:	e9 0c 00 00 00       	jmp    c0102961 <__alltraps>

c0102955 <vector255>:
.globl vector255
vector255:
  pushl $0
c0102955:	6a 00                	push   $0x0
  pushl $255
c0102957:	68 ff 00 00 00       	push   $0xff
  jmp __alltraps
c010295c:	e9 00 00 00 00       	jmp    c0102961 <__alltraps>

c0102961 <__alltraps>:
.text
.globl __alltraps
__alltraps:
    # push registers to build a trap frame
    # therefore make the stack look like a struct trapframe
    pushl %ds
c0102961:	1e                   	push   %ds
    pushl %es
c0102962:	06                   	push   %es
    pushl %fs
c0102963:	0f a0                	push   %fs
    pushl %gs
c0102965:	0f a8                	push   %gs
    pushal
c0102967:	60                   	pusha  

    # load GD_KDATA into %ds and %es to set up data segments for kernel
    movl $GD_KDATA, %eax
c0102968:	b8 10 00 00 00       	mov    $0x10,%eax
    movw %ax, %ds
c010296d:	8e d8                	mov    %eax,%ds
    movw %ax, %es
c010296f:	8e c0                	mov    %eax,%es

    # push %esp to pass a pointer to the trapframe as an argument to trap()
    pushl %esp
c0102971:	54                   	push   %esp

    # call trap(tf), where tf=%esp
    call trap
c0102972:	e8 61 f5 ff ff       	call   c0101ed8 <trap>

    # pop the pushed stack pointer
    popl %esp
c0102977:	5c                   	pop    %esp

c0102978 <__trapret>:

    # return falls through to trapret...
.globl __trapret
__trapret:
    # restore registers from stack
    popal
c0102978:	61                   	popa   

    # restore %ds, %es, %fs and %gs
    popl %gs
c0102979:	0f a9                	pop    %gs
    popl %fs
c010297b:	0f a1                	pop    %fs
    popl %es
c010297d:	07                   	pop    %es
    popl %ds
c010297e:	1f                   	pop    %ds

    # get rid of the trap number and error code
    addl $0x8, %esp
c010297f:	83 c4 08             	add    $0x8,%esp
    iret
c0102982:	cf                   	iret   

c0102983 <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
c0102983:	55                   	push   %ebp
c0102984:	89 e5                	mov    %esp,%ebp
    return page - pages;//返回在物理内存中第几页
c0102986:	8b 45 08             	mov    0x8(%ebp),%eax
c0102989:	8b 15 18 af 11 c0    	mov    0xc011af18,%edx
c010298f:	29 d0                	sub    %edx,%eax
c0102991:	c1 f8 02             	sar    $0x2,%eax
c0102994:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
c010299a:	5d                   	pop    %ebp
c010299b:	c3                   	ret    

c010299c <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
c010299c:	55                   	push   %ebp
c010299d:	89 e5                	mov    %esp,%ebp
    return page2ppn(page) << PGSHIFT;
c010299f:	ff 75 08             	pushl  0x8(%ebp)
c01029a2:	e8 dc ff ff ff       	call   c0102983 <page2ppn>
c01029a7:	83 c4 04             	add    $0x4,%esp
c01029aa:	c1 e0 0c             	shl    $0xc,%eax
}
c01029ad:	c9                   	leave  
c01029ae:	c3                   	ret    

c01029af <pa2page>:

static inline struct Page *
pa2page(uintptr_t pa) {
c01029af:	55                   	push   %ebp
c01029b0:	89 e5                	mov    %esp,%ebp
c01029b2:	83 ec 08             	sub    $0x8,%esp
    if (PPN(pa) >= npage) {
c01029b5:	8b 45 08             	mov    0x8(%ebp),%eax
c01029b8:	c1 e8 0c             	shr    $0xc,%eax
c01029bb:	89 c2                	mov    %eax,%edx
c01029bd:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01029c2:	39 c2                	cmp    %eax,%edx
c01029c4:	72 14                	jb     c01029da <pa2page+0x2b>
        panic("pa2page called with invalid pa");
c01029c6:	83 ec 04             	sub    $0x4,%esp
c01029c9:	68 30 63 10 c0       	push   $0xc0106330
c01029ce:	6a 5a                	push   $0x5a
c01029d0:	68 4f 63 10 c0       	push   $0xc010634f
c01029d5:	e8 09 da ff ff       	call   c01003e3 <__panic>
    }
    return &pages[PPN(pa)];
c01029da:	8b 0d 18 af 11 c0    	mov    0xc011af18,%ecx
c01029e0:	8b 45 08             	mov    0x8(%ebp),%eax
c01029e3:	c1 e8 0c             	shr    $0xc,%eax
c01029e6:	89 c2                	mov    %eax,%edx
c01029e8:	89 d0                	mov    %edx,%eax
c01029ea:	c1 e0 02             	shl    $0x2,%eax
c01029ed:	01 d0                	add    %edx,%eax
c01029ef:	c1 e0 02             	shl    $0x2,%eax
c01029f2:	01 c8                	add    %ecx,%eax
}
c01029f4:	c9                   	leave  
c01029f5:	c3                   	ret    

c01029f6 <page2kva>:

static inline void *
page2kva(struct Page *page) {
c01029f6:	55                   	push   %ebp
c01029f7:	89 e5                	mov    %esp,%ebp
c01029f9:	83 ec 18             	sub    $0x18,%esp
    return KADDR(page2pa(page));
c01029fc:	ff 75 08             	pushl  0x8(%ebp)
c01029ff:	e8 98 ff ff ff       	call   c010299c <page2pa>
c0102a04:	83 c4 04             	add    $0x4,%esp
c0102a07:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0102a0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102a0d:	c1 e8 0c             	shr    $0xc,%eax
c0102a10:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0102a13:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0102a18:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c0102a1b:	72 14                	jb     c0102a31 <page2kva+0x3b>
c0102a1d:	ff 75 f4             	pushl  -0xc(%ebp)
c0102a20:	68 60 63 10 c0       	push   $0xc0106360
c0102a25:	6a 61                	push   $0x61
c0102a27:	68 4f 63 10 c0       	push   $0xc010634f
c0102a2c:	e8 b2 d9 ff ff       	call   c01003e3 <__panic>
c0102a31:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102a34:	2d 00 00 00 40       	sub    $0x40000000,%eax
}
c0102a39:	c9                   	leave  
c0102a3a:	c3                   	ret    

c0102a3b <pte2page>:
kva2page(void *kva) {
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte) {
c0102a3b:	55                   	push   %ebp
c0102a3c:	89 e5                	mov    %esp,%ebp
c0102a3e:	83 ec 08             	sub    $0x8,%esp
    if (!(pte & PTE_P)) {
c0102a41:	8b 45 08             	mov    0x8(%ebp),%eax
c0102a44:	83 e0 01             	and    $0x1,%eax
c0102a47:	85 c0                	test   %eax,%eax
c0102a49:	75 14                	jne    c0102a5f <pte2page+0x24>
        panic("pte2page called with invalid pte");
c0102a4b:	83 ec 04             	sub    $0x4,%esp
c0102a4e:	68 84 63 10 c0       	push   $0xc0106384
c0102a53:	6a 6c                	push   $0x6c
c0102a55:	68 4f 63 10 c0       	push   $0xc010634f
c0102a5a:	e8 84 d9 ff ff       	call   c01003e3 <__panic>
    }
    return pa2page(PTE_ADDR(pte));
c0102a5f:	8b 45 08             	mov    0x8(%ebp),%eax
c0102a62:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0102a67:	83 ec 0c             	sub    $0xc,%esp
c0102a6a:	50                   	push   %eax
c0102a6b:	e8 3f ff ff ff       	call   c01029af <pa2page>
c0102a70:	83 c4 10             	add    $0x10,%esp
}
c0102a73:	c9                   	leave  
c0102a74:	c3                   	ret    

c0102a75 <pde2page>:

static inline struct Page *
pde2page(pde_t pde) {
c0102a75:	55                   	push   %ebp
c0102a76:	89 e5                	mov    %esp,%ebp
c0102a78:	83 ec 08             	sub    $0x8,%esp
    return pa2page(PDE_ADDR(pde));
c0102a7b:	8b 45 08             	mov    0x8(%ebp),%eax
c0102a7e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0102a83:	83 ec 0c             	sub    $0xc,%esp
c0102a86:	50                   	push   %eax
c0102a87:	e8 23 ff ff ff       	call   c01029af <pa2page>
c0102a8c:	83 c4 10             	add    $0x10,%esp
}
c0102a8f:	c9                   	leave  
c0102a90:	c3                   	ret    

c0102a91 <page_ref>:

static inline int
page_ref(struct Page *page) {
c0102a91:	55                   	push   %ebp
c0102a92:	89 e5                	mov    %esp,%ebp
    return page->ref;
c0102a94:	8b 45 08             	mov    0x8(%ebp),%eax
c0102a97:	8b 00                	mov    (%eax),%eax
}
c0102a99:	5d                   	pop    %ebp
c0102a9a:	c3                   	ret    

c0102a9b <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
c0102a9b:	55                   	push   %ebp
c0102a9c:	89 e5                	mov    %esp,%ebp
    page->ref = val;
c0102a9e:	8b 45 08             	mov    0x8(%ebp),%eax
c0102aa1:	8b 55 0c             	mov    0xc(%ebp),%edx
c0102aa4:	89 10                	mov    %edx,(%eax)
}
c0102aa6:	90                   	nop
c0102aa7:	5d                   	pop    %ebp
c0102aa8:	c3                   	ret    

c0102aa9 <page_ref_inc>:

static inline int
page_ref_inc(struct Page *page) {
c0102aa9:	55                   	push   %ebp
c0102aaa:	89 e5                	mov    %esp,%ebp
    page->ref += 1;
c0102aac:	8b 45 08             	mov    0x8(%ebp),%eax
c0102aaf:	8b 00                	mov    (%eax),%eax
c0102ab1:	8d 50 01             	lea    0x1(%eax),%edx
c0102ab4:	8b 45 08             	mov    0x8(%ebp),%eax
c0102ab7:	89 10                	mov    %edx,(%eax)
    return page->ref;
c0102ab9:	8b 45 08             	mov    0x8(%ebp),%eax
c0102abc:	8b 00                	mov    (%eax),%eax
}
c0102abe:	5d                   	pop    %ebp
c0102abf:	c3                   	ret    

c0102ac0 <page_ref_dec>:

static inline int
page_ref_dec(struct Page *page) {
c0102ac0:	55                   	push   %ebp
c0102ac1:	89 e5                	mov    %esp,%ebp
    page->ref -= 1;
c0102ac3:	8b 45 08             	mov    0x8(%ebp),%eax
c0102ac6:	8b 00                	mov    (%eax),%eax
c0102ac8:	8d 50 ff             	lea    -0x1(%eax),%edx
c0102acb:	8b 45 08             	mov    0x8(%ebp),%eax
c0102ace:	89 10                	mov    %edx,(%eax)
    return page->ref;
c0102ad0:	8b 45 08             	mov    0x8(%ebp),%eax
c0102ad3:	8b 00                	mov    (%eax),%eax
}
c0102ad5:	5d                   	pop    %ebp
c0102ad6:	c3                   	ret    

c0102ad7 <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
c0102ad7:	55                   	push   %ebp
c0102ad8:	89 e5                	mov    %esp,%ebp
c0102ada:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
c0102add:	9c                   	pushf  
c0102ade:	58                   	pop    %eax
c0102adf:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
c0102ae2:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
c0102ae5:	25 00 02 00 00       	and    $0x200,%eax
c0102aea:	85 c0                	test   %eax,%eax
c0102aec:	74 0c                	je     c0102afa <__intr_save+0x23>
        intr_disable();
c0102aee:	e8 8c ed ff ff       	call   c010187f <intr_disable>
        return 1;
c0102af3:	b8 01 00 00 00       	mov    $0x1,%eax
c0102af8:	eb 05                	jmp    c0102aff <__intr_save+0x28>
    }
    return 0;
c0102afa:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0102aff:	c9                   	leave  
c0102b00:	c3                   	ret    

c0102b01 <__intr_restore>:

static inline void
__intr_restore(bool flag) {
c0102b01:	55                   	push   %ebp
c0102b02:	89 e5                	mov    %esp,%ebp
c0102b04:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
c0102b07:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0102b0b:	74 05                	je     c0102b12 <__intr_restore+0x11>
        intr_enable();
c0102b0d:	e8 66 ed ff ff       	call   c0101878 <intr_enable>
    }
}
c0102b12:	90                   	nop
c0102b13:	c9                   	leave  
c0102b14:	c3                   	ret    

c0102b15 <lgdt>:
/* *
 * lgdt - load the global descriptor table register and reset the
 * data/code segement registers for kernel.
 * */
static inline void
lgdt(struct pseudodesc *pd) {                                         //加载gdt地址到gdtr
c0102b15:	55                   	push   %ebp
c0102b16:	89 e5                	mov    %esp,%ebp
    asm volatile ("lgdt (%0)" :: "r" (pd));
c0102b18:	8b 45 08             	mov    0x8(%ebp),%eax
c0102b1b:	0f 01 10             	lgdtl  (%eax)
    asm volatile ("movw %%ax, %%gs" :: "a" (USER_DS));
c0102b1e:	b8 23 00 00 00       	mov    $0x23,%eax
c0102b23:	8e e8                	mov    %eax,%gs
    asm volatile ("movw %%ax, %%fs" :: "a" (USER_DS));
c0102b25:	b8 23 00 00 00       	mov    $0x23,%eax
c0102b2a:	8e e0                	mov    %eax,%fs
    asm volatile ("movw %%ax, %%es" :: "a" (KERNEL_DS));
c0102b2c:	b8 10 00 00 00       	mov    $0x10,%eax
c0102b31:	8e c0                	mov    %eax,%es
    asm volatile ("movw %%ax, %%ds" :: "a" (KERNEL_DS));
c0102b33:	b8 10 00 00 00       	mov    $0x10,%eax
c0102b38:	8e d8                	mov    %eax,%ds
    asm volatile ("movw %%ax, %%ss" :: "a" (KERNEL_DS));
c0102b3a:	b8 10 00 00 00       	mov    $0x10,%eax
c0102b3f:	8e d0                	mov    %eax,%ss
    // reload cs
    asm volatile ("ljmp %0, $1f\n 1:\n" :: "i" (KERNEL_CS));
c0102b41:	ea 48 2b 10 c0 08 00 	ljmp   $0x8,$0xc0102b48
}
c0102b48:	90                   	nop
c0102b49:	5d                   	pop    %ebp
c0102b4a:	c3                   	ret    

c0102b4b <load_esp0>:
 * load_esp0 - change the ESP0 in default task state segment,
 * so that we can use different kernel stack when we trap frame
 * user to kernel.
 * */
void
load_esp0(uintptr_t esp0) {
c0102b4b:	55                   	push   %ebp
c0102b4c:	89 e5                	mov    %esp,%ebp
    ts.ts_esp0 = esp0;
c0102b4e:	8b 45 08             	mov    0x8(%ebp),%eax
c0102b51:	a3 a4 ae 11 c0       	mov    %eax,0xc011aea4
}
c0102b56:	90                   	nop
c0102b57:	5d                   	pop    %ebp
c0102b58:	c3                   	ret    

c0102b59 <gdt_init>:

/* gdt_init - initialize the default GDT and TSS */
static void
gdt_init(void) {
c0102b59:	55                   	push   %ebp
c0102b5a:	89 e5                	mov    %esp,%ebp
c0102b5c:	83 ec 10             	sub    $0x10,%esp
    // set boot kernel stack and default SS0
    load_esp0((uintptr_t)bootstacktop);
c0102b5f:	b8 00 70 11 c0       	mov    $0xc0117000,%eax
c0102b64:	50                   	push   %eax
c0102b65:	e8 e1 ff ff ff       	call   c0102b4b <load_esp0>
c0102b6a:	83 c4 04             	add    $0x4,%esp
    ts.ts_ss0 = KERNEL_DS;
c0102b6d:	66 c7 05 a8 ae 11 c0 	movw   $0x10,0xc011aea8
c0102b74:	10 00 

    // initialize the TSS filed of the gdt
    gdt[SEG_TSS] = SEGTSS(STS_T32A, (uintptr_t)&ts, sizeof(ts), DPL_KERNEL);
c0102b76:	66 c7 05 28 7a 11 c0 	movw   $0x68,0xc0117a28
c0102b7d:	68 00 
c0102b7f:	b8 a0 ae 11 c0       	mov    $0xc011aea0,%eax
c0102b84:	66 a3 2a 7a 11 c0    	mov    %ax,0xc0117a2a
c0102b8a:	b8 a0 ae 11 c0       	mov    $0xc011aea0,%eax
c0102b8f:	c1 e8 10             	shr    $0x10,%eax
c0102b92:	a2 2c 7a 11 c0       	mov    %al,0xc0117a2c
c0102b97:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c0102b9e:	83 e0 f0             	and    $0xfffffff0,%eax
c0102ba1:	83 c8 09             	or     $0x9,%eax
c0102ba4:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c0102ba9:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c0102bb0:	83 e0 ef             	and    $0xffffffef,%eax
c0102bb3:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c0102bb8:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c0102bbf:	83 e0 9f             	and    $0xffffff9f,%eax
c0102bc2:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c0102bc7:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c0102bce:	83 c8 80             	or     $0xffffff80,%eax
c0102bd1:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c0102bd6:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102bdd:	83 e0 f0             	and    $0xfffffff0,%eax
c0102be0:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102be5:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102bec:	83 e0 ef             	and    $0xffffffef,%eax
c0102bef:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102bf4:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102bfb:	83 e0 df             	and    $0xffffffdf,%eax
c0102bfe:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102c03:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102c0a:	83 c8 40             	or     $0x40,%eax
c0102c0d:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102c12:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102c19:	83 e0 7f             	and    $0x7f,%eax
c0102c1c:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102c21:	b8 a0 ae 11 c0       	mov    $0xc011aea0,%eax
c0102c26:	c1 e8 18             	shr    $0x18,%eax
c0102c29:	a2 2f 7a 11 c0       	mov    %al,0xc0117a2f

    // reload all segment registers
    lgdt(&gdt_pd);
c0102c2e:	68 30 7a 11 c0       	push   $0xc0117a30
c0102c33:	e8 dd fe ff ff       	call   c0102b15 <lgdt>
c0102c38:	83 c4 04             	add    $0x4,%esp
c0102c3b:	66 c7 45 fe 28 00    	movw   $0x28,-0x2(%ebp)
    asm volatile ("cli" ::: "memory");
}

static inline void
ltr(uint16_t sel) {
    asm volatile ("ltr %0" :: "r" (sel) : "memory");
c0102c41:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
c0102c45:	0f 00 d8             	ltr    %ax

    // load the TSS
    ltr(GD_TSS);
}
c0102c48:	90                   	nop
c0102c49:	c9                   	leave  
c0102c4a:	c3                   	ret    

c0102c4b <init_pmm_manager>:

//init_pmm_manager - initialize a pmm_manager instance
static void
init_pmm_manager(void) {
c0102c4b:	55                   	push   %ebp
c0102c4c:	89 e5                	mov    %esp,%ebp
c0102c4e:	83 ec 08             	sub    $0x8,%esp
    pmm_manager = &default_pmm_manager;
c0102c51:	c7 05 10 af 11 c0 54 	movl   $0xc0106d54,0xc011af10
c0102c58:	6d 10 c0 
    cprintf("memory management: %s\n", pmm_manager->name);
c0102c5b:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102c60:	8b 00                	mov    (%eax),%eax
c0102c62:	83 ec 08             	sub    $0x8,%esp
c0102c65:	50                   	push   %eax
c0102c66:	68 b0 63 10 c0       	push   $0xc01063b0
c0102c6b:	e8 0d d6 ff ff       	call   c010027d <cprintf>
c0102c70:	83 c4 10             	add    $0x10,%esp
    pmm_manager->init();
c0102c73:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102c78:	8b 40 04             	mov    0x4(%eax),%eax
c0102c7b:	ff d0                	call   *%eax
}
c0102c7d:	90                   	nop
c0102c7e:	c9                   	leave  
c0102c7f:	c3                   	ret    

c0102c80 <init_memmap>:

//init_memmap - call pmm->init_memmap to build Page struct for free memory  
static void
init_memmap(struct Page *base, size_t n) {
c0102c80:	55                   	push   %ebp
c0102c81:	89 e5                	mov    %esp,%ebp
c0102c83:	83 ec 08             	sub    $0x8,%esp
    pmm_manager->init_memmap(base, n);
c0102c86:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102c8b:	8b 40 08             	mov    0x8(%eax),%eax
c0102c8e:	83 ec 08             	sub    $0x8,%esp
c0102c91:	ff 75 0c             	pushl  0xc(%ebp)
c0102c94:	ff 75 08             	pushl  0x8(%ebp)
c0102c97:	ff d0                	call   *%eax
c0102c99:	83 c4 10             	add    $0x10,%esp
}
c0102c9c:	90                   	nop
c0102c9d:	c9                   	leave  
c0102c9e:	c3                   	ret    

c0102c9f <alloc_pages>:

//alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE memory 
struct Page *
alloc_pages(size_t n) {
c0102c9f:	55                   	push   %ebp
c0102ca0:	89 e5                	mov    %esp,%ebp
c0102ca2:	83 ec 18             	sub    $0x18,%esp
    struct Page *page=NULL;
c0102ca5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
c0102cac:	e8 26 fe ff ff       	call   c0102ad7 <__intr_save>
c0102cb1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        page = pmm_manager->alloc_pages(n);
c0102cb4:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102cb9:	8b 40 0c             	mov    0xc(%eax),%eax
c0102cbc:	83 ec 0c             	sub    $0xc,%esp
c0102cbf:	ff 75 08             	pushl  0x8(%ebp)
c0102cc2:	ff d0                	call   *%eax
c0102cc4:	83 c4 10             	add    $0x10,%esp
c0102cc7:	89 45 f4             	mov    %eax,-0xc(%ebp)
    }
    local_intr_restore(intr_flag);
c0102cca:	83 ec 0c             	sub    $0xc,%esp
c0102ccd:	ff 75 f0             	pushl  -0x10(%ebp)
c0102cd0:	e8 2c fe ff ff       	call   c0102b01 <__intr_restore>
c0102cd5:	83 c4 10             	add    $0x10,%esp
    return page;
c0102cd8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0102cdb:	c9                   	leave  
c0102cdc:	c3                   	ret    

c0102cdd <free_pages>:

//free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory 
void
free_pages(struct Page *base, size_t n) {
c0102cdd:	55                   	push   %ebp
c0102cde:	89 e5                	mov    %esp,%ebp
c0102ce0:	83 ec 18             	sub    $0x18,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
c0102ce3:	e8 ef fd ff ff       	call   c0102ad7 <__intr_save>
c0102ce8:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        pmm_manager->free_pages(base, n);
c0102ceb:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102cf0:	8b 40 10             	mov    0x10(%eax),%eax
c0102cf3:	83 ec 08             	sub    $0x8,%esp
c0102cf6:	ff 75 0c             	pushl  0xc(%ebp)
c0102cf9:	ff 75 08             	pushl  0x8(%ebp)
c0102cfc:	ff d0                	call   *%eax
c0102cfe:	83 c4 10             	add    $0x10,%esp
    }
    local_intr_restore(intr_flag);
c0102d01:	83 ec 0c             	sub    $0xc,%esp
c0102d04:	ff 75 f4             	pushl  -0xc(%ebp)
c0102d07:	e8 f5 fd ff ff       	call   c0102b01 <__intr_restore>
c0102d0c:	83 c4 10             	add    $0x10,%esp
}
c0102d0f:	90                   	nop
c0102d10:	c9                   	leave  
c0102d11:	c3                   	ret    

c0102d12 <nr_free_pages>:

//nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE) 
//of current free memory
size_t
nr_free_pages(void) {
c0102d12:	55                   	push   %ebp
c0102d13:	89 e5                	mov    %esp,%ebp
c0102d15:	83 ec 18             	sub    $0x18,%esp
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
c0102d18:	e8 ba fd ff ff       	call   c0102ad7 <__intr_save>
c0102d1d:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        ret = pmm_manager->nr_free_pages();
c0102d20:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102d25:	8b 40 14             	mov    0x14(%eax),%eax
c0102d28:	ff d0                	call   *%eax
c0102d2a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    }
    local_intr_restore(intr_flag);
c0102d2d:	83 ec 0c             	sub    $0xc,%esp
c0102d30:	ff 75 f4             	pushl  -0xc(%ebp)
c0102d33:	e8 c9 fd ff ff       	call   c0102b01 <__intr_restore>
c0102d38:	83 c4 10             	add    $0x10,%esp
    return ret;
c0102d3b:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
c0102d3e:	c9                   	leave  
c0102d3f:	c3                   	ret    

c0102d40 <page_init>:

/* pmm_init - initialize the physical memory management */
static void
page_init(void) {
c0102d40:	55                   	push   %ebp
c0102d41:	89 e5                	mov    %esp,%ebp
c0102d43:	57                   	push   %edi
c0102d44:	56                   	push   %esi
c0102d45:	53                   	push   %ebx
c0102d46:	83 ec 7c             	sub    $0x7c,%esp
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
c0102d49:	c7 45 c4 00 80 00 c0 	movl   $0xc0008000,-0x3c(%ebp)
    uint64_t maxpa = 0;
c0102d50:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
c0102d57:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

    cprintf("e820map:\n");
c0102d5e:	83 ec 0c             	sub    $0xc,%esp
c0102d61:	68 c7 63 10 c0       	push   $0xc01063c7
c0102d66:	e8 12 d5 ff ff       	call   c010027d <cprintf>
c0102d6b:	83 c4 10             	add    $0x10,%esp
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
c0102d6e:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0102d75:	e9 fc 00 00 00       	jmp    c0102e76 <page_init+0x136>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
c0102d7a:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102d7d:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102d80:	89 d0                	mov    %edx,%eax
c0102d82:	c1 e0 02             	shl    $0x2,%eax
c0102d85:	01 d0                	add    %edx,%eax
c0102d87:	c1 e0 02             	shl    $0x2,%eax
c0102d8a:	01 c8                	add    %ecx,%eax
c0102d8c:	8b 50 08             	mov    0x8(%eax),%edx
c0102d8f:	8b 40 04             	mov    0x4(%eax),%eax
c0102d92:	89 45 b8             	mov    %eax,-0x48(%ebp)
c0102d95:	89 55 bc             	mov    %edx,-0x44(%ebp)
c0102d98:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102d9b:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102d9e:	89 d0                	mov    %edx,%eax
c0102da0:	c1 e0 02             	shl    $0x2,%eax
c0102da3:	01 d0                	add    %edx,%eax
c0102da5:	c1 e0 02             	shl    $0x2,%eax
c0102da8:	01 c8                	add    %ecx,%eax
c0102daa:	8b 48 0c             	mov    0xc(%eax),%ecx
c0102dad:	8b 58 10             	mov    0x10(%eax),%ebx
c0102db0:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0102db3:	8b 55 bc             	mov    -0x44(%ebp),%edx
c0102db6:	01 c8                	add    %ecx,%eax
c0102db8:	11 da                	adc    %ebx,%edx
c0102dba:	89 45 b0             	mov    %eax,-0x50(%ebp)
c0102dbd:	89 55 b4             	mov    %edx,-0x4c(%ebp)
        cprintf("  memory: %08llx, [%08llx, %08llx], type = %d.\n",
c0102dc0:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102dc3:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102dc6:	89 d0                	mov    %edx,%eax
c0102dc8:	c1 e0 02             	shl    $0x2,%eax
c0102dcb:	01 d0                	add    %edx,%eax
c0102dcd:	c1 e0 02             	shl    $0x2,%eax
c0102dd0:	01 c8                	add    %ecx,%eax
c0102dd2:	83 c0 14             	add    $0x14,%eax
c0102dd5:	8b 00                	mov    (%eax),%eax
c0102dd7:	89 45 84             	mov    %eax,-0x7c(%ebp)
c0102dda:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0102ddd:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0102de0:	83 c0 ff             	add    $0xffffffff,%eax
c0102de3:	83 d2 ff             	adc    $0xffffffff,%edx
c0102de6:	89 c1                	mov    %eax,%ecx
c0102de8:	89 d3                	mov    %edx,%ebx
c0102dea:	8b 55 c4             	mov    -0x3c(%ebp),%edx
c0102ded:	89 55 80             	mov    %edx,-0x80(%ebp)
c0102df0:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102df3:	89 d0                	mov    %edx,%eax
c0102df5:	c1 e0 02             	shl    $0x2,%eax
c0102df8:	01 d0                	add    %edx,%eax
c0102dfa:	c1 e0 02             	shl    $0x2,%eax
c0102dfd:	03 45 80             	add    -0x80(%ebp),%eax
c0102e00:	8b 50 10             	mov    0x10(%eax),%edx
c0102e03:	8b 40 0c             	mov    0xc(%eax),%eax
c0102e06:	ff 75 84             	pushl  -0x7c(%ebp)
c0102e09:	53                   	push   %ebx
c0102e0a:	51                   	push   %ecx
c0102e0b:	ff 75 bc             	pushl  -0x44(%ebp)
c0102e0e:	ff 75 b8             	pushl  -0x48(%ebp)
c0102e11:	52                   	push   %edx
c0102e12:	50                   	push   %eax
c0102e13:	68 d4 63 10 c0       	push   $0xc01063d4
c0102e18:	e8 60 d4 ff ff       	call   c010027d <cprintf>
c0102e1d:	83 c4 20             	add    $0x20,%esp
                memmap->map[i].size, begin, end - 1, memmap->map[i].type);
        if (memmap->map[i].type == E820_ARM) {
c0102e20:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102e23:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102e26:	89 d0                	mov    %edx,%eax
c0102e28:	c1 e0 02             	shl    $0x2,%eax
c0102e2b:	01 d0                	add    %edx,%eax
c0102e2d:	c1 e0 02             	shl    $0x2,%eax
c0102e30:	01 c8                	add    %ecx,%eax
c0102e32:	83 c0 14             	add    $0x14,%eax
c0102e35:	8b 00                	mov    (%eax),%eax
c0102e37:	83 f8 01             	cmp    $0x1,%eax
c0102e3a:	75 36                	jne    c0102e72 <page_init+0x132>
            if (maxpa < end && begin < KMEMSIZE) {
c0102e3c:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0102e3f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0102e42:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
c0102e45:	77 2b                	ja     c0102e72 <page_init+0x132>
c0102e47:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
c0102e4a:	72 05                	jb     c0102e51 <page_init+0x111>
c0102e4c:	3b 45 b0             	cmp    -0x50(%ebp),%eax
c0102e4f:	73 21                	jae    c0102e72 <page_init+0x132>
c0102e51:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
c0102e55:	77 1b                	ja     c0102e72 <page_init+0x132>
c0102e57:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
c0102e5b:	72 09                	jb     c0102e66 <page_init+0x126>
c0102e5d:	81 7d b8 ff ff ff 37 	cmpl   $0x37ffffff,-0x48(%ebp)
c0102e64:	77 0c                	ja     c0102e72 <page_init+0x132>
                maxpa = end;
c0102e66:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0102e69:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0102e6c:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0102e6f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
    uint64_t maxpa = 0;

    cprintf("e820map:\n");
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
c0102e72:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
c0102e76:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0102e79:	8b 00                	mov    (%eax),%eax
c0102e7b:	3b 45 dc             	cmp    -0x24(%ebp),%eax
c0102e7e:	0f 8f f6 fe ff ff    	jg     c0102d7a <page_init+0x3a>
            if (maxpa < end && begin < KMEMSIZE) {
                maxpa = end;
            }//探测最大内存空间
        }
    }
    if (maxpa > KMEMSIZE) {
c0102e84:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0102e88:	72 1d                	jb     c0102ea7 <page_init+0x167>
c0102e8a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0102e8e:	77 09                	ja     c0102e99 <page_init+0x159>
c0102e90:	81 7d e0 00 00 00 38 	cmpl   $0x38000000,-0x20(%ebp)
c0102e97:	76 0e                	jbe    c0102ea7 <page_init+0x167>
        maxpa = KMEMSIZE;
c0102e99:	c7 45 e0 00 00 00 38 	movl   $0x38000000,-0x20(%ebp)
c0102ea0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    }  //不超过最大可用内存空间

    extern char end[]; //bootloader加载kernel的结束地址，用来存放page

    npage = maxpa / PGSIZE; //最大页表数目
c0102ea7:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0102eaa:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0102ead:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
c0102eb1:	c1 ea 0c             	shr    $0xc,%edx
c0102eb4:	a3 80 ae 11 c0       	mov    %eax,0xc011ae80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);//指向end所在页表后的第一个页表 虚拟地址  存放页表
c0102eb9:	c7 45 ac 00 10 00 00 	movl   $0x1000,-0x54(%ebp)
c0102ec0:	b8 28 af 11 c0       	mov    $0xc011af28,%eax
c0102ec5:	8d 50 ff             	lea    -0x1(%eax),%edx
c0102ec8:	8b 45 ac             	mov    -0x54(%ebp),%eax
c0102ecb:	01 d0                	add    %edx,%eax
c0102ecd:	89 45 a8             	mov    %eax,-0x58(%ebp)
c0102ed0:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0102ed3:	ba 00 00 00 00       	mov    $0x0,%edx
c0102ed8:	f7 75 ac             	divl   -0x54(%ebp)
c0102edb:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0102ede:	29 d0                	sub    %edx,%eax
c0102ee0:	a3 18 af 11 c0       	mov    %eax,0xc011af18

    for (i = 0; i < npage; i ++) {
c0102ee5:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0102eec:	eb 2f                	jmp    c0102f1d <page_init+0x1dd>
        SetPageReserved(pages + i);
c0102eee:	8b 0d 18 af 11 c0    	mov    0xc011af18,%ecx
c0102ef4:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102ef7:	89 d0                	mov    %edx,%eax
c0102ef9:	c1 e0 02             	shl    $0x2,%eax
c0102efc:	01 d0                	add    %edx,%eax
c0102efe:	c1 e0 02             	shl    $0x2,%eax
c0102f01:	01 c8                	add    %ecx,%eax
c0102f03:	83 c0 04             	add    $0x4,%eax
c0102f06:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
c0102f0d:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0102f10:	8b 45 8c             	mov    -0x74(%ebp),%eax
c0102f13:	8b 55 90             	mov    -0x70(%ebp),%edx
c0102f16:	0f ab 10             	bts    %edx,(%eax)
    extern char end[]; //bootloader加载kernel的结束地址，用来存放page

    npage = maxpa / PGSIZE; //最大页表数目
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);//指向end所在页表后的第一个页表 虚拟地址  存放页表

    for (i = 0; i < npage; i ++) {
c0102f19:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
c0102f1d:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102f20:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0102f25:	39 c2                	cmp    %eax,%edx
c0102f27:	72 c5                	jb     c0102eee <page_init+0x1ae>
        SetPageReserved(pages + i);
    }//暂时都设置为保留

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);//实地址，空闲表
c0102f29:	8b 15 80 ae 11 c0    	mov    0xc011ae80,%edx
c0102f2f:	89 d0                	mov    %edx,%eax
c0102f31:	c1 e0 02             	shl    $0x2,%eax
c0102f34:	01 d0                	add    %edx,%eax
c0102f36:	c1 e0 02             	shl    $0x2,%eax
c0102f39:	89 c2                	mov    %eax,%edx
c0102f3b:	a1 18 af 11 c0       	mov    0xc011af18,%eax
c0102f40:	01 d0                	add    %edx,%eax
c0102f42:	89 45 a4             	mov    %eax,-0x5c(%ebp)
c0102f45:	81 7d a4 ff ff ff bf 	cmpl   $0xbfffffff,-0x5c(%ebp)
c0102f4c:	77 17                	ja     c0102f65 <page_init+0x225>
c0102f4e:	ff 75 a4             	pushl  -0x5c(%ebp)
c0102f51:	68 04 64 10 c0       	push   $0xc0106404
c0102f56:	68 dc 00 00 00       	push   $0xdc
c0102f5b:	68 28 64 10 c0       	push   $0xc0106428
c0102f60:	e8 7e d4 ff ff       	call   c01003e3 <__panic>
c0102f65:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0102f68:	05 00 00 00 40       	add    $0x40000000,%eax
c0102f6d:	89 45 a0             	mov    %eax,-0x60(%ebp)

    for (i = 0; i < memmap->nr_map; i ++) {
c0102f70:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0102f77:	e9 69 01 00 00       	jmp    c01030e5 <page_init+0x3a5>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
c0102f7c:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102f7f:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102f82:	89 d0                	mov    %edx,%eax
c0102f84:	c1 e0 02             	shl    $0x2,%eax
c0102f87:	01 d0                	add    %edx,%eax
c0102f89:	c1 e0 02             	shl    $0x2,%eax
c0102f8c:	01 c8                	add    %ecx,%eax
c0102f8e:	8b 50 08             	mov    0x8(%eax),%edx
c0102f91:	8b 40 04             	mov    0x4(%eax),%eax
c0102f94:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0102f97:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c0102f9a:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102f9d:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102fa0:	89 d0                	mov    %edx,%eax
c0102fa2:	c1 e0 02             	shl    $0x2,%eax
c0102fa5:	01 d0                	add    %edx,%eax
c0102fa7:	c1 e0 02             	shl    $0x2,%eax
c0102faa:	01 c8                	add    %ecx,%eax
c0102fac:	8b 48 0c             	mov    0xc(%eax),%ecx
c0102faf:	8b 58 10             	mov    0x10(%eax),%ebx
c0102fb2:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0102fb5:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0102fb8:	01 c8                	add    %ecx,%eax
c0102fba:	11 da                	adc    %ebx,%edx
c0102fbc:	89 45 c8             	mov    %eax,-0x38(%ebp)
c0102fbf:	89 55 cc             	mov    %edx,-0x34(%ebp)
        if (memmap->map[i].type == E820_ARM) {
c0102fc2:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102fc5:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102fc8:	89 d0                	mov    %edx,%eax
c0102fca:	c1 e0 02             	shl    $0x2,%eax
c0102fcd:	01 d0                	add    %edx,%eax
c0102fcf:	c1 e0 02             	shl    $0x2,%eax
c0102fd2:	01 c8                	add    %ecx,%eax
c0102fd4:	83 c0 14             	add    $0x14,%eax
c0102fd7:	8b 00                	mov    (%eax),%eax
c0102fd9:	83 f8 01             	cmp    $0x1,%eax
c0102fdc:	0f 85 ff 00 00 00    	jne    c01030e1 <page_init+0x3a1>
            if (begin < freemem) {
c0102fe2:	8b 45 a0             	mov    -0x60(%ebp),%eax
c0102fe5:	ba 00 00 00 00       	mov    $0x0,%edx
c0102fea:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0102fed:	72 17                	jb     c0103006 <page_init+0x2c6>
c0102fef:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0102ff2:	77 05                	ja     c0102ff9 <page_init+0x2b9>
c0102ff4:	3b 45 d0             	cmp    -0x30(%ebp),%eax
c0102ff7:	76 0d                	jbe    c0103006 <page_init+0x2c6>
                begin = freemem;
c0102ff9:	8b 45 a0             	mov    -0x60(%ebp),%eax
c0102ffc:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0102fff:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
            }
            if (end > KMEMSIZE) {
c0103006:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
c010300a:	72 1d                	jb     c0103029 <page_init+0x2e9>
c010300c:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
c0103010:	77 09                	ja     c010301b <page_init+0x2db>
c0103012:	81 7d c8 00 00 00 38 	cmpl   $0x38000000,-0x38(%ebp)
c0103019:	76 0e                	jbe    c0103029 <page_init+0x2e9>
                end = KMEMSIZE;
c010301b:	c7 45 c8 00 00 00 38 	movl   $0x38000000,-0x38(%ebp)
c0103022:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
            }
            if (begin < end) {
c0103029:	8b 45 d0             	mov    -0x30(%ebp),%eax
c010302c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c010302f:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0103032:	0f 87 a9 00 00 00    	ja     c01030e1 <page_init+0x3a1>
c0103038:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c010303b:	72 09                	jb     c0103046 <page_init+0x306>
c010303d:	3b 45 c8             	cmp    -0x38(%ebp),%eax
c0103040:	0f 83 9b 00 00 00    	jae    c01030e1 <page_init+0x3a1>
                begin = ROUNDUP(begin, PGSIZE);
c0103046:	c7 45 9c 00 10 00 00 	movl   $0x1000,-0x64(%ebp)
c010304d:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0103050:	8b 45 9c             	mov    -0x64(%ebp),%eax
c0103053:	01 d0                	add    %edx,%eax
c0103055:	83 e8 01             	sub    $0x1,%eax
c0103058:	89 45 98             	mov    %eax,-0x68(%ebp)
c010305b:	8b 45 98             	mov    -0x68(%ebp),%eax
c010305e:	ba 00 00 00 00       	mov    $0x0,%edx
c0103063:	f7 75 9c             	divl   -0x64(%ebp)
c0103066:	8b 45 98             	mov    -0x68(%ebp),%eax
c0103069:	29 d0                	sub    %edx,%eax
c010306b:	ba 00 00 00 00       	mov    $0x0,%edx
c0103070:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0103073:	89 55 d4             	mov    %edx,-0x2c(%ebp)
                end = ROUNDDOWN(end, PGSIZE);
c0103076:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0103079:	89 45 94             	mov    %eax,-0x6c(%ebp)
c010307c:	8b 45 94             	mov    -0x6c(%ebp),%eax
c010307f:	ba 00 00 00 00       	mov    $0x0,%edx
c0103084:	89 c3                	mov    %eax,%ebx
c0103086:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
c010308c:	89 de                	mov    %ebx,%esi
c010308e:	89 d0                	mov    %edx,%eax
c0103090:	83 e0 00             	and    $0x0,%eax
c0103093:	89 c7                	mov    %eax,%edi
c0103095:	89 75 c8             	mov    %esi,-0x38(%ebp)
c0103098:	89 7d cc             	mov    %edi,-0x34(%ebp)
                if (begin < end) {
c010309b:	8b 45 d0             	mov    -0x30(%ebp),%eax
c010309e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01030a1:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c01030a4:	77 3b                	ja     c01030e1 <page_init+0x3a1>
c01030a6:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c01030a9:	72 05                	jb     c01030b0 <page_init+0x370>
c01030ab:	3b 45 c8             	cmp    -0x38(%ebp),%eax
c01030ae:	73 31                	jae    c01030e1 <page_init+0x3a1>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);//空闲页表初始化
c01030b0:	8b 45 c8             	mov    -0x38(%ebp),%eax
c01030b3:	8b 55 cc             	mov    -0x34(%ebp),%edx
c01030b6:	2b 45 d0             	sub    -0x30(%ebp),%eax
c01030b9:	1b 55 d4             	sbb    -0x2c(%ebp),%edx
c01030bc:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
c01030c0:	c1 ea 0c             	shr    $0xc,%edx
c01030c3:	89 c3                	mov    %eax,%ebx
c01030c5:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01030c8:	83 ec 0c             	sub    $0xc,%esp
c01030cb:	50                   	push   %eax
c01030cc:	e8 de f8 ff ff       	call   c01029af <pa2page>
c01030d1:	83 c4 10             	add    $0x10,%esp
c01030d4:	83 ec 08             	sub    $0x8,%esp
c01030d7:	53                   	push   %ebx
c01030d8:	50                   	push   %eax
c01030d9:	e8 a2 fb ff ff       	call   c0102c80 <init_memmap>
c01030de:	83 c4 10             	add    $0x10,%esp
        SetPageReserved(pages + i);
    }//暂时都设置为保留

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);//实地址，空闲表

    for (i = 0; i < memmap->nr_map; i ++) {
c01030e1:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
c01030e5:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c01030e8:	8b 00                	mov    (%eax),%eax
c01030ea:	3b 45 dc             	cmp    -0x24(%ebp),%eax
c01030ed:	0f 8f 89 fe ff ff    	jg     c0102f7c <page_init+0x23c>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);//空闲页表初始化
                }
            }
        }
    }
}
c01030f3:	90                   	nop
c01030f4:	8d 65 f4             	lea    -0xc(%ebp),%esp
c01030f7:	5b                   	pop    %ebx
c01030f8:	5e                   	pop    %esi
c01030f9:	5f                   	pop    %edi
c01030fa:	5d                   	pop    %ebp
c01030fb:	c3                   	ret    

c01030fc <boot_map_segment>:
//  la:   linear address of this memory need to map (after x86 segment map)
//  size: memory size
//  pa:   physical address of this memory
//  perm: permission of this memory  
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
c01030fc:	55                   	push   %ebp
c01030fd:	89 e5                	mov    %esp,%ebp
c01030ff:	83 ec 28             	sub    $0x28,%esp
    assert(PGOFF(la) == PGOFF(pa));
c0103102:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103105:	33 45 14             	xor    0x14(%ebp),%eax
c0103108:	25 ff 0f 00 00       	and    $0xfff,%eax
c010310d:	85 c0                	test   %eax,%eax
c010310f:	74 19                	je     c010312a <boot_map_segment+0x2e>
c0103111:	68 36 64 10 c0       	push   $0xc0106436
c0103116:	68 4d 64 10 c0       	push   $0xc010644d
c010311b:	68 fa 00 00 00       	push   $0xfa
c0103120:	68 28 64 10 c0       	push   $0xc0106428
c0103125:	e8 b9 d2 ff ff       	call   c01003e3 <__panic>
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
c010312a:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
c0103131:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103134:	25 ff 0f 00 00       	and    $0xfff,%eax
c0103139:	89 c2                	mov    %eax,%edx
c010313b:	8b 45 10             	mov    0x10(%ebp),%eax
c010313e:	01 c2                	add    %eax,%edx
c0103140:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103143:	01 d0                	add    %edx,%eax
c0103145:	83 e8 01             	sub    $0x1,%eax
c0103148:	89 45 ec             	mov    %eax,-0x14(%ebp)
c010314b:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010314e:	ba 00 00 00 00       	mov    $0x0,%edx
c0103153:	f7 75 f0             	divl   -0x10(%ebp)
c0103156:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103159:	29 d0                	sub    %edx,%eax
c010315b:	c1 e8 0c             	shr    $0xc,%eax
c010315e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    la = ROUNDDOWN(la, PGSIZE);
c0103161:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103164:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0103167:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010316a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c010316f:	89 45 0c             	mov    %eax,0xc(%ebp)
    pa = ROUNDDOWN(pa, PGSIZE);
c0103172:	8b 45 14             	mov    0x14(%ebp),%eax
c0103175:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0103178:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010317b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103180:	89 45 14             	mov    %eax,0x14(%ebp)
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
c0103183:	eb 57                	jmp    c01031dc <boot_map_segment+0xe0>
        pte_t *ptep = get_pte(pgdir, la, 1);
c0103185:	83 ec 04             	sub    $0x4,%esp
c0103188:	6a 01                	push   $0x1
c010318a:	ff 75 0c             	pushl  0xc(%ebp)
c010318d:	ff 75 08             	pushl  0x8(%ebp)
c0103190:	e8 53 01 00 00       	call   c01032e8 <get_pte>
c0103195:	83 c4 10             	add    $0x10,%esp
c0103198:	89 45 e0             	mov    %eax,-0x20(%ebp)
        assert(ptep != NULL);
c010319b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
c010319f:	75 19                	jne    c01031ba <boot_map_segment+0xbe>
c01031a1:	68 62 64 10 c0       	push   $0xc0106462
c01031a6:	68 4d 64 10 c0       	push   $0xc010644d
c01031ab:	68 00 01 00 00       	push   $0x100
c01031b0:	68 28 64 10 c0       	push   $0xc0106428
c01031b5:	e8 29 d2 ff ff       	call   c01003e3 <__panic>
        *ptep = pa | PTE_P | perm;
c01031ba:	8b 45 14             	mov    0x14(%ebp),%eax
c01031bd:	0b 45 18             	or     0x18(%ebp),%eax
c01031c0:	83 c8 01             	or     $0x1,%eax
c01031c3:	89 c2                	mov    %eax,%edx
c01031c5:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01031c8:	89 10                	mov    %edx,(%eax)
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
    assert(PGOFF(la) == PGOFF(pa));
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
c01031ca:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
c01031ce:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
c01031d5:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
c01031dc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01031e0:	75 a3                	jne    c0103185 <boot_map_segment+0x89>
        pte_t *ptep = get_pte(pgdir, la, 1);
        assert(ptep != NULL);
        *ptep = pa | PTE_P | perm;
    }
}
c01031e2:	90                   	nop
c01031e3:	c9                   	leave  
c01031e4:	c3                   	ret    

c01031e5 <boot_alloc_page>:

//boot_alloc_page - allocate one page using pmm->alloc_pages(1) 
// return value: the kernel virtual address of this allocated page
//note: this function is used to get the memory for PDT(Page Directory Table)&PT(Page Table)
static void *
boot_alloc_page(void) {
c01031e5:	55                   	push   %ebp
c01031e6:	89 e5                	mov    %esp,%ebp
c01031e8:	83 ec 18             	sub    $0x18,%esp
    struct Page *p = alloc_page();
c01031eb:	83 ec 0c             	sub    $0xc,%esp
c01031ee:	6a 01                	push   $0x1
c01031f0:	e8 aa fa ff ff       	call   c0102c9f <alloc_pages>
c01031f5:	83 c4 10             	add    $0x10,%esp
c01031f8:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (p == NULL) {
c01031fb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01031ff:	75 17                	jne    c0103218 <boot_alloc_page+0x33>
        panic("boot_alloc_page failed.\n");
c0103201:	83 ec 04             	sub    $0x4,%esp
c0103204:	68 6f 64 10 c0       	push   $0xc010646f
c0103209:	68 0c 01 00 00       	push   $0x10c
c010320e:	68 28 64 10 c0       	push   $0xc0106428
c0103213:	e8 cb d1 ff ff       	call   c01003e3 <__panic>
    }
    return page2kva(p);
c0103218:	83 ec 0c             	sub    $0xc,%esp
c010321b:	ff 75 f4             	pushl  -0xc(%ebp)
c010321e:	e8 d3 f7 ff ff       	call   c01029f6 <page2kva>
c0103223:	83 c4 10             	add    $0x10,%esp
}
c0103226:	c9                   	leave  
c0103227:	c3                   	ret    

c0103228 <pmm_init>:

//pmm_init - setup a pmm to manage physical memory, build PDT&PT to setup paging mechanism 
//         - check the correctness of pmm & paging mechanism, print PDT&PT
void
pmm_init(void) {
c0103228:	55                   	push   %ebp
c0103229:	89 e5                	mov    %esp,%ebp
c010322b:	83 ec 18             	sub    $0x18,%esp
    // We've already enabled paging
    boot_cr3 = PADDR(boot_pgdir);
c010322e:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103233:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0103236:	81 7d f4 ff ff ff bf 	cmpl   $0xbfffffff,-0xc(%ebp)
c010323d:	77 17                	ja     c0103256 <pmm_init+0x2e>
c010323f:	ff 75 f4             	pushl  -0xc(%ebp)
c0103242:	68 04 64 10 c0       	push   $0xc0106404
c0103247:	68 16 01 00 00       	push   $0x116
c010324c:	68 28 64 10 c0       	push   $0xc0106428
c0103251:	e8 8d d1 ff ff       	call   c01003e3 <__panic>
c0103256:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103259:	05 00 00 00 40       	add    $0x40000000,%eax
c010325e:	a3 14 af 11 c0       	mov    %eax,0xc011af14
    //We need to alloc/free the physical memory (granularity is 4KB or other size). 
    //So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    //First we should init a physical memory manager(pmm) based on the framework.
    //Then pmm can alloc/free the physical memory. 
    //Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();
c0103263:	e8 e3 f9 ff ff       	call   c0102c4b <init_pmm_manager>

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();
c0103268:	e8 d3 fa ff ff       	call   c0102d40 <page_init>

    //use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();
c010326d:	e8 90 03 00 00       	call   c0103602 <check_alloc_page>

    check_pgdir();
c0103272:	e8 ae 03 00 00       	call   c0103625 <check_pgdir>

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // recursively insert boot_pgdir in itself
    // to form a virtual page table at virtual address VPT
    boot_pgdir[PDX(VPT)] = PADDR(boot_pgdir) | PTE_P | PTE_W;
c0103277:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010327c:	8d 90 ac 0f 00 00    	lea    0xfac(%eax),%edx
c0103282:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103287:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010328a:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
c0103291:	77 17                	ja     c01032aa <pmm_init+0x82>
c0103293:	ff 75 f0             	pushl  -0x10(%ebp)
c0103296:	68 04 64 10 c0       	push   $0xc0106404
c010329b:	68 2c 01 00 00       	push   $0x12c
c01032a0:	68 28 64 10 c0       	push   $0xc0106428
c01032a5:	e8 39 d1 ff ff       	call   c01003e3 <__panic>
c01032aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01032ad:	05 00 00 00 40       	add    $0x40000000,%eax
c01032b2:	83 c8 03             	or     $0x3,%eax
c01032b5:	89 02                	mov    %eax,(%edx)

    // map all physical memory to linear memory with base linear addr KERNBASE
    // linear_addr KERNBASE ~ KERNBASE + KMEMSIZE = phy_addr 0 ~ KMEMSIZE
    boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, 0, PTE_W);
c01032b7:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01032bc:	83 ec 0c             	sub    $0xc,%esp
c01032bf:	6a 02                	push   $0x2
c01032c1:	6a 00                	push   $0x0
c01032c3:	68 00 00 00 38       	push   $0x38000000
c01032c8:	68 00 00 00 c0       	push   $0xc0000000
c01032cd:	50                   	push   %eax
c01032ce:	e8 29 fe ff ff       	call   c01030fc <boot_map_segment>
c01032d3:	83 c4 20             	add    $0x20,%esp

    // Since we are using bootloader's GDT,
    // we should reload gdt (second time, the last time) to get user segments and the TSS
    // map virtual_addr 0 ~ 4G = linear_addr 0 ~ 4G
    // then set kernel stack (ss:esp) in TSS, setup TSS in gdt, load TSS
    gdt_init();
c01032d6:	e8 7e f8 ff ff       	call   c0102b59 <gdt_init>

    //now the basic virtual memory map(see memalyout.h) is established.
    //check the correctness of the basic virtual memory map.
    check_boot_pgdir();
c01032db:	e8 ab 08 00 00       	call   c0103b8b <check_boot_pgdir>

    print_pgdir();
c01032e0:	e8 a1 0c 00 00       	call   c0103f86 <print_pgdir>

}
c01032e5:	90                   	nop
c01032e6:	c9                   	leave  
c01032e7:	c3                   	ret    

c01032e8 <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *
get_pte(pde_t *pgdir, uintptr_t la, bool create) {
c01032e8:	55                   	push   %ebp
c01032e9:	89 e5                	mov    %esp,%ebp
c01032eb:	83 ec 28             	sub    $0x28,%esp
    return NULL;          // (8) return page table entry
#endif

	 // PDX(la) 根据la的高10位获得对应的页目录项(一级页表中的某一项)索引(页目录项)
    // &pgdir[PDX(la)] 根据一级页表项索引从一级页表中找到对应的页目录项指针
    pde_t *pdep = &pgdir[PDX(la)];
c01032ee:	8b 45 0c             	mov    0xc(%ebp),%eax
c01032f1:	c1 e8 16             	shr    $0x16,%eax
c01032f4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c01032fb:	8b 45 08             	mov    0x8(%ebp),%eax
c01032fe:	01 d0                	add    %edx,%eax
c0103300:	89 45 f4             	mov    %eax,-0xc(%ebp)
    // 判断当前页目录项的Present存在位是否为1(对应的二级页表是否存在)
    if (!(*pdep & PTE_P)) {
c0103303:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103306:	8b 00                	mov    (%eax),%eax
c0103308:	83 e0 01             	and    $0x1,%eax
c010330b:	85 c0                	test   %eax,%eax
c010330d:	0f 85 9f 00 00 00    	jne    c01033b2 <get_pte+0xca>
        // 对应的二级页表不存在
        // *page指向的是这个新创建的二级页表基地址
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
c0103313:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0103317:	74 16                	je     c010332f <get_pte+0x47>
c0103319:	83 ec 0c             	sub    $0xc,%esp
c010331c:	6a 01                	push   $0x1
c010331e:	e8 7c f9 ff ff       	call   c0102c9f <alloc_pages>
c0103323:	83 c4 10             	add    $0x10,%esp
c0103326:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103329:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c010332d:	75 0a                	jne    c0103339 <get_pte+0x51>
             // 如果create参数为false或是alloc_page分配物理内存失败
            return NULL;
c010332f:	b8 00 00 00 00       	mov    $0x0,%eax
c0103334:	e9 ca 00 00 00       	jmp    c0103403 <get_pte+0x11b>
        }
        // 二级页表所对应的物理页 引用数为1
        set_page_ref(page, 1);
c0103339:	83 ec 08             	sub    $0x8,%esp
c010333c:	6a 01                	push   $0x1
c010333e:	ff 75 f0             	pushl  -0x10(%ebp)
c0103341:	e8 55 f7 ff ff       	call   c0102a9b <set_page_ref>
c0103346:	83 c4 10             	add    $0x10,%esp
        // 获得page变量的物理地址
        uintptr_t pa = page2pa(page);
c0103349:	83 ec 0c             	sub    $0xc,%esp
c010334c:	ff 75 f0             	pushl  -0x10(%ebp)
c010334f:	e8 48 f6 ff ff       	call   c010299c <page2pa>
c0103354:	83 c4 10             	add    $0x10,%esp
c0103357:	89 45 ec             	mov    %eax,-0x14(%ebp)
        // 将整个page所在的物理页格式胡，全部填满0
        memset(KADDR(pa), 0, PGSIZE);
c010335a:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010335d:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0103360:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103363:	c1 e8 0c             	shr    $0xc,%eax
c0103366:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0103369:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c010336e:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
c0103371:	72 17                	jb     c010338a <get_pte+0xa2>
c0103373:	ff 75 e8             	pushl  -0x18(%ebp)
c0103376:	68 60 63 10 c0       	push   $0xc0106360
c010337b:	68 7c 01 00 00       	push   $0x17c
c0103380:	68 28 64 10 c0       	push   $0xc0106428
c0103385:	e8 59 d0 ff ff       	call   c01003e3 <__panic>
c010338a:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010338d:	2d 00 00 00 40       	sub    $0x40000000,%eax
c0103392:	83 ec 04             	sub    $0x4,%esp
c0103395:	68 00 10 00 00       	push   $0x1000
c010339a:	6a 00                	push   $0x0
c010339c:	50                   	push   %eax
c010339d:	e8 b7 20 00 00       	call   c0105459 <memset>
c01033a2:	83 c4 10             	add    $0x10,%esp
        // la对应的一级页目录项进行赋值，使其指向新创建的二级页表(页表中的数据被MMU直接处理，为了映射效率存放的都是物理地址)
        // 或PTE_U/PTE_W/PET_P 标识当前页目录项是用户级别的、可写的、已存在的
        *pdep = pa | PTE_U | PTE_W | PTE_P;
c01033a5:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01033a8:	83 c8 07             	or     $0x7,%eax
c01033ab:	89 c2                	mov    %eax,%edx
c01033ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01033b0:	89 10                	mov    %edx,(%eax)
    }

    // 要想通过C语言中的数组来访问对应数据，需要的是数组基址(虚拟地址),而*pdep中页目录表项中存放了对应二级页表的一个物理地址
    // PDE_ADDR将*pdep的低12位抹零对齐(指向二级页表的起始基地址)，再通过KADDR转为内核虚拟地址，进行数组访问
    // PTX(la)获得la线性地址的中间10位部分，即二级页表中对应页表项的索引下标。这样便能得到la对应的二级页表项了
    return &((pte_t *)KADDR(PDE_ADDR(*pdep)))[PTX(la)];
c01033b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01033b5:	8b 00                	mov    (%eax),%eax
c01033b7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c01033bc:	89 45 e0             	mov    %eax,-0x20(%ebp)
c01033bf:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01033c2:	c1 e8 0c             	shr    $0xc,%eax
c01033c5:	89 45 dc             	mov    %eax,-0x24(%ebp)
c01033c8:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01033cd:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c01033d0:	72 17                	jb     c01033e9 <get_pte+0x101>
c01033d2:	ff 75 e0             	pushl  -0x20(%ebp)
c01033d5:	68 60 63 10 c0       	push   $0xc0106360
c01033da:	68 85 01 00 00       	push   $0x185
c01033df:	68 28 64 10 c0       	push   $0xc0106428
c01033e4:	e8 fa cf ff ff       	call   c01003e3 <__panic>
c01033e9:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01033ec:	2d 00 00 00 40       	sub    $0x40000000,%eax
c01033f1:	89 c2                	mov    %eax,%edx
c01033f3:	8b 45 0c             	mov    0xc(%ebp),%eax
c01033f6:	c1 e8 0c             	shr    $0xc,%eax
c01033f9:	25 ff 03 00 00       	and    $0x3ff,%eax
c01033fe:	c1 e0 02             	shl    $0x2,%eax
c0103401:	01 d0                	add    %edx,%eax
}
c0103403:	c9                   	leave  
c0103404:	c3                   	ret    

c0103405 <get_page>:

//get_page - get related Page struct for linear address la using PDT pgdir
struct Page *
get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
c0103405:	55                   	push   %ebp
c0103406:	89 e5                	mov    %esp,%ebp
c0103408:	83 ec 18             	sub    $0x18,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
c010340b:	83 ec 04             	sub    $0x4,%esp
c010340e:	6a 00                	push   $0x0
c0103410:	ff 75 0c             	pushl  0xc(%ebp)
c0103413:	ff 75 08             	pushl  0x8(%ebp)
c0103416:	e8 cd fe ff ff       	call   c01032e8 <get_pte>
c010341b:	83 c4 10             	add    $0x10,%esp
c010341e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep_store != NULL) {
c0103421:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0103425:	74 08                	je     c010342f <get_page+0x2a>
        *ptep_store = ptep;
c0103427:	8b 45 10             	mov    0x10(%ebp),%eax
c010342a:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010342d:	89 10                	mov    %edx,(%eax)
    }
    if (ptep != NULL && *ptep & PTE_P) {
c010342f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0103433:	74 1f                	je     c0103454 <get_page+0x4f>
c0103435:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103438:	8b 00                	mov    (%eax),%eax
c010343a:	83 e0 01             	and    $0x1,%eax
c010343d:	85 c0                	test   %eax,%eax
c010343f:	74 13                	je     c0103454 <get_page+0x4f>
        return pte2page(*ptep);
c0103441:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103444:	8b 00                	mov    (%eax),%eax
c0103446:	83 ec 0c             	sub    $0xc,%esp
c0103449:	50                   	push   %eax
c010344a:	e8 ec f5 ff ff       	call   c0102a3b <pte2page>
c010344f:	83 c4 10             	add    $0x10,%esp
c0103452:	eb 05                	jmp    c0103459 <get_page+0x54>
    }
    return NULL;
c0103454:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0103459:	c9                   	leave  
c010345a:	c3                   	ret    

c010345b <page_remove_pte>:

//page_remove_pte - free an Page sturct which is related linear address la
//                - and clean(invalidate) pte which is related linear address la
//note: PT is changed, so the TLB need to be invalidate 
static inline void
page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
c010345b:	55                   	push   %ebp
c010345c:	89 e5                	mov    %esp,%ebp
c010345e:	83 ec 18             	sub    $0x18,%esp
                                  //(5) clear second page table entry
                                  //(6) flush tlb
    }
	
#endif
	if (*ptep & PTE_P) {
c0103461:	8b 45 10             	mov    0x10(%ebp),%eax
c0103464:	8b 00                	mov    (%eax),%eax
c0103466:	83 e0 01             	and    $0x1,%eax
c0103469:	85 c0                	test   %eax,%eax
c010346b:	74 50                	je     c01034bd <page_remove_pte+0x62>
        // 如果对应的二级页表项存在
        // 获得*ptep对应的Page结构
        struct Page *page = pte2page(*ptep);
c010346d:	8b 45 10             	mov    0x10(%ebp),%eax
c0103470:	8b 00                	mov    (%eax),%eax
c0103472:	83 ec 0c             	sub    $0xc,%esp
c0103475:	50                   	push   %eax
c0103476:	e8 c0 f5 ff ff       	call   c0102a3b <pte2page>
c010347b:	83 c4 10             	add    $0x10,%esp
c010347e:	89 45 f4             	mov    %eax,-0xc(%ebp)
        // 关联的page引用数自减1
        if (page_ref_dec(page) == 0) {
c0103481:	83 ec 0c             	sub    $0xc,%esp
c0103484:	ff 75 f4             	pushl  -0xc(%ebp)
c0103487:	e8 34 f6 ff ff       	call   c0102ac0 <page_ref_dec>
c010348c:	83 c4 10             	add    $0x10,%esp
c010348f:	85 c0                	test   %eax,%eax
c0103491:	75 10                	jne    c01034a3 <page_remove_pte+0x48>
            // 如果自减1后，引用数为0，需要free释放掉该物理页
            free_page(page);
c0103493:	83 ec 08             	sub    $0x8,%esp
c0103496:	6a 01                	push   $0x1
c0103498:	ff 75 f4             	pushl  -0xc(%ebp)
c010349b:	e8 3d f8 ff ff       	call   c0102cdd <free_pages>
c01034a0:	83 c4 10             	add    $0x10,%esp
        }
        // 清空当前二级页表项(整体设置为0)
        *ptep = 0;
c01034a3:	8b 45 10             	mov    0x10(%ebp),%eax
c01034a6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        // 由于页表项发生了改变，需要TLB快表
        tlb_invalidate(pgdir, la);
c01034ac:	83 ec 08             	sub    $0x8,%esp
c01034af:	ff 75 0c             	pushl  0xc(%ebp)
c01034b2:	ff 75 08             	pushl  0x8(%ebp)
c01034b5:	e8 f8 00 00 00       	call   c01035b2 <tlb_invalidate>
c01034ba:	83 c4 10             	add    $0x10,%esp
    }
}
c01034bd:	90                   	nop
c01034be:	c9                   	leave  
c01034bf:	c3                   	ret    

c01034c0 <page_remove>:

//page_remove - free an Page which is related linear address la and has an validated pte
void
page_remove(pde_t *pgdir, uintptr_t la) {
c01034c0:	55                   	push   %ebp
c01034c1:	89 e5                	mov    %esp,%ebp
c01034c3:	83 ec 18             	sub    $0x18,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
c01034c6:	83 ec 04             	sub    $0x4,%esp
c01034c9:	6a 00                	push   $0x0
c01034cb:	ff 75 0c             	pushl  0xc(%ebp)
c01034ce:	ff 75 08             	pushl  0x8(%ebp)
c01034d1:	e8 12 fe ff ff       	call   c01032e8 <get_pte>
c01034d6:	83 c4 10             	add    $0x10,%esp
c01034d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep != NULL) {
c01034dc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01034e0:	74 14                	je     c01034f6 <page_remove+0x36>
        page_remove_pte(pgdir, la, ptep);//刷新指定页的TLB
c01034e2:	83 ec 04             	sub    $0x4,%esp
c01034e5:	ff 75 f4             	pushl  -0xc(%ebp)
c01034e8:	ff 75 0c             	pushl  0xc(%ebp)
c01034eb:	ff 75 08             	pushl  0x8(%ebp)
c01034ee:	e8 68 ff ff ff       	call   c010345b <page_remove_pte>
c01034f3:	83 c4 10             	add    $0x10,%esp
    }
}
c01034f6:	90                   	nop
c01034f7:	c9                   	leave  
c01034f8:	c3                   	ret    

c01034f9 <page_insert>:
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
//note: PT is changed, so the TLB need to be invalidate 
int
page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
c01034f9:	55                   	push   %ebp
c01034fa:	89 e5                	mov    %esp,%ebp
c01034fc:	83 ec 18             	sub    $0x18,%esp
    pte_t *ptep = get_pte(pgdir, la, 1);
c01034ff:	83 ec 04             	sub    $0x4,%esp
c0103502:	6a 01                	push   $0x1
c0103504:	ff 75 10             	pushl  0x10(%ebp)
c0103507:	ff 75 08             	pushl  0x8(%ebp)
c010350a:	e8 d9 fd ff ff       	call   c01032e8 <get_pte>
c010350f:	83 c4 10             	add    $0x10,%esp
c0103512:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep == NULL) {
c0103515:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0103519:	75 0a                	jne    c0103525 <page_insert+0x2c>
        return -E_NO_MEM;
c010351b:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
c0103520:	e9 8b 00 00 00       	jmp    c01035b0 <page_insert+0xb7>
    }
    page_ref_inc(page);
c0103525:	83 ec 0c             	sub    $0xc,%esp
c0103528:	ff 75 0c             	pushl  0xc(%ebp)
c010352b:	e8 79 f5 ff ff       	call   c0102aa9 <page_ref_inc>
c0103530:	83 c4 10             	add    $0x10,%esp
    if (*ptep & PTE_P) {
c0103533:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103536:	8b 00                	mov    (%eax),%eax
c0103538:	83 e0 01             	and    $0x1,%eax
c010353b:	85 c0                	test   %eax,%eax
c010353d:	74 40                	je     c010357f <page_insert+0x86>
        struct Page *p = pte2page(*ptep);
c010353f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103542:	8b 00                	mov    (%eax),%eax
c0103544:	83 ec 0c             	sub    $0xc,%esp
c0103547:	50                   	push   %eax
c0103548:	e8 ee f4 ff ff       	call   c0102a3b <pte2page>
c010354d:	83 c4 10             	add    $0x10,%esp
c0103550:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (p == page) {
c0103553:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103556:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103559:	75 10                	jne    c010356b <page_insert+0x72>
            page_ref_dec(page);
c010355b:	83 ec 0c             	sub    $0xc,%esp
c010355e:	ff 75 0c             	pushl  0xc(%ebp)
c0103561:	e8 5a f5 ff ff       	call   c0102ac0 <page_ref_dec>
c0103566:	83 c4 10             	add    $0x10,%esp
c0103569:	eb 14                	jmp    c010357f <page_insert+0x86>
        }
        else {
            page_remove_pte(pgdir, la, ptep);
c010356b:	83 ec 04             	sub    $0x4,%esp
c010356e:	ff 75 f4             	pushl  -0xc(%ebp)
c0103571:	ff 75 10             	pushl  0x10(%ebp)
c0103574:	ff 75 08             	pushl  0x8(%ebp)
c0103577:	e8 df fe ff ff       	call   c010345b <page_remove_pte>
c010357c:	83 c4 10             	add    $0x10,%esp
        }
    }
    *ptep = page2pa(page) | PTE_P | perm;
c010357f:	83 ec 0c             	sub    $0xc,%esp
c0103582:	ff 75 0c             	pushl  0xc(%ebp)
c0103585:	e8 12 f4 ff ff       	call   c010299c <page2pa>
c010358a:	83 c4 10             	add    $0x10,%esp
c010358d:	0b 45 14             	or     0x14(%ebp),%eax
c0103590:	83 c8 01             	or     $0x1,%eax
c0103593:	89 c2                	mov    %eax,%edx
c0103595:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103598:	89 10                	mov    %edx,(%eax)
    tlb_invalidate(pgdir, la);
c010359a:	83 ec 08             	sub    $0x8,%esp
c010359d:	ff 75 10             	pushl  0x10(%ebp)
c01035a0:	ff 75 08             	pushl  0x8(%ebp)
c01035a3:	e8 0a 00 00 00       	call   c01035b2 <tlb_invalidate>
c01035a8:	83 c4 10             	add    $0x10,%esp
    return 0;
c01035ab:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01035b0:	c9                   	leave  
c01035b1:	c3                   	ret    

c01035b2 <tlb_invalidate>:

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void
tlb_invalidate(pde_t *pgdir, uintptr_t la) {
c01035b2:	55                   	push   %ebp
c01035b3:	89 e5                	mov    %esp,%ebp
c01035b5:	83 ec 18             	sub    $0x18,%esp
}

static inline uintptr_t
rcr3(void) {
    uintptr_t cr3;
    asm volatile ("mov %%cr3, %0" : "=r" (cr3) :: "memory");
c01035b8:	0f 20 d8             	mov    %cr3,%eax
c01035bb:	89 45 ec             	mov    %eax,-0x14(%ebp)
    return cr3;
c01035be:	8b 55 ec             	mov    -0x14(%ebp),%edx
    if (rcr3() == PADDR(pgdir)) {
c01035c1:	8b 45 08             	mov    0x8(%ebp),%eax
c01035c4:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01035c7:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
c01035ce:	77 17                	ja     c01035e7 <tlb_invalidate+0x35>
c01035d0:	ff 75 f0             	pushl  -0x10(%ebp)
c01035d3:	68 04 64 10 c0       	push   $0xc0106404
c01035d8:	68 ee 01 00 00       	push   $0x1ee
c01035dd:	68 28 64 10 c0       	push   $0xc0106428
c01035e2:	e8 fc cd ff ff       	call   c01003e3 <__panic>
c01035e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01035ea:	05 00 00 00 40       	add    $0x40000000,%eax
c01035ef:	39 c2                	cmp    %eax,%edx
c01035f1:	75 0c                	jne    c01035ff <tlb_invalidate+0x4d>
        invlpg((void *)la);
c01035f3:	8b 45 0c             	mov    0xc(%ebp),%eax
c01035f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static inline void
invlpg(void *addr) {
    asm volatile ("invlpg (%0)" :: "r" (addr) : "memory");
c01035f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01035fc:	0f 01 38             	invlpg (%eax)
    }
}
c01035ff:	90                   	nop
c0103600:	c9                   	leave  
c0103601:	c3                   	ret    

c0103602 <check_alloc_page>:

static void
check_alloc_page(void) {
c0103602:	55                   	push   %ebp
c0103603:	89 e5                	mov    %esp,%ebp
c0103605:	83 ec 08             	sub    $0x8,%esp
    pmm_manager->check();
c0103608:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c010360d:	8b 40 18             	mov    0x18(%eax),%eax
c0103610:	ff d0                	call   *%eax
    cprintf("check_alloc_page() succeeded!\n");
c0103612:	83 ec 0c             	sub    $0xc,%esp
c0103615:	68 88 64 10 c0       	push   $0xc0106488
c010361a:	e8 5e cc ff ff       	call   c010027d <cprintf>
c010361f:	83 c4 10             	add    $0x10,%esp
}
c0103622:	90                   	nop
c0103623:	c9                   	leave  
c0103624:	c3                   	ret    

c0103625 <check_pgdir>:

static void
check_pgdir(void) {
c0103625:	55                   	push   %ebp
c0103626:	89 e5                	mov    %esp,%ebp
c0103628:	83 ec 28             	sub    $0x28,%esp
    assert(npage <= KMEMSIZE / PGSIZE);//总页数检查
c010362b:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0103630:	3d 00 80 03 00       	cmp    $0x38000,%eax
c0103635:	76 19                	jbe    c0103650 <check_pgdir+0x2b>
c0103637:	68 a7 64 10 c0       	push   $0xc01064a7
c010363c:	68 4d 64 10 c0       	push   $0xc010644d
c0103641:	68 fb 01 00 00       	push   $0x1fb
c0103646:	68 28 64 10 c0       	push   $0xc0106428
c010364b:	e8 93 cd ff ff       	call   c01003e3 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);//页目录的地址应该就是页首
c0103650:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103655:	85 c0                	test   %eax,%eax
c0103657:	74 0e                	je     c0103667 <check_pgdir+0x42>
c0103659:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010365e:	25 ff 0f 00 00       	and    $0xfff,%eax
c0103663:	85 c0                	test   %eax,%eax
c0103665:	74 19                	je     c0103680 <check_pgdir+0x5b>
c0103667:	68 c4 64 10 c0       	push   $0xc01064c4
c010366c:	68 4d 64 10 c0       	push   $0xc010644d
c0103671:	68 fc 01 00 00       	push   $0x1fc
c0103676:	68 28 64 10 c0       	push   $0xc0106428
c010367b:	e8 63 cd ff ff       	call   c01003e3 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
c0103680:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103685:	83 ec 04             	sub    $0x4,%esp
c0103688:	6a 00                	push   $0x0
c010368a:	6a 00                	push   $0x0
c010368c:	50                   	push   %eax
c010368d:	e8 73 fd ff ff       	call   c0103405 <get_page>
c0103692:	83 c4 10             	add    $0x10,%esp
c0103695:	85 c0                	test   %eax,%eax
c0103697:	74 19                	je     c01036b2 <check_pgdir+0x8d>
c0103699:	68 fc 64 10 c0       	push   $0xc01064fc
c010369e:	68 4d 64 10 c0       	push   $0xc010644d
c01036a3:	68 fd 01 00 00       	push   $0x1fd
c01036a8:	68 28 64 10 c0       	push   $0xc0106428
c01036ad:	e8 31 cd ff ff       	call   c01003e3 <__panic>

    struct Page *p1, *p2;
    p1 = alloc_page();
c01036b2:	83 ec 0c             	sub    $0xc,%esp
c01036b5:	6a 01                	push   $0x1
c01036b7:	e8 e3 f5 ff ff       	call   c0102c9f <alloc_pages>
c01036bc:	83 c4 10             	add    $0x10,%esp
c01036bf:	89 45 f4             	mov    %eax,-0xc(%ebp)
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
c01036c2:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01036c7:	6a 00                	push   $0x0
c01036c9:	6a 00                	push   $0x0
c01036cb:	ff 75 f4             	pushl  -0xc(%ebp)
c01036ce:	50                   	push   %eax
c01036cf:	e8 25 fe ff ff       	call   c01034f9 <page_insert>
c01036d4:	83 c4 10             	add    $0x10,%esp
c01036d7:	85 c0                	test   %eax,%eax
c01036d9:	74 19                	je     c01036f4 <check_pgdir+0xcf>
c01036db:	68 24 65 10 c0       	push   $0xc0106524
c01036e0:	68 4d 64 10 c0       	push   $0xc010644d
c01036e5:	68 01 02 00 00       	push   $0x201
c01036ea:	68 28 64 10 c0       	push   $0xc0106428
c01036ef:	e8 ef cc ff ff       	call   c01003e3 <__panic>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
c01036f4:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01036f9:	83 ec 04             	sub    $0x4,%esp
c01036fc:	6a 00                	push   $0x0
c01036fe:	6a 00                	push   $0x0
c0103700:	50                   	push   %eax
c0103701:	e8 e2 fb ff ff       	call   c01032e8 <get_pte>
c0103706:	83 c4 10             	add    $0x10,%esp
c0103709:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010370c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0103710:	75 19                	jne    c010372b <check_pgdir+0x106>
c0103712:	68 50 65 10 c0       	push   $0xc0106550
c0103717:	68 4d 64 10 c0       	push   $0xc010644d
c010371c:	68 04 02 00 00       	push   $0x204
c0103721:	68 28 64 10 c0       	push   $0xc0106428
c0103726:	e8 b8 cc ff ff       	call   c01003e3 <__panic>
    assert(pte2page(*ptep) == p1);
c010372b:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010372e:	8b 00                	mov    (%eax),%eax
c0103730:	83 ec 0c             	sub    $0xc,%esp
c0103733:	50                   	push   %eax
c0103734:	e8 02 f3 ff ff       	call   c0102a3b <pte2page>
c0103739:	83 c4 10             	add    $0x10,%esp
c010373c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c010373f:	74 19                	je     c010375a <check_pgdir+0x135>
c0103741:	68 7d 65 10 c0       	push   $0xc010657d
c0103746:	68 4d 64 10 c0       	push   $0xc010644d
c010374b:	68 05 02 00 00       	push   $0x205
c0103750:	68 28 64 10 c0       	push   $0xc0106428
c0103755:	e8 89 cc ff ff       	call   c01003e3 <__panic>
    assert(page_ref(p1) == 1);
c010375a:	83 ec 0c             	sub    $0xc,%esp
c010375d:	ff 75 f4             	pushl  -0xc(%ebp)
c0103760:	e8 2c f3 ff ff       	call   c0102a91 <page_ref>
c0103765:	83 c4 10             	add    $0x10,%esp
c0103768:	83 f8 01             	cmp    $0x1,%eax
c010376b:	74 19                	je     c0103786 <check_pgdir+0x161>
c010376d:	68 93 65 10 c0       	push   $0xc0106593
c0103772:	68 4d 64 10 c0       	push   $0xc010644d
c0103777:	68 06 02 00 00       	push   $0x206
c010377c:	68 28 64 10 c0       	push   $0xc0106428
c0103781:	e8 5d cc ff ff       	call   c01003e3 <__panic>

    ptep = &((pte_t *)KADDR(PDE_ADDR(boot_pgdir[0])))[1];
c0103786:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010378b:	8b 00                	mov    (%eax),%eax
c010378d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103792:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0103795:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103798:	c1 e8 0c             	shr    $0xc,%eax
c010379b:	89 45 e8             	mov    %eax,-0x18(%ebp)
c010379e:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01037a3:	39 45 e8             	cmp    %eax,-0x18(%ebp)
c01037a6:	72 17                	jb     c01037bf <check_pgdir+0x19a>
c01037a8:	ff 75 ec             	pushl  -0x14(%ebp)
c01037ab:	68 60 63 10 c0       	push   $0xc0106360
c01037b0:	68 08 02 00 00       	push   $0x208
c01037b5:	68 28 64 10 c0       	push   $0xc0106428
c01037ba:	e8 24 cc ff ff       	call   c01003e3 <__panic>
c01037bf:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01037c2:	2d 00 00 00 40       	sub    $0x40000000,%eax
c01037c7:	83 c0 04             	add    $0x4,%eax
c01037ca:	89 45 f0             	mov    %eax,-0x10(%ebp)
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
c01037cd:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01037d2:	83 ec 04             	sub    $0x4,%esp
c01037d5:	6a 00                	push   $0x0
c01037d7:	68 00 10 00 00       	push   $0x1000
c01037dc:	50                   	push   %eax
c01037dd:	e8 06 fb ff ff       	call   c01032e8 <get_pte>
c01037e2:	83 c4 10             	add    $0x10,%esp
c01037e5:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c01037e8:	74 19                	je     c0103803 <check_pgdir+0x1de>
c01037ea:	68 a8 65 10 c0       	push   $0xc01065a8
c01037ef:	68 4d 64 10 c0       	push   $0xc010644d
c01037f4:	68 09 02 00 00       	push   $0x209
c01037f9:	68 28 64 10 c0       	push   $0xc0106428
c01037fe:	e8 e0 cb ff ff       	call   c01003e3 <__panic>

    p2 = alloc_page();
c0103803:	83 ec 0c             	sub    $0xc,%esp
c0103806:	6a 01                	push   $0x1
c0103808:	e8 92 f4 ff ff       	call   c0102c9f <alloc_pages>
c010380d:	83 c4 10             	add    $0x10,%esp
c0103810:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
c0103813:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103818:	6a 06                	push   $0x6
c010381a:	68 00 10 00 00       	push   $0x1000
c010381f:	ff 75 e4             	pushl  -0x1c(%ebp)
c0103822:	50                   	push   %eax
c0103823:	e8 d1 fc ff ff       	call   c01034f9 <page_insert>
c0103828:	83 c4 10             	add    $0x10,%esp
c010382b:	85 c0                	test   %eax,%eax
c010382d:	74 19                	je     c0103848 <check_pgdir+0x223>
c010382f:	68 d0 65 10 c0       	push   $0xc01065d0
c0103834:	68 4d 64 10 c0       	push   $0xc010644d
c0103839:	68 0c 02 00 00       	push   $0x20c
c010383e:	68 28 64 10 c0       	push   $0xc0106428
c0103843:	e8 9b cb ff ff       	call   c01003e3 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
c0103848:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010384d:	83 ec 04             	sub    $0x4,%esp
c0103850:	6a 00                	push   $0x0
c0103852:	68 00 10 00 00       	push   $0x1000
c0103857:	50                   	push   %eax
c0103858:	e8 8b fa ff ff       	call   c01032e8 <get_pte>
c010385d:	83 c4 10             	add    $0x10,%esp
c0103860:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103863:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0103867:	75 19                	jne    c0103882 <check_pgdir+0x25d>
c0103869:	68 08 66 10 c0       	push   $0xc0106608
c010386e:	68 4d 64 10 c0       	push   $0xc010644d
c0103873:	68 0d 02 00 00       	push   $0x20d
c0103878:	68 28 64 10 c0       	push   $0xc0106428
c010387d:	e8 61 cb ff ff       	call   c01003e3 <__panic>
    assert(*ptep & PTE_U);
c0103882:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103885:	8b 00                	mov    (%eax),%eax
c0103887:	83 e0 04             	and    $0x4,%eax
c010388a:	85 c0                	test   %eax,%eax
c010388c:	75 19                	jne    c01038a7 <check_pgdir+0x282>
c010388e:	68 38 66 10 c0       	push   $0xc0106638
c0103893:	68 4d 64 10 c0       	push   $0xc010644d
c0103898:	68 0e 02 00 00       	push   $0x20e
c010389d:	68 28 64 10 c0       	push   $0xc0106428
c01038a2:	e8 3c cb ff ff       	call   c01003e3 <__panic>
    assert(*ptep & PTE_W);
c01038a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01038aa:	8b 00                	mov    (%eax),%eax
c01038ac:	83 e0 02             	and    $0x2,%eax
c01038af:	85 c0                	test   %eax,%eax
c01038b1:	75 19                	jne    c01038cc <check_pgdir+0x2a7>
c01038b3:	68 46 66 10 c0       	push   $0xc0106646
c01038b8:	68 4d 64 10 c0       	push   $0xc010644d
c01038bd:	68 0f 02 00 00       	push   $0x20f
c01038c2:	68 28 64 10 c0       	push   $0xc0106428
c01038c7:	e8 17 cb ff ff       	call   c01003e3 <__panic>
    assert(boot_pgdir[0] & PTE_U);
c01038cc:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01038d1:	8b 00                	mov    (%eax),%eax
c01038d3:	83 e0 04             	and    $0x4,%eax
c01038d6:	85 c0                	test   %eax,%eax
c01038d8:	75 19                	jne    c01038f3 <check_pgdir+0x2ce>
c01038da:	68 54 66 10 c0       	push   $0xc0106654
c01038df:	68 4d 64 10 c0       	push   $0xc010644d
c01038e4:	68 10 02 00 00       	push   $0x210
c01038e9:	68 28 64 10 c0       	push   $0xc0106428
c01038ee:	e8 f0 ca ff ff       	call   c01003e3 <__panic>
    assert(page_ref(p2) == 1);
c01038f3:	83 ec 0c             	sub    $0xc,%esp
c01038f6:	ff 75 e4             	pushl  -0x1c(%ebp)
c01038f9:	e8 93 f1 ff ff       	call   c0102a91 <page_ref>
c01038fe:	83 c4 10             	add    $0x10,%esp
c0103901:	83 f8 01             	cmp    $0x1,%eax
c0103904:	74 19                	je     c010391f <check_pgdir+0x2fa>
c0103906:	68 6a 66 10 c0       	push   $0xc010666a
c010390b:	68 4d 64 10 c0       	push   $0xc010644d
c0103910:	68 11 02 00 00       	push   $0x211
c0103915:	68 28 64 10 c0       	push   $0xc0106428
c010391a:	e8 c4 ca ff ff       	call   c01003e3 <__panic>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
c010391f:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103924:	6a 00                	push   $0x0
c0103926:	68 00 10 00 00       	push   $0x1000
c010392b:	ff 75 f4             	pushl  -0xc(%ebp)
c010392e:	50                   	push   %eax
c010392f:	e8 c5 fb ff ff       	call   c01034f9 <page_insert>
c0103934:	83 c4 10             	add    $0x10,%esp
c0103937:	85 c0                	test   %eax,%eax
c0103939:	74 19                	je     c0103954 <check_pgdir+0x32f>
c010393b:	68 7c 66 10 c0       	push   $0xc010667c
c0103940:	68 4d 64 10 c0       	push   $0xc010644d
c0103945:	68 13 02 00 00       	push   $0x213
c010394a:	68 28 64 10 c0       	push   $0xc0106428
c010394f:	e8 8f ca ff ff       	call   c01003e3 <__panic>
    assert(page_ref(p1) == 2);
c0103954:	83 ec 0c             	sub    $0xc,%esp
c0103957:	ff 75 f4             	pushl  -0xc(%ebp)
c010395a:	e8 32 f1 ff ff       	call   c0102a91 <page_ref>
c010395f:	83 c4 10             	add    $0x10,%esp
c0103962:	83 f8 02             	cmp    $0x2,%eax
c0103965:	74 19                	je     c0103980 <check_pgdir+0x35b>
c0103967:	68 a8 66 10 c0       	push   $0xc01066a8
c010396c:	68 4d 64 10 c0       	push   $0xc010644d
c0103971:	68 14 02 00 00       	push   $0x214
c0103976:	68 28 64 10 c0       	push   $0xc0106428
c010397b:	e8 63 ca ff ff       	call   c01003e3 <__panic>
    assert(page_ref(p2) == 0);
c0103980:	83 ec 0c             	sub    $0xc,%esp
c0103983:	ff 75 e4             	pushl  -0x1c(%ebp)
c0103986:	e8 06 f1 ff ff       	call   c0102a91 <page_ref>
c010398b:	83 c4 10             	add    $0x10,%esp
c010398e:	85 c0                	test   %eax,%eax
c0103990:	74 19                	je     c01039ab <check_pgdir+0x386>
c0103992:	68 ba 66 10 c0       	push   $0xc01066ba
c0103997:	68 4d 64 10 c0       	push   $0xc010644d
c010399c:	68 15 02 00 00       	push   $0x215
c01039a1:	68 28 64 10 c0       	push   $0xc0106428
c01039a6:	e8 38 ca ff ff       	call   c01003e3 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
c01039ab:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01039b0:	83 ec 04             	sub    $0x4,%esp
c01039b3:	6a 00                	push   $0x0
c01039b5:	68 00 10 00 00       	push   $0x1000
c01039ba:	50                   	push   %eax
c01039bb:	e8 28 f9 ff ff       	call   c01032e8 <get_pte>
c01039c0:	83 c4 10             	add    $0x10,%esp
c01039c3:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01039c6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c01039ca:	75 19                	jne    c01039e5 <check_pgdir+0x3c0>
c01039cc:	68 08 66 10 c0       	push   $0xc0106608
c01039d1:	68 4d 64 10 c0       	push   $0xc010644d
c01039d6:	68 16 02 00 00       	push   $0x216
c01039db:	68 28 64 10 c0       	push   $0xc0106428
c01039e0:	e8 fe c9 ff ff       	call   c01003e3 <__panic>
    assert(pte2page(*ptep) == p1);
c01039e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01039e8:	8b 00                	mov    (%eax),%eax
c01039ea:	83 ec 0c             	sub    $0xc,%esp
c01039ed:	50                   	push   %eax
c01039ee:	e8 48 f0 ff ff       	call   c0102a3b <pte2page>
c01039f3:	83 c4 10             	add    $0x10,%esp
c01039f6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01039f9:	74 19                	je     c0103a14 <check_pgdir+0x3ef>
c01039fb:	68 7d 65 10 c0       	push   $0xc010657d
c0103a00:	68 4d 64 10 c0       	push   $0xc010644d
c0103a05:	68 17 02 00 00       	push   $0x217
c0103a0a:	68 28 64 10 c0       	push   $0xc0106428
c0103a0f:	e8 cf c9 ff ff       	call   c01003e3 <__panic>
    assert((*ptep & PTE_U) == 0);
c0103a14:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103a17:	8b 00                	mov    (%eax),%eax
c0103a19:	83 e0 04             	and    $0x4,%eax
c0103a1c:	85 c0                	test   %eax,%eax
c0103a1e:	74 19                	je     c0103a39 <check_pgdir+0x414>
c0103a20:	68 cc 66 10 c0       	push   $0xc01066cc
c0103a25:	68 4d 64 10 c0       	push   $0xc010644d
c0103a2a:	68 18 02 00 00       	push   $0x218
c0103a2f:	68 28 64 10 c0       	push   $0xc0106428
c0103a34:	e8 aa c9 ff ff       	call   c01003e3 <__panic>

    page_remove(boot_pgdir, 0x0);
c0103a39:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103a3e:	83 ec 08             	sub    $0x8,%esp
c0103a41:	6a 00                	push   $0x0
c0103a43:	50                   	push   %eax
c0103a44:	e8 77 fa ff ff       	call   c01034c0 <page_remove>
c0103a49:	83 c4 10             	add    $0x10,%esp
    assert(page_ref(p1) == 1);
c0103a4c:	83 ec 0c             	sub    $0xc,%esp
c0103a4f:	ff 75 f4             	pushl  -0xc(%ebp)
c0103a52:	e8 3a f0 ff ff       	call   c0102a91 <page_ref>
c0103a57:	83 c4 10             	add    $0x10,%esp
c0103a5a:	83 f8 01             	cmp    $0x1,%eax
c0103a5d:	74 19                	je     c0103a78 <check_pgdir+0x453>
c0103a5f:	68 93 65 10 c0       	push   $0xc0106593
c0103a64:	68 4d 64 10 c0       	push   $0xc010644d
c0103a69:	68 1b 02 00 00       	push   $0x21b
c0103a6e:	68 28 64 10 c0       	push   $0xc0106428
c0103a73:	e8 6b c9 ff ff       	call   c01003e3 <__panic>
    assert(page_ref(p2) == 0);
c0103a78:	83 ec 0c             	sub    $0xc,%esp
c0103a7b:	ff 75 e4             	pushl  -0x1c(%ebp)
c0103a7e:	e8 0e f0 ff ff       	call   c0102a91 <page_ref>
c0103a83:	83 c4 10             	add    $0x10,%esp
c0103a86:	85 c0                	test   %eax,%eax
c0103a88:	74 19                	je     c0103aa3 <check_pgdir+0x47e>
c0103a8a:	68 ba 66 10 c0       	push   $0xc01066ba
c0103a8f:	68 4d 64 10 c0       	push   $0xc010644d
c0103a94:	68 1c 02 00 00       	push   $0x21c
c0103a99:	68 28 64 10 c0       	push   $0xc0106428
c0103a9e:	e8 40 c9 ff ff       	call   c01003e3 <__panic>

    page_remove(boot_pgdir, PGSIZE);
c0103aa3:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103aa8:	83 ec 08             	sub    $0x8,%esp
c0103aab:	68 00 10 00 00       	push   $0x1000
c0103ab0:	50                   	push   %eax
c0103ab1:	e8 0a fa ff ff       	call   c01034c0 <page_remove>
c0103ab6:	83 c4 10             	add    $0x10,%esp
    assert(page_ref(p1) == 0);
c0103ab9:	83 ec 0c             	sub    $0xc,%esp
c0103abc:	ff 75 f4             	pushl  -0xc(%ebp)
c0103abf:	e8 cd ef ff ff       	call   c0102a91 <page_ref>
c0103ac4:	83 c4 10             	add    $0x10,%esp
c0103ac7:	85 c0                	test   %eax,%eax
c0103ac9:	74 19                	je     c0103ae4 <check_pgdir+0x4bf>
c0103acb:	68 e1 66 10 c0       	push   $0xc01066e1
c0103ad0:	68 4d 64 10 c0       	push   $0xc010644d
c0103ad5:	68 1f 02 00 00       	push   $0x21f
c0103ada:	68 28 64 10 c0       	push   $0xc0106428
c0103adf:	e8 ff c8 ff ff       	call   c01003e3 <__panic>
    assert(page_ref(p2) == 0);
c0103ae4:	83 ec 0c             	sub    $0xc,%esp
c0103ae7:	ff 75 e4             	pushl  -0x1c(%ebp)
c0103aea:	e8 a2 ef ff ff       	call   c0102a91 <page_ref>
c0103aef:	83 c4 10             	add    $0x10,%esp
c0103af2:	85 c0                	test   %eax,%eax
c0103af4:	74 19                	je     c0103b0f <check_pgdir+0x4ea>
c0103af6:	68 ba 66 10 c0       	push   $0xc01066ba
c0103afb:	68 4d 64 10 c0       	push   $0xc010644d
c0103b00:	68 20 02 00 00       	push   $0x220
c0103b05:	68 28 64 10 c0       	push   $0xc0106428
c0103b0a:	e8 d4 c8 ff ff       	call   c01003e3 <__panic>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
c0103b0f:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103b14:	8b 00                	mov    (%eax),%eax
c0103b16:	83 ec 0c             	sub    $0xc,%esp
c0103b19:	50                   	push   %eax
c0103b1a:	e8 56 ef ff ff       	call   c0102a75 <pde2page>
c0103b1f:	83 c4 10             	add    $0x10,%esp
c0103b22:	83 ec 0c             	sub    $0xc,%esp
c0103b25:	50                   	push   %eax
c0103b26:	e8 66 ef ff ff       	call   c0102a91 <page_ref>
c0103b2b:	83 c4 10             	add    $0x10,%esp
c0103b2e:	83 f8 01             	cmp    $0x1,%eax
c0103b31:	74 19                	je     c0103b4c <check_pgdir+0x527>
c0103b33:	68 f4 66 10 c0       	push   $0xc01066f4
c0103b38:	68 4d 64 10 c0       	push   $0xc010644d
c0103b3d:	68 22 02 00 00       	push   $0x222
c0103b42:	68 28 64 10 c0       	push   $0xc0106428
c0103b47:	e8 97 c8 ff ff       	call   c01003e3 <__panic>
    free_page(pde2page(boot_pgdir[0]));
c0103b4c:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103b51:	8b 00                	mov    (%eax),%eax
c0103b53:	83 ec 0c             	sub    $0xc,%esp
c0103b56:	50                   	push   %eax
c0103b57:	e8 19 ef ff ff       	call   c0102a75 <pde2page>
c0103b5c:	83 c4 10             	add    $0x10,%esp
c0103b5f:	83 ec 08             	sub    $0x8,%esp
c0103b62:	6a 01                	push   $0x1
c0103b64:	50                   	push   %eax
c0103b65:	e8 73 f1 ff ff       	call   c0102cdd <free_pages>
c0103b6a:	83 c4 10             	add    $0x10,%esp
    boot_pgdir[0] = 0;
c0103b6d:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103b72:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_pgdir() succeeded!\n");
c0103b78:	83 ec 0c             	sub    $0xc,%esp
c0103b7b:	68 1b 67 10 c0       	push   $0xc010671b
c0103b80:	e8 f8 c6 ff ff       	call   c010027d <cprintf>
c0103b85:	83 c4 10             	add    $0x10,%esp
}
c0103b88:	90                   	nop
c0103b89:	c9                   	leave  
c0103b8a:	c3                   	ret    

c0103b8b <check_boot_pgdir>:

static void
check_boot_pgdir(void) {
c0103b8b:	55                   	push   %ebp
c0103b8c:	89 e5                	mov    %esp,%ebp
c0103b8e:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
c0103b91:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0103b98:	e9 a3 00 00 00       	jmp    c0103c40 <check_boot_pgdir+0xb5>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
c0103b9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103ba0:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103ba3:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103ba6:	c1 e8 0c             	shr    $0xc,%eax
c0103ba9:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0103bac:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0103bb1:	39 45 ec             	cmp    %eax,-0x14(%ebp)
c0103bb4:	72 17                	jb     c0103bcd <check_boot_pgdir+0x42>
c0103bb6:	ff 75 f0             	pushl  -0x10(%ebp)
c0103bb9:	68 60 63 10 c0       	push   $0xc0106360
c0103bbe:	68 2e 02 00 00       	push   $0x22e
c0103bc3:	68 28 64 10 c0       	push   $0xc0106428
c0103bc8:	e8 16 c8 ff ff       	call   c01003e3 <__panic>
c0103bcd:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103bd0:	2d 00 00 00 40       	sub    $0x40000000,%eax
c0103bd5:	89 c2                	mov    %eax,%edx
c0103bd7:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103bdc:	83 ec 04             	sub    $0x4,%esp
c0103bdf:	6a 00                	push   $0x0
c0103be1:	52                   	push   %edx
c0103be2:	50                   	push   %eax
c0103be3:	e8 00 f7 ff ff       	call   c01032e8 <get_pte>
c0103be8:	83 c4 10             	add    $0x10,%esp
c0103beb:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0103bee:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0103bf2:	75 19                	jne    c0103c0d <check_boot_pgdir+0x82>
c0103bf4:	68 38 67 10 c0       	push   $0xc0106738
c0103bf9:	68 4d 64 10 c0       	push   $0xc010644d
c0103bfe:	68 2e 02 00 00       	push   $0x22e
c0103c03:	68 28 64 10 c0       	push   $0xc0106428
c0103c08:	e8 d6 c7 ff ff       	call   c01003e3 <__panic>
        assert(PTE_ADDR(*ptep) == i);
c0103c0d:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103c10:	8b 00                	mov    (%eax),%eax
c0103c12:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103c17:	89 c2                	mov    %eax,%edx
c0103c19:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103c1c:	39 c2                	cmp    %eax,%edx
c0103c1e:	74 19                	je     c0103c39 <check_boot_pgdir+0xae>
c0103c20:	68 75 67 10 c0       	push   $0xc0106775
c0103c25:	68 4d 64 10 c0       	push   $0xc010644d
c0103c2a:	68 2f 02 00 00       	push   $0x22f
c0103c2f:	68 28 64 10 c0       	push   $0xc0106428
c0103c34:	e8 aa c7 ff ff       	call   c01003e3 <__panic>

static void
check_boot_pgdir(void) {
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
c0103c39:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
c0103c40:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0103c43:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0103c48:	39 c2                	cmp    %eax,%edx
c0103c4a:	0f 82 4d ff ff ff    	jb     c0103b9d <check_boot_pgdir+0x12>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
    }

    assert(PDE_ADDR(boot_pgdir[PDX(VPT)]) == PADDR(boot_pgdir));
c0103c50:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103c55:	05 ac 0f 00 00       	add    $0xfac,%eax
c0103c5a:	8b 00                	mov    (%eax),%eax
c0103c5c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103c61:	89 c2                	mov    %eax,%edx
c0103c63:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103c68:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0103c6b:	81 7d e4 ff ff ff bf 	cmpl   $0xbfffffff,-0x1c(%ebp)
c0103c72:	77 17                	ja     c0103c8b <check_boot_pgdir+0x100>
c0103c74:	ff 75 e4             	pushl  -0x1c(%ebp)
c0103c77:	68 04 64 10 c0       	push   $0xc0106404
c0103c7c:	68 32 02 00 00       	push   $0x232
c0103c81:	68 28 64 10 c0       	push   $0xc0106428
c0103c86:	e8 58 c7 ff ff       	call   c01003e3 <__panic>
c0103c8b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103c8e:	05 00 00 00 40       	add    $0x40000000,%eax
c0103c93:	39 c2                	cmp    %eax,%edx
c0103c95:	74 19                	je     c0103cb0 <check_boot_pgdir+0x125>
c0103c97:	68 8c 67 10 c0       	push   $0xc010678c
c0103c9c:	68 4d 64 10 c0       	push   $0xc010644d
c0103ca1:	68 32 02 00 00       	push   $0x232
c0103ca6:	68 28 64 10 c0       	push   $0xc0106428
c0103cab:	e8 33 c7 ff ff       	call   c01003e3 <__panic>

    assert(boot_pgdir[0] == 0);
c0103cb0:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103cb5:	8b 00                	mov    (%eax),%eax
c0103cb7:	85 c0                	test   %eax,%eax
c0103cb9:	74 19                	je     c0103cd4 <check_boot_pgdir+0x149>
c0103cbb:	68 c0 67 10 c0       	push   $0xc01067c0
c0103cc0:	68 4d 64 10 c0       	push   $0xc010644d
c0103cc5:	68 34 02 00 00       	push   $0x234
c0103cca:	68 28 64 10 c0       	push   $0xc0106428
c0103ccf:	e8 0f c7 ff ff       	call   c01003e3 <__panic>

    struct Page *p;
    p = alloc_page();
c0103cd4:	83 ec 0c             	sub    $0xc,%esp
c0103cd7:	6a 01                	push   $0x1
c0103cd9:	e8 c1 ef ff ff       	call   c0102c9f <alloc_pages>
c0103cde:	83 c4 10             	add    $0x10,%esp
c0103ce1:	89 45 e0             	mov    %eax,-0x20(%ebp)
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W) == 0);
c0103ce4:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103ce9:	6a 02                	push   $0x2
c0103ceb:	68 00 01 00 00       	push   $0x100
c0103cf0:	ff 75 e0             	pushl  -0x20(%ebp)
c0103cf3:	50                   	push   %eax
c0103cf4:	e8 00 f8 ff ff       	call   c01034f9 <page_insert>
c0103cf9:	83 c4 10             	add    $0x10,%esp
c0103cfc:	85 c0                	test   %eax,%eax
c0103cfe:	74 19                	je     c0103d19 <check_boot_pgdir+0x18e>
c0103d00:	68 d4 67 10 c0       	push   $0xc01067d4
c0103d05:	68 4d 64 10 c0       	push   $0xc010644d
c0103d0a:	68 38 02 00 00       	push   $0x238
c0103d0f:	68 28 64 10 c0       	push   $0xc0106428
c0103d14:	e8 ca c6 ff ff       	call   c01003e3 <__panic>
    assert(page_ref(p) == 1);
c0103d19:	83 ec 0c             	sub    $0xc,%esp
c0103d1c:	ff 75 e0             	pushl  -0x20(%ebp)
c0103d1f:	e8 6d ed ff ff       	call   c0102a91 <page_ref>
c0103d24:	83 c4 10             	add    $0x10,%esp
c0103d27:	83 f8 01             	cmp    $0x1,%eax
c0103d2a:	74 19                	je     c0103d45 <check_boot_pgdir+0x1ba>
c0103d2c:	68 02 68 10 c0       	push   $0xc0106802
c0103d31:	68 4d 64 10 c0       	push   $0xc010644d
c0103d36:	68 39 02 00 00       	push   $0x239
c0103d3b:	68 28 64 10 c0       	push   $0xc0106428
c0103d40:	e8 9e c6 ff ff       	call   c01003e3 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W) == 0);
c0103d45:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103d4a:	6a 02                	push   $0x2
c0103d4c:	68 00 11 00 00       	push   $0x1100
c0103d51:	ff 75 e0             	pushl  -0x20(%ebp)
c0103d54:	50                   	push   %eax
c0103d55:	e8 9f f7 ff ff       	call   c01034f9 <page_insert>
c0103d5a:	83 c4 10             	add    $0x10,%esp
c0103d5d:	85 c0                	test   %eax,%eax
c0103d5f:	74 19                	je     c0103d7a <check_boot_pgdir+0x1ef>
c0103d61:	68 14 68 10 c0       	push   $0xc0106814
c0103d66:	68 4d 64 10 c0       	push   $0xc010644d
c0103d6b:	68 3a 02 00 00       	push   $0x23a
c0103d70:	68 28 64 10 c0       	push   $0xc0106428
c0103d75:	e8 69 c6 ff ff       	call   c01003e3 <__panic>
    assert(page_ref(p) == 2);
c0103d7a:	83 ec 0c             	sub    $0xc,%esp
c0103d7d:	ff 75 e0             	pushl  -0x20(%ebp)
c0103d80:	e8 0c ed ff ff       	call   c0102a91 <page_ref>
c0103d85:	83 c4 10             	add    $0x10,%esp
c0103d88:	83 f8 02             	cmp    $0x2,%eax
c0103d8b:	74 19                	je     c0103da6 <check_boot_pgdir+0x21b>
c0103d8d:	68 4b 68 10 c0       	push   $0xc010684b
c0103d92:	68 4d 64 10 c0       	push   $0xc010644d
c0103d97:	68 3b 02 00 00       	push   $0x23b
c0103d9c:	68 28 64 10 c0       	push   $0xc0106428
c0103da1:	e8 3d c6 ff ff       	call   c01003e3 <__panic>

    const char *str = "ucore: Hello world!!";
c0103da6:	c7 45 dc 5c 68 10 c0 	movl   $0xc010685c,-0x24(%ebp)
    strcpy((void *)0x100, str);
c0103dad:	83 ec 08             	sub    $0x8,%esp
c0103db0:	ff 75 dc             	pushl  -0x24(%ebp)
c0103db3:	68 00 01 00 00       	push   $0x100
c0103db8:	e8 c3 13 00 00       	call   c0105180 <strcpy>
c0103dbd:	83 c4 10             	add    $0x10,%esp
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
c0103dc0:	83 ec 08             	sub    $0x8,%esp
c0103dc3:	68 00 11 00 00       	push   $0x1100
c0103dc8:	68 00 01 00 00       	push   $0x100
c0103dcd:	e8 28 14 00 00       	call   c01051fa <strcmp>
c0103dd2:	83 c4 10             	add    $0x10,%esp
c0103dd5:	85 c0                	test   %eax,%eax
c0103dd7:	74 19                	je     c0103df2 <check_boot_pgdir+0x267>
c0103dd9:	68 74 68 10 c0       	push   $0xc0106874
c0103dde:	68 4d 64 10 c0       	push   $0xc010644d
c0103de3:	68 3f 02 00 00       	push   $0x23f
c0103de8:	68 28 64 10 c0       	push   $0xc0106428
c0103ded:	e8 f1 c5 ff ff       	call   c01003e3 <__panic>

    *(char *)(page2kva(p) + 0x100) = '\0';
c0103df2:	83 ec 0c             	sub    $0xc,%esp
c0103df5:	ff 75 e0             	pushl  -0x20(%ebp)
c0103df8:	e8 f9 eb ff ff       	call   c01029f6 <page2kva>
c0103dfd:	83 c4 10             	add    $0x10,%esp
c0103e00:	05 00 01 00 00       	add    $0x100,%eax
c0103e05:	c6 00 00             	movb   $0x0,(%eax)
    assert(strlen((const char *)0x100) == 0);
c0103e08:	83 ec 0c             	sub    $0xc,%esp
c0103e0b:	68 00 01 00 00       	push   $0x100
c0103e10:	e8 13 13 00 00       	call   c0105128 <strlen>
c0103e15:	83 c4 10             	add    $0x10,%esp
c0103e18:	85 c0                	test   %eax,%eax
c0103e1a:	74 19                	je     c0103e35 <check_boot_pgdir+0x2aa>
c0103e1c:	68 ac 68 10 c0       	push   $0xc01068ac
c0103e21:	68 4d 64 10 c0       	push   $0xc010644d
c0103e26:	68 42 02 00 00       	push   $0x242
c0103e2b:	68 28 64 10 c0       	push   $0xc0106428
c0103e30:	e8 ae c5 ff ff       	call   c01003e3 <__panic>

    free_page(p);
c0103e35:	83 ec 08             	sub    $0x8,%esp
c0103e38:	6a 01                	push   $0x1
c0103e3a:	ff 75 e0             	pushl  -0x20(%ebp)
c0103e3d:	e8 9b ee ff ff       	call   c0102cdd <free_pages>
c0103e42:	83 c4 10             	add    $0x10,%esp
    free_page(pde2page(boot_pgdir[0]));
c0103e45:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103e4a:	8b 00                	mov    (%eax),%eax
c0103e4c:	83 ec 0c             	sub    $0xc,%esp
c0103e4f:	50                   	push   %eax
c0103e50:	e8 20 ec ff ff       	call   c0102a75 <pde2page>
c0103e55:	83 c4 10             	add    $0x10,%esp
c0103e58:	83 ec 08             	sub    $0x8,%esp
c0103e5b:	6a 01                	push   $0x1
c0103e5d:	50                   	push   %eax
c0103e5e:	e8 7a ee ff ff       	call   c0102cdd <free_pages>
c0103e63:	83 c4 10             	add    $0x10,%esp
    boot_pgdir[0] = 0;
c0103e66:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103e6b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_boot_pgdir() succeeded!\n");
c0103e71:	83 ec 0c             	sub    $0xc,%esp
c0103e74:	68 d0 68 10 c0       	push   $0xc01068d0
c0103e79:	e8 ff c3 ff ff       	call   c010027d <cprintf>
c0103e7e:	83 c4 10             	add    $0x10,%esp
}
c0103e81:	90                   	nop
c0103e82:	c9                   	leave  
c0103e83:	c3                   	ret    

c0103e84 <perm2str>:

//perm2str - use string 'u,r,w,-' to present the permission
static const char *
perm2str(int perm) {
c0103e84:	55                   	push   %ebp
c0103e85:	89 e5                	mov    %esp,%ebp
    static char str[4];
    str[0] = (perm & PTE_U) ? 'u' : '-';
c0103e87:	8b 45 08             	mov    0x8(%ebp),%eax
c0103e8a:	83 e0 04             	and    $0x4,%eax
c0103e8d:	85 c0                	test   %eax,%eax
c0103e8f:	74 07                	je     c0103e98 <perm2str+0x14>
c0103e91:	b8 75 00 00 00       	mov    $0x75,%eax
c0103e96:	eb 05                	jmp    c0103e9d <perm2str+0x19>
c0103e98:	b8 2d 00 00 00       	mov    $0x2d,%eax
c0103e9d:	a2 08 af 11 c0       	mov    %al,0xc011af08
    str[1] = 'r';
c0103ea2:	c6 05 09 af 11 c0 72 	movb   $0x72,0xc011af09
    str[2] = (perm & PTE_W) ? 'w' : '-';
c0103ea9:	8b 45 08             	mov    0x8(%ebp),%eax
c0103eac:	83 e0 02             	and    $0x2,%eax
c0103eaf:	85 c0                	test   %eax,%eax
c0103eb1:	74 07                	je     c0103eba <perm2str+0x36>
c0103eb3:	b8 77 00 00 00       	mov    $0x77,%eax
c0103eb8:	eb 05                	jmp    c0103ebf <perm2str+0x3b>
c0103eba:	b8 2d 00 00 00       	mov    $0x2d,%eax
c0103ebf:	a2 0a af 11 c0       	mov    %al,0xc011af0a
    str[3] = '\0';
c0103ec4:	c6 05 0b af 11 c0 00 	movb   $0x0,0xc011af0b
    return str;
c0103ecb:	b8 08 af 11 c0       	mov    $0xc011af08,%eax
}
c0103ed0:	5d                   	pop    %ebp
c0103ed1:	c3                   	ret    

c0103ed2 <get_pgtable_items>:
//  table:       the beginning addr of table
//  left_store:  the pointer of the high side of table's next range
//  right_store: the pointer of the low side of table's next range
// return value: 0 - not a invalid item range, perm - a valid item range with perm permission 
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
c0103ed2:	55                   	push   %ebp
c0103ed3:	89 e5                	mov    %esp,%ebp
c0103ed5:	83 ec 10             	sub    $0x10,%esp
    if (start >= right) {
c0103ed8:	8b 45 10             	mov    0x10(%ebp),%eax
c0103edb:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103ede:	72 0e                	jb     c0103eee <get_pgtable_items+0x1c>
        return 0;
c0103ee0:	b8 00 00 00 00       	mov    $0x0,%eax
c0103ee5:	e9 9a 00 00 00       	jmp    c0103f84 <get_pgtable_items+0xb2>
    }
    while (start < right && !(table[start] & PTE_P)) {
        start ++;
c0103eea:	83 45 10 01          	addl   $0x1,0x10(%ebp)
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
    if (start >= right) {
        return 0;
    }
    while (start < right && !(table[start] & PTE_P)) {
c0103eee:	8b 45 10             	mov    0x10(%ebp),%eax
c0103ef1:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103ef4:	73 18                	jae    c0103f0e <get_pgtable_items+0x3c>
c0103ef6:	8b 45 10             	mov    0x10(%ebp),%eax
c0103ef9:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0103f00:	8b 45 14             	mov    0x14(%ebp),%eax
c0103f03:	01 d0                	add    %edx,%eax
c0103f05:	8b 00                	mov    (%eax),%eax
c0103f07:	83 e0 01             	and    $0x1,%eax
c0103f0a:	85 c0                	test   %eax,%eax
c0103f0c:	74 dc                	je     c0103eea <get_pgtable_items+0x18>
        start ++;
    }
    if (start < right) {
c0103f0e:	8b 45 10             	mov    0x10(%ebp),%eax
c0103f11:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103f14:	73 69                	jae    c0103f7f <get_pgtable_items+0xad>
        if (left_store != NULL) {
c0103f16:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
c0103f1a:	74 08                	je     c0103f24 <get_pgtable_items+0x52>
            *left_store = start;
c0103f1c:	8b 45 18             	mov    0x18(%ebp),%eax
c0103f1f:	8b 55 10             	mov    0x10(%ebp),%edx
c0103f22:	89 10                	mov    %edx,(%eax)
        }
        int perm = (table[start ++] & PTE_USER);
c0103f24:	8b 45 10             	mov    0x10(%ebp),%eax
c0103f27:	8d 50 01             	lea    0x1(%eax),%edx
c0103f2a:	89 55 10             	mov    %edx,0x10(%ebp)
c0103f2d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0103f34:	8b 45 14             	mov    0x14(%ebp),%eax
c0103f37:	01 d0                	add    %edx,%eax
c0103f39:	8b 00                	mov    (%eax),%eax
c0103f3b:	83 e0 07             	and    $0x7,%eax
c0103f3e:	89 45 fc             	mov    %eax,-0x4(%ebp)
        while (start < right && (table[start] & PTE_USER) == perm) {
c0103f41:	eb 04                	jmp    c0103f47 <get_pgtable_items+0x75>
            start ++;
c0103f43:	83 45 10 01          	addl   $0x1,0x10(%ebp)
    if (start < right) {
        if (left_store != NULL) {
            *left_store = start;
        }
        int perm = (table[start ++] & PTE_USER);
        while (start < right && (table[start] & PTE_USER) == perm) {
c0103f47:	8b 45 10             	mov    0x10(%ebp),%eax
c0103f4a:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103f4d:	73 1d                	jae    c0103f6c <get_pgtable_items+0x9a>
c0103f4f:	8b 45 10             	mov    0x10(%ebp),%eax
c0103f52:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0103f59:	8b 45 14             	mov    0x14(%ebp),%eax
c0103f5c:	01 d0                	add    %edx,%eax
c0103f5e:	8b 00                	mov    (%eax),%eax
c0103f60:	83 e0 07             	and    $0x7,%eax
c0103f63:	89 c2                	mov    %eax,%edx
c0103f65:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0103f68:	39 c2                	cmp    %eax,%edx
c0103f6a:	74 d7                	je     c0103f43 <get_pgtable_items+0x71>
            start ++;
        }
        if (right_store != NULL) {
c0103f6c:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
c0103f70:	74 08                	je     c0103f7a <get_pgtable_items+0xa8>
            *right_store = start;
c0103f72:	8b 45 1c             	mov    0x1c(%ebp),%eax
c0103f75:	8b 55 10             	mov    0x10(%ebp),%edx
c0103f78:	89 10                	mov    %edx,(%eax)
        }
        return perm;
c0103f7a:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0103f7d:	eb 05                	jmp    c0103f84 <get_pgtable_items+0xb2>
    }
    return 0;
c0103f7f:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0103f84:	c9                   	leave  
c0103f85:	c3                   	ret    

c0103f86 <print_pgdir>:

//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
c0103f86:	55                   	push   %ebp
c0103f87:	89 e5                	mov    %esp,%ebp
c0103f89:	57                   	push   %edi
c0103f8a:	56                   	push   %esi
c0103f8b:	53                   	push   %ebx
c0103f8c:	83 ec 2c             	sub    $0x2c,%esp
    cprintf("-------------------- BEGIN --------------------\n");
c0103f8f:	83 ec 0c             	sub    $0xc,%esp
c0103f92:	68 f0 68 10 c0       	push   $0xc01068f0
c0103f97:	e8 e1 c2 ff ff       	call   c010027d <cprintf>
c0103f9c:	83 c4 10             	add    $0x10,%esp
    size_t left, right = 0, perm;
c0103f9f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
c0103fa6:	e9 e5 00 00 00       	jmp    c0104090 <print_pgdir+0x10a>
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
c0103fab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103fae:	83 ec 0c             	sub    $0xc,%esp
c0103fb1:	50                   	push   %eax
c0103fb2:	e8 cd fe ff ff       	call   c0103e84 <perm2str>
c0103fb7:	83 c4 10             	add    $0x10,%esp
c0103fba:	89 c7                	mov    %eax,%edi
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
c0103fbc:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0103fbf:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103fc2:	29 c2                	sub    %eax,%edx
c0103fc4:	89 d0                	mov    %edx,%eax
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
c0103fc6:	c1 e0 16             	shl    $0x16,%eax
c0103fc9:	89 c3                	mov    %eax,%ebx
c0103fcb:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0103fce:	c1 e0 16             	shl    $0x16,%eax
c0103fd1:	89 c1                	mov    %eax,%ecx
c0103fd3:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103fd6:	c1 e0 16             	shl    $0x16,%eax
c0103fd9:	89 c2                	mov    %eax,%edx
c0103fdb:	8b 75 dc             	mov    -0x24(%ebp),%esi
c0103fde:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103fe1:	29 c6                	sub    %eax,%esi
c0103fe3:	89 f0                	mov    %esi,%eax
c0103fe5:	83 ec 08             	sub    $0x8,%esp
c0103fe8:	57                   	push   %edi
c0103fe9:	53                   	push   %ebx
c0103fea:	51                   	push   %ecx
c0103feb:	52                   	push   %edx
c0103fec:	50                   	push   %eax
c0103fed:	68 21 69 10 c0       	push   $0xc0106921
c0103ff2:	e8 86 c2 ff ff       	call   c010027d <cprintf>
c0103ff7:	83 c4 20             	add    $0x20,%esp
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
c0103ffa:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103ffd:	c1 e0 0a             	shl    $0xa,%eax
c0104000:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
c0104003:	eb 4f                	jmp    c0104054 <print_pgdir+0xce>
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
c0104005:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104008:	83 ec 0c             	sub    $0xc,%esp
c010400b:	50                   	push   %eax
c010400c:	e8 73 fe ff ff       	call   c0103e84 <perm2str>
c0104011:	83 c4 10             	add    $0x10,%esp
c0104014:	89 c7                	mov    %eax,%edi
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
c0104016:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104019:	8b 45 d8             	mov    -0x28(%ebp),%eax
c010401c:	29 c2                	sub    %eax,%edx
c010401e:	89 d0                	mov    %edx,%eax
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
c0104020:	c1 e0 0c             	shl    $0xc,%eax
c0104023:	89 c3                	mov    %eax,%ebx
c0104025:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0104028:	c1 e0 0c             	shl    $0xc,%eax
c010402b:	89 c1                	mov    %eax,%ecx
c010402d:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104030:	c1 e0 0c             	shl    $0xc,%eax
c0104033:	89 c2                	mov    %eax,%edx
c0104035:	8b 75 d4             	mov    -0x2c(%ebp),%esi
c0104038:	8b 45 d8             	mov    -0x28(%ebp),%eax
c010403b:	29 c6                	sub    %eax,%esi
c010403d:	89 f0                	mov    %esi,%eax
c010403f:	83 ec 08             	sub    $0x8,%esp
c0104042:	57                   	push   %edi
c0104043:	53                   	push   %ebx
c0104044:	51                   	push   %ecx
c0104045:	52                   	push   %edx
c0104046:	50                   	push   %eax
c0104047:	68 40 69 10 c0       	push   $0xc0106940
c010404c:	e8 2c c2 ff ff       	call   c010027d <cprintf>
c0104051:	83 c4 20             	add    $0x20,%esp
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
c0104054:	be 00 00 c0 fa       	mov    $0xfac00000,%esi
c0104059:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010405c:	8b 55 dc             	mov    -0x24(%ebp),%edx
c010405f:	89 d3                	mov    %edx,%ebx
c0104061:	c1 e3 0a             	shl    $0xa,%ebx
c0104064:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0104067:	89 d1                	mov    %edx,%ecx
c0104069:	c1 e1 0a             	shl    $0xa,%ecx
c010406c:	83 ec 08             	sub    $0x8,%esp
c010406f:	8d 55 d4             	lea    -0x2c(%ebp),%edx
c0104072:	52                   	push   %edx
c0104073:	8d 55 d8             	lea    -0x28(%ebp),%edx
c0104076:	52                   	push   %edx
c0104077:	56                   	push   %esi
c0104078:	50                   	push   %eax
c0104079:	53                   	push   %ebx
c010407a:	51                   	push   %ecx
c010407b:	e8 52 fe ff ff       	call   c0103ed2 <get_pgtable_items>
c0104080:	83 c4 20             	add    $0x20,%esp
c0104083:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0104086:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c010408a:	0f 85 75 ff ff ff    	jne    c0104005 <print_pgdir+0x7f>
//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
c0104090:	b9 00 b0 fe fa       	mov    $0xfafeb000,%ecx
c0104095:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104098:	83 ec 08             	sub    $0x8,%esp
c010409b:	8d 55 dc             	lea    -0x24(%ebp),%edx
c010409e:	52                   	push   %edx
c010409f:	8d 55 e0             	lea    -0x20(%ebp),%edx
c01040a2:	52                   	push   %edx
c01040a3:	51                   	push   %ecx
c01040a4:	50                   	push   %eax
c01040a5:	68 00 04 00 00       	push   $0x400
c01040aa:	6a 00                	push   $0x0
c01040ac:	e8 21 fe ff ff       	call   c0103ed2 <get_pgtable_items>
c01040b1:	83 c4 20             	add    $0x20,%esp
c01040b4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c01040b7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c01040bb:	0f 85 ea fe ff ff    	jne    c0103fab <print_pgdir+0x25>
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
        }
    }
    cprintf("--------------------- END ---------------------\n");
c01040c1:	83 ec 0c             	sub    $0xc,%esp
c01040c4:	68 64 69 10 c0       	push   $0xc0106964
c01040c9:	e8 af c1 ff ff       	call   c010027d <cprintf>
c01040ce:	83 c4 10             	add    $0x10,%esp
}
c01040d1:	90                   	nop
c01040d2:	8d 65 f4             	lea    -0xc(%ebp),%esp
c01040d5:	5b                   	pop    %ebx
c01040d6:	5e                   	pop    %esi
c01040d7:	5f                   	pop    %edi
c01040d8:	5d                   	pop    %ebp
c01040d9:	c3                   	ret    

c01040da <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
c01040da:	55                   	push   %ebp
c01040db:	89 e5                	mov    %esp,%ebp
    return page - pages;//返回在物理内存中第几页
c01040dd:	8b 45 08             	mov    0x8(%ebp),%eax
c01040e0:	8b 15 18 af 11 c0    	mov    0xc011af18,%edx
c01040e6:	29 d0                	sub    %edx,%eax
c01040e8:	c1 f8 02             	sar    $0x2,%eax
c01040eb:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
c01040f1:	5d                   	pop    %ebp
c01040f2:	c3                   	ret    

c01040f3 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
c01040f3:	55                   	push   %ebp
c01040f4:	89 e5                	mov    %esp,%ebp
    return page2ppn(page) << PGSHIFT;
c01040f6:	ff 75 08             	pushl  0x8(%ebp)
c01040f9:	e8 dc ff ff ff       	call   c01040da <page2ppn>
c01040fe:	83 c4 04             	add    $0x4,%esp
c0104101:	c1 e0 0c             	shl    $0xc,%eax
}
c0104104:	c9                   	leave  
c0104105:	c3                   	ret    

c0104106 <page_ref>:
pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde));
}

static inline int
page_ref(struct Page *page) {
c0104106:	55                   	push   %ebp
c0104107:	89 e5                	mov    %esp,%ebp
    return page->ref;
c0104109:	8b 45 08             	mov    0x8(%ebp),%eax
c010410c:	8b 00                	mov    (%eax),%eax
}
c010410e:	5d                   	pop    %ebp
c010410f:	c3                   	ret    

c0104110 <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
c0104110:	55                   	push   %ebp
c0104111:	89 e5                	mov    %esp,%ebp
    page->ref = val;
c0104113:	8b 45 08             	mov    0x8(%ebp),%eax
c0104116:	8b 55 0c             	mov    0xc(%ebp),%edx
c0104119:	89 10                	mov    %edx,(%eax)
}
c010411b:	90                   	nop
c010411c:	5d                   	pop    %ebp
c010411d:	c3                   	ret    

c010411e <default_init>:

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
c010411e:	55                   	push   %ebp
c010411f:	89 e5                	mov    %esp,%ebp
c0104121:	83 ec 10             	sub    $0x10,%esp
c0104124:	c7 45 fc 1c af 11 c0 	movl   $0xc011af1c,-0x4(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c010412b:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010412e:	8b 55 fc             	mov    -0x4(%ebp),%edx
c0104131:	89 50 04             	mov    %edx,0x4(%eax)
c0104134:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0104137:	8b 50 04             	mov    0x4(%eax),%edx
c010413a:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010413d:	89 10                	mov    %edx,(%eax)
    list_init(&free_list);
    nr_free = 0;
c010413f:	c7 05 24 af 11 c0 00 	movl   $0x0,0xc011af24
c0104146:	00 00 00 
	
}
c0104149:	90                   	nop
c010414a:	c9                   	leave  
c010414b:	c3                   	ret    

c010414c <default_init_memmap>:

static void
default_init_memmap(struct Page *base, size_t n) { //实际物理地址
c010414c:	55                   	push   %ebp
c010414d:	89 e5                	mov    %esp,%ebp
c010414f:	83 ec 48             	sub    $0x48,%esp
    assert(n > 0); //强制要求n>0
c0104152:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0104156:	75 16                	jne    c010416e <default_init_memmap+0x22>
c0104158:	68 98 69 10 c0       	push   $0xc0106998
c010415d:	68 9e 69 10 c0       	push   $0xc010699e
c0104162:	6a 74                	push   $0x74
c0104164:	68 b3 69 10 c0       	push   $0xc01069b3
c0104169:	e8 75 c2 ff ff       	call   c01003e3 <__panic>
    struct Page *p = base;  
c010416e:	8b 45 08             	mov    0x8(%ebp),%eax
c0104171:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
c0104174:	eb 6c                	jmp    c01041e2 <default_init_memmap+0x96>
        assert(PageReserved(p));//要求不是保留页
c0104176:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104179:	83 c0 04             	add    $0x4,%eax
c010417c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
c0104183:	89 45 e4             	mov    %eax,-0x1c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104186:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104189:	8b 55 e8             	mov    -0x18(%ebp),%edx
c010418c:	0f a3 10             	bt     %edx,(%eax)
c010418f:	19 c0                	sbb    %eax,%eax
c0104191:	89 45 e0             	mov    %eax,-0x20(%ebp)
    return oldbit != 0;
c0104194:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
c0104198:	0f 95 c0             	setne  %al
c010419b:	0f b6 c0             	movzbl %al,%eax
c010419e:	85 c0                	test   %eax,%eax
c01041a0:	75 16                	jne    c01041b8 <default_init_memmap+0x6c>
c01041a2:	68 c9 69 10 c0       	push   $0xc01069c9
c01041a7:	68 9e 69 10 c0       	push   $0xc010699e
c01041ac:	6a 77                	push   $0x77
c01041ae:	68 b3 69 10 c0       	push   $0xc01069b3
c01041b3:	e8 2b c2 ff ff       	call   c01003e3 <__panic>
        p->flags = p->property = 0;//将每个page的flag与property置0 在ffma中每个空闲块的第一个页表结构使用，表示该块空闲页表个数
c01041b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01041bb:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
c01041c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01041c5:	8b 50 08             	mov    0x8(%eax),%edx
c01041c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01041cb:	89 50 04             	mov    %edx,0x4(%eax)
        set_page_ref(p, 0);//被映射次数 0
c01041ce:	83 ec 08             	sub    $0x8,%esp
c01041d1:	6a 00                	push   $0x0
c01041d3:	ff 75 f4             	pushl  -0xc(%ebp)
c01041d6:	e8 35 ff ff ff       	call   c0104110 <set_page_ref>
c01041db:	83 c4 10             	add    $0x10,%esp

static void
default_init_memmap(struct Page *base, size_t n) { //实际物理地址
    assert(n > 0); //强制要求n>0
    struct Page *p = base;  
    for (; p != base + n; p ++) {
c01041de:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
c01041e2:	8b 55 0c             	mov    0xc(%ebp),%edx
c01041e5:	89 d0                	mov    %edx,%eax
c01041e7:	c1 e0 02             	shl    $0x2,%eax
c01041ea:	01 d0                	add    %edx,%eax
c01041ec:	c1 e0 02             	shl    $0x2,%eax
c01041ef:	89 c2                	mov    %eax,%edx
c01041f1:	8b 45 08             	mov    0x8(%ebp),%eax
c01041f4:	01 d0                	add    %edx,%eax
c01041f6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01041f9:	0f 85 77 ff ff ff    	jne    c0104176 <default_init_memmap+0x2a>
        assert(PageReserved(p));//要求不是保留页
        p->flags = p->property = 0;//将每个page的flag与property置0 在ffma中每个空闲块的第一个页表结构使用，表示该块空闲页表个数
        set_page_ref(p, 0);//被映射次数 0
    }
    base->property = n; //空闲页表数目
c01041ff:	8b 45 08             	mov    0x8(%ebp),%eax
c0104202:	8b 55 0c             	mov    0xc(%ebp),%edx
c0104205:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base); //空闲块首页
c0104208:	8b 45 08             	mov    0x8(%ebp),%eax
c010420b:	83 c0 04             	add    $0x4,%eax
c010420e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
c0104215:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0104218:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c010421b:	8b 55 ec             	mov    -0x14(%ebp),%edx
c010421e:	0f ab 10             	bts    %edx,(%eax)
    nr_free += n; //空闲页数目
c0104221:	8b 15 24 af 11 c0    	mov    0xc011af24,%edx
c0104227:	8b 45 0c             	mov    0xc(%ebp),%eax
c010422a:	01 d0                	add    %edx,%eax
c010422c:	a3 24 af 11 c0       	mov    %eax,0xc011af24
    list_add(&free_list, &(base->page_link));
c0104231:	8b 45 08             	mov    0x8(%ebp),%eax
c0104234:	83 c0 0c             	add    $0xc,%eax
c0104237:	c7 45 f0 1c af 11 c0 	movl   $0xc011af1c,-0x10(%ebp)
c010423e:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104241:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104244:	89 45 d8             	mov    %eax,-0x28(%ebp)
c0104247:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010424a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
c010424d:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104250:	8b 40 04             	mov    0x4(%eax),%eax
c0104253:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104256:	89 55 d0             	mov    %edx,-0x30(%ebp)
c0104259:	8b 55 d8             	mov    -0x28(%ebp),%edx
c010425c:	89 55 cc             	mov    %edx,-0x34(%ebp)
c010425f:	89 45 c8             	mov    %eax,-0x38(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c0104262:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0104265:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0104268:	89 10                	mov    %edx,(%eax)
c010426a:	8b 45 c8             	mov    -0x38(%ebp),%eax
c010426d:	8b 10                	mov    (%eax),%edx
c010426f:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0104272:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c0104275:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104278:	8b 55 c8             	mov    -0x38(%ebp),%edx
c010427b:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c010427e:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104281:	8b 55 cc             	mov    -0x34(%ebp),%edx
c0104284:	89 10                	mov    %edx,(%eax)
}
c0104286:	90                   	nop
c0104287:	c9                   	leave  
c0104288:	c3                   	ret    

c0104289 <default_alloc_pages>:

static struct Page *
default_alloc_pages(size_t n) {
c0104289:	55                   	push   %ebp
c010428a:	89 e5                	mov    %esp,%ebp
c010428c:	83 ec 58             	sub    $0x58,%esp
    assert(n > 0);
c010428f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0104293:	75 19                	jne    c01042ae <default_alloc_pages+0x25>
c0104295:	68 98 69 10 c0       	push   $0xc0106998
c010429a:	68 9e 69 10 c0       	push   $0xc010699e
c010429f:	68 83 00 00 00       	push   $0x83
c01042a4:	68 b3 69 10 c0       	push   $0xc01069b3
c01042a9:	e8 35 c1 ff ff       	call   c01003e3 <__panic>
    if (n > nr_free) {
c01042ae:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c01042b3:	3b 45 08             	cmp    0x8(%ebp),%eax
c01042b6:	73 0a                	jae    c01042c2 <default_alloc_pages+0x39>
        return NULL;
c01042b8:	b8 00 00 00 00       	mov    $0x0,%eax
c01042bd:	e9 3d 01 00 00       	jmp    c01043ff <default_alloc_pages+0x176>
    }
    struct Page *page = NULL;
c01042c2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    list_entry_t *le = &free_list;
c01042c9:	c7 45 f0 1c af 11 c0 	movl   $0xc011af1c,-0x10(%ebp)
    while ((le = list_next(le)) != &free_list) {
c01042d0:	eb 1c                	jmp    c01042ee <default_alloc_pages+0x65>
        struct Page *p =  le2page(le, page_link); //将链表节点转换成page
c01042d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01042d5:	83 e8 0c             	sub    $0xc,%eax
c01042d8:	89 45 e8             	mov    %eax,-0x18(%ebp)
        if (p->property >= n) {
c01042db:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01042de:	8b 40 08             	mov    0x8(%eax),%eax
c01042e1:	3b 45 08             	cmp    0x8(%ebp),%eax
c01042e4:	72 08                	jb     c01042ee <default_alloc_pages+0x65>
            page = p;
c01042e6:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01042e9:	89 45 f4             	mov    %eax,-0xc(%ebp)
            break;
c01042ec:	eb 18                	jmp    c0104306 <default_alloc_pages+0x7d>
c01042ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01042f1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c01042f4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01042f7:	8b 40 04             	mov    0x4(%eax),%eax
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
c01042fa:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01042fd:	81 7d f0 1c af 11 c0 	cmpl   $0xc011af1c,-0x10(%ebp)
c0104304:	75 cc                	jne    c01042d2 <default_alloc_pages+0x49>
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
c0104306:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c010430a:	0f 84 ec 00 00 00    	je     c01043fc <default_alloc_pages+0x173>
        
        if (page->property > n) {
c0104310:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104313:	8b 40 08             	mov    0x8(%eax),%eax
c0104316:	3b 45 08             	cmp    0x8(%ebp),%eax
c0104319:	0f 86 8c 00 00 00    	jbe    c01043ab <default_alloc_pages+0x122>
            struct Page *p = page + n;  //第n个
c010431f:	8b 55 08             	mov    0x8(%ebp),%edx
c0104322:	89 d0                	mov    %edx,%eax
c0104324:	c1 e0 02             	shl    $0x2,%eax
c0104327:	01 d0                	add    %edx,%eax
c0104329:	c1 e0 02             	shl    $0x2,%eax
c010432c:	89 c2                	mov    %eax,%edx
c010432e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104331:	01 d0                	add    %edx,%eax
c0104333:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            p->property = page->property - n; //设置空闲页数量
c0104336:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104339:	8b 40 08             	mov    0x8(%eax),%eax
c010433c:	2b 45 08             	sub    0x8(%ebp),%eax
c010433f:	89 c2                	mov    %eax,%edx
c0104341:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104344:	89 50 08             	mov    %edx,0x8(%eax)
		    SetPageProperty(p); //设置未头部
c0104347:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010434a:	83 c0 04             	add    $0x4,%eax
c010434d:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
c0104354:	89 45 c0             	mov    %eax,-0x40(%ebp)
c0104357:	8b 45 c0             	mov    -0x40(%ebp),%eax
c010435a:	8b 55 dc             	mov    -0x24(%ebp),%edx
c010435d:	0f ab 10             	bts    %edx,(%eax)
            list_add_after(&(page->page_link), &(p->page_link));
c0104360:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104363:	83 c0 0c             	add    $0xc,%eax
c0104366:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0104369:	83 c2 0c             	add    $0xc,%edx
c010436c:	89 55 ec             	mov    %edx,-0x14(%ebp)
c010436f:	89 45 d0             	mov    %eax,-0x30(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
c0104372:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104375:	8b 40 04             	mov    0x4(%eax),%eax
c0104378:	8b 55 d0             	mov    -0x30(%ebp),%edx
c010437b:	89 55 cc             	mov    %edx,-0x34(%ebp)
c010437e:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0104381:	89 55 c8             	mov    %edx,-0x38(%ebp)
c0104384:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c0104387:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c010438a:	8b 55 cc             	mov    -0x34(%ebp),%edx
c010438d:	89 10                	mov    %edx,(%eax)
c010438f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104392:	8b 10                	mov    (%eax),%edx
c0104394:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0104397:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c010439a:	8b 45 cc             	mov    -0x34(%ebp),%eax
c010439d:	8b 55 c4             	mov    -0x3c(%ebp),%edx
c01043a0:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c01043a3:	8b 45 cc             	mov    -0x34(%ebp),%eax
c01043a6:	8b 55 c8             	mov    -0x38(%ebp),%edx
c01043a9:	89 10                	mov    %edx,(%eax)
    }
        list_del(&(page->page_link));
c01043ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01043ae:	83 c0 0c             	add    $0xc,%eax
c01043b1:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c01043b4:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01043b7:	8b 40 04             	mov    0x4(%eax),%eax
c01043ba:	8b 55 d8             	mov    -0x28(%ebp),%edx
c01043bd:	8b 12                	mov    (%edx),%edx
c01043bf:	89 55 b8             	mov    %edx,-0x48(%ebp)
c01043c2:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c01043c5:	8b 45 b8             	mov    -0x48(%ebp),%eax
c01043c8:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c01043cb:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c01043ce:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c01043d1:	8b 55 b8             	mov    -0x48(%ebp),%edx
c01043d4:	89 10                	mov    %edx,(%eax)
	    nr_free -= n;
c01043d6:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c01043db:	2b 45 08             	sub    0x8(%ebp),%eax
c01043de:	a3 24 af 11 c0       	mov    %eax,0xc011af24
        ClearPageProperty(page);
c01043e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01043e6:	83 c0 04             	add    $0x4,%eax
c01043e9:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
c01043f0:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c01043f3:	8b 45 bc             	mov    -0x44(%ebp),%eax
c01043f6:	8b 55 e0             	mov    -0x20(%ebp),%edx
c01043f9:	0f b3 10             	btr    %edx,(%eax)
    }
    return page;
c01043fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01043ff:	c9                   	leave  
c0104400:	c3                   	ret    

c0104401 <default_free_pages>:

static void
default_free_pages(struct Page *base, size_t n) {
c0104401:	55                   	push   %ebp
c0104402:	89 e5                	mov    %esp,%ebp
c0104404:	81 ec 88 00 00 00    	sub    $0x88,%esp
    assert(n > 0);
c010440a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c010440e:	75 19                	jne    c0104429 <default_free_pages+0x28>
c0104410:	68 98 69 10 c0       	push   $0xc0106998
c0104415:	68 9e 69 10 c0       	push   $0xc010699e
c010441a:	68 a1 00 00 00       	push   $0xa1
c010441f:	68 b3 69 10 c0       	push   $0xc01069b3
c0104424:	e8 ba bf ff ff       	call   c01003e3 <__panic>
    struct Page *p = base;
c0104429:	8b 45 08             	mov    0x8(%ebp),%eax
c010442c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	//将这n个连续页flag与ref清零
    for (; p != base + n; p ++) {
c010442f:	e9 8f 00 00 00       	jmp    c01044c3 <default_free_pages+0xc2>
        assert(!PageReserved(p) && !PageProperty(p));//检查
c0104434:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104437:	83 c0 04             	add    $0x4,%eax
c010443a:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
c0104441:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104444:	8b 45 bc             	mov    -0x44(%ebp),%eax
c0104447:	8b 55 c0             	mov    -0x40(%ebp),%edx
c010444a:	0f a3 10             	bt     %edx,(%eax)
c010444d:	19 c0                	sbb    %eax,%eax
c010444f:	89 45 b8             	mov    %eax,-0x48(%ebp)
    return oldbit != 0;
c0104452:	83 7d b8 00          	cmpl   $0x0,-0x48(%ebp)
c0104456:	0f 95 c0             	setne  %al
c0104459:	0f b6 c0             	movzbl %al,%eax
c010445c:	85 c0                	test   %eax,%eax
c010445e:	75 2c                	jne    c010448c <default_free_pages+0x8b>
c0104460:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104463:	83 c0 04             	add    $0x4,%eax
c0104466:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
c010446d:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104470:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c0104473:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0104476:	0f a3 10             	bt     %edx,(%eax)
c0104479:	19 c0                	sbb    %eax,%eax
c010447b:	89 45 b0             	mov    %eax,-0x50(%ebp)
    return oldbit != 0;
c010447e:	83 7d b0 00          	cmpl   $0x0,-0x50(%ebp)
c0104482:	0f 95 c0             	setne  %al
c0104485:	0f b6 c0             	movzbl %al,%eax
c0104488:	85 c0                	test   %eax,%eax
c010448a:	74 19                	je     c01044a5 <default_free_pages+0xa4>
c010448c:	68 dc 69 10 c0       	push   $0xc01069dc
c0104491:	68 9e 69 10 c0       	push   $0xc010699e
c0104496:	68 a5 00 00 00       	push   $0xa5
c010449b:	68 b3 69 10 c0       	push   $0xc01069b3
c01044a0:	e8 3e bf ff ff       	call   c01003e3 <__panic>
        p->flags = 0;
c01044a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01044a8:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
        set_page_ref(p, 0);
c01044af:	83 ec 08             	sub    $0x8,%esp
c01044b2:	6a 00                	push   $0x0
c01044b4:	ff 75 f4             	pushl  -0xc(%ebp)
c01044b7:	e8 54 fc ff ff       	call   c0104110 <set_page_ref>
c01044bc:	83 c4 10             	add    $0x10,%esp
static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
	//将这n个连续页flag与ref清零
    for (; p != base + n; p ++) {
c01044bf:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
c01044c3:	8b 55 0c             	mov    0xc(%ebp),%edx
c01044c6:	89 d0                	mov    %edx,%eax
c01044c8:	c1 e0 02             	shl    $0x2,%eax
c01044cb:	01 d0                	add    %edx,%eax
c01044cd:	c1 e0 02             	shl    $0x2,%eax
c01044d0:	89 c2                	mov    %eax,%edx
c01044d2:	8b 45 08             	mov    0x8(%ebp),%eax
c01044d5:	01 d0                	add    %edx,%eax
c01044d7:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01044da:	0f 85 54 ff ff ff    	jne    c0104434 <default_free_pages+0x33>
        assert(!PageReserved(p) && !PageProperty(p));//检查
        p->flags = 0;
        set_page_ref(p, 0);
    }
	//设置头页
    base->property = n;
c01044e0:	8b 45 08             	mov    0x8(%ebp),%eax
c01044e3:	8b 55 0c             	mov    0xc(%ebp),%edx
c01044e6:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
c01044e9:	8b 45 08             	mov    0x8(%ebp),%eax
c01044ec:	83 c0 04             	add    $0x4,%eax
c01044ef:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
c01044f6:	89 45 ac             	mov    %eax,-0x54(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c01044f9:	8b 45 ac             	mov    -0x54(%ebp),%eax
c01044fc:	8b 55 e0             	mov    -0x20(%ebp),%edx
c01044ff:	0f ab 10             	bts    %edx,(%eax)
c0104502:	c7 45 e8 1c af 11 c0 	movl   $0xc011af1c,-0x18(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0104509:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010450c:	8b 40 04             	mov    0x4(%eax),%eax
    list_entry_t *le = list_next(&free_list);
c010450f:	89 45 f0             	mov    %eax,-0x10(%ebp)
	//空闲块的合并
    while (le != &free_list) {
c0104512:	e9 08 01 00 00       	jmp    c010461f <default_free_pages+0x21e>
        p = le2page(le, page_link);
c0104517:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010451a:	83 e8 0c             	sub    $0xc,%eax
c010451d:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0104520:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104523:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0104526:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104529:	8b 40 04             	mov    0x4(%eax),%eax
        le = list_next(le);
c010452c:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (base + base->property == p) {
c010452f:	8b 45 08             	mov    0x8(%ebp),%eax
c0104532:	8b 50 08             	mov    0x8(%eax),%edx
c0104535:	89 d0                	mov    %edx,%eax
c0104537:	c1 e0 02             	shl    $0x2,%eax
c010453a:	01 d0                	add    %edx,%eax
c010453c:	c1 e0 02             	shl    $0x2,%eax
c010453f:	89 c2                	mov    %eax,%edx
c0104541:	8b 45 08             	mov    0x8(%ebp),%eax
c0104544:	01 d0                	add    %edx,%eax
c0104546:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0104549:	75 5a                	jne    c01045a5 <default_free_pages+0x1a4>
            base->property += p->property;
c010454b:	8b 45 08             	mov    0x8(%ebp),%eax
c010454e:	8b 50 08             	mov    0x8(%eax),%edx
c0104551:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104554:	8b 40 08             	mov    0x8(%eax),%eax
c0104557:	01 c2                	add    %eax,%edx
c0104559:	8b 45 08             	mov    0x8(%ebp),%eax
c010455c:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(p);
c010455f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104562:	83 c0 04             	add    $0x4,%eax
c0104565:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
c010456c:	89 45 a0             	mov    %eax,-0x60(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c010456f:	8b 45 a0             	mov    -0x60(%ebp),%eax
c0104572:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104575:	0f b3 10             	btr    %edx,(%eax)
            list_del(&(p->page_link));
c0104578:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010457b:	83 c0 0c             	add    $0xc,%eax
c010457e:	89 45 dc             	mov    %eax,-0x24(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c0104581:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104584:	8b 40 04             	mov    0x4(%eax),%eax
c0104587:	8b 55 dc             	mov    -0x24(%ebp),%edx
c010458a:	8b 12                	mov    (%edx),%edx
c010458c:	89 55 a8             	mov    %edx,-0x58(%ebp)
c010458f:	89 45 a4             	mov    %eax,-0x5c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c0104592:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0104595:	8b 55 a4             	mov    -0x5c(%ebp),%edx
c0104598:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c010459b:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c010459e:	8b 55 a8             	mov    -0x58(%ebp),%edx
c01045a1:	89 10                	mov    %edx,(%eax)
c01045a3:	eb 7a                	jmp    c010461f <default_free_pages+0x21e>
        }
        else if (p + p->property == base) {
c01045a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01045a8:	8b 50 08             	mov    0x8(%eax),%edx
c01045ab:	89 d0                	mov    %edx,%eax
c01045ad:	c1 e0 02             	shl    $0x2,%eax
c01045b0:	01 d0                	add    %edx,%eax
c01045b2:	c1 e0 02             	shl    $0x2,%eax
c01045b5:	89 c2                	mov    %eax,%edx
c01045b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01045ba:	01 d0                	add    %edx,%eax
c01045bc:	3b 45 08             	cmp    0x8(%ebp),%eax
c01045bf:	75 5e                	jne    c010461f <default_free_pages+0x21e>
            p->property += base->property;
c01045c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01045c4:	8b 50 08             	mov    0x8(%eax),%edx
c01045c7:	8b 45 08             	mov    0x8(%ebp),%eax
c01045ca:	8b 40 08             	mov    0x8(%eax),%eax
c01045cd:	01 c2                	add    %eax,%edx
c01045cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01045d2:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(base);
c01045d5:	8b 45 08             	mov    0x8(%ebp),%eax
c01045d8:	83 c0 04             	add    $0x4,%eax
c01045db:	c7 45 cc 01 00 00 00 	movl   $0x1,-0x34(%ebp)
c01045e2:	89 45 94             	mov    %eax,-0x6c(%ebp)
c01045e5:	8b 45 94             	mov    -0x6c(%ebp),%eax
c01045e8:	8b 55 cc             	mov    -0x34(%ebp),%edx
c01045eb:	0f b3 10             	btr    %edx,(%eax)
            base = p;
c01045ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01045f1:	89 45 08             	mov    %eax,0x8(%ebp)
            list_del(&(p->page_link));
c01045f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01045f7:	83 c0 0c             	add    $0xc,%eax
c01045fa:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c01045fd:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104600:	8b 40 04             	mov    0x4(%eax),%eax
c0104603:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0104606:	8b 12                	mov    (%edx),%edx
c0104608:	89 55 9c             	mov    %edx,-0x64(%ebp)
c010460b:	89 45 98             	mov    %eax,-0x68(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c010460e:	8b 45 9c             	mov    -0x64(%ebp),%eax
c0104611:	8b 55 98             	mov    -0x68(%ebp),%edx
c0104614:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c0104617:	8b 45 98             	mov    -0x68(%ebp),%eax
c010461a:	8b 55 9c             	mov    -0x64(%ebp),%edx
c010461d:	89 10                	mov    %edx,(%eax)
	//设置头页
    base->property = n;
    SetPageProperty(base);
    list_entry_t *le = list_next(&free_list);
	//空闲块的合并
    while (le != &free_list) {
c010461f:	81 7d f0 1c af 11 c0 	cmpl   $0xc011af1c,-0x10(%ebp)
c0104626:	0f 85 eb fe ff ff    	jne    c0104517 <default_free_pages+0x116>
            ClearPageProperty(base);
            base = p;
            list_del(&(p->page_link));
        }
    }
    nr_free += n;
c010462c:	8b 15 24 af 11 c0    	mov    0xc011af24,%edx
c0104632:	8b 45 0c             	mov    0xc(%ebp),%eax
c0104635:	01 d0                	add    %edx,%eax
c0104637:	a3 24 af 11 c0       	mov    %eax,0xc011af24
c010463c:	c7 45 d0 1c af 11 c0 	movl   $0xc011af1c,-0x30(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0104643:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104646:	8b 40 04             	mov    0x4(%eax),%eax
	le=list_next(&free_list);
c0104649:	89 45 f0             	mov    %eax,-0x10(%ebp)
	//按地址从小到大插入。
	while(le!=&free_list){
c010464c:	eb 69                	jmp    c01046b7 <default_free_pages+0x2b6>
		p=le2page(le,page_link);
c010464e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104651:	83 e8 0c             	sub    $0xc,%eax
c0104654:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if(base+base->property<=p){
c0104657:	8b 45 08             	mov    0x8(%ebp),%eax
c010465a:	8b 50 08             	mov    0x8(%eax),%edx
c010465d:	89 d0                	mov    %edx,%eax
c010465f:	c1 e0 02             	shl    $0x2,%eax
c0104662:	01 d0                	add    %edx,%eax
c0104664:	c1 e0 02             	shl    $0x2,%eax
c0104667:	89 c2                	mov    %eax,%edx
c0104669:	8b 45 08             	mov    0x8(%ebp),%eax
c010466c:	01 d0                	add    %edx,%eax
c010466e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0104671:	77 35                	ja     c01046a8 <default_free_pages+0x2a7>
			assert(base+base->property!=p);
c0104673:	8b 45 08             	mov    0x8(%ebp),%eax
c0104676:	8b 50 08             	mov    0x8(%eax),%edx
c0104679:	89 d0                	mov    %edx,%eax
c010467b:	c1 e0 02             	shl    $0x2,%eax
c010467e:	01 d0                	add    %edx,%eax
c0104680:	c1 e0 02             	shl    $0x2,%eax
c0104683:	89 c2                	mov    %eax,%edx
c0104685:	8b 45 08             	mov    0x8(%ebp),%eax
c0104688:	01 d0                	add    %edx,%eax
c010468a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c010468d:	75 33                	jne    c01046c2 <default_free_pages+0x2c1>
c010468f:	68 01 6a 10 c0       	push   $0xc0106a01
c0104694:	68 9e 69 10 c0       	push   $0xc010699e
c0104699:	68 c3 00 00 00       	push   $0xc3
c010469e:	68 b3 69 10 c0       	push   $0xc01069b3
c01046a3:	e8 3b bd ff ff       	call   c01003e3 <__panic>
c01046a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01046ab:	89 45 c8             	mov    %eax,-0x38(%ebp)
c01046ae:	8b 45 c8             	mov    -0x38(%ebp),%eax
c01046b1:	8b 40 04             	mov    0x4(%eax),%eax
			break;
		}
		le=list_next(le);
c01046b4:	89 45 f0             	mov    %eax,-0x10(%ebp)
        }
    }
    nr_free += n;
	le=list_next(&free_list);
	//按地址从小到大插入。
	while(le!=&free_list){
c01046b7:	81 7d f0 1c af 11 c0 	cmpl   $0xc011af1c,-0x10(%ebp)
c01046be:	75 8e                	jne    c010464e <default_free_pages+0x24d>
c01046c0:	eb 01                	jmp    c01046c3 <default_free_pages+0x2c2>
		p=le2page(le,page_link);
		if(base+base->property<=p){
			assert(base+base->property!=p);
			break;
c01046c2:	90                   	nop
		}
		le=list_next(le);
	}
		
    list_add_before(le, &(base->page_link));
c01046c3:	8b 45 08             	mov    0x8(%ebp),%eax
c01046c6:	8d 50 0c             	lea    0xc(%eax),%edx
c01046c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01046cc:	89 45 c4             	mov    %eax,-0x3c(%ebp)
c01046cf:	89 55 90             	mov    %edx,-0x70(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
c01046d2:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c01046d5:	8b 00                	mov    (%eax),%eax
c01046d7:	8b 55 90             	mov    -0x70(%ebp),%edx
c01046da:	89 55 8c             	mov    %edx,-0x74(%ebp)
c01046dd:	89 45 88             	mov    %eax,-0x78(%ebp)
c01046e0:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c01046e3:	89 45 84             	mov    %eax,-0x7c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c01046e6:	8b 45 84             	mov    -0x7c(%ebp),%eax
c01046e9:	8b 55 8c             	mov    -0x74(%ebp),%edx
c01046ec:	89 10                	mov    %edx,(%eax)
c01046ee:	8b 45 84             	mov    -0x7c(%ebp),%eax
c01046f1:	8b 10                	mov    (%eax),%edx
c01046f3:	8b 45 88             	mov    -0x78(%ebp),%eax
c01046f6:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c01046f9:	8b 45 8c             	mov    -0x74(%ebp),%eax
c01046fc:	8b 55 84             	mov    -0x7c(%ebp),%edx
c01046ff:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0104702:	8b 45 8c             	mov    -0x74(%ebp),%eax
c0104705:	8b 55 88             	mov    -0x78(%ebp),%edx
c0104708:	89 10                	mov    %edx,(%eax)
}
c010470a:	90                   	nop
c010470b:	c9                   	leave  
c010470c:	c3                   	ret    

c010470d <default_nr_free_pages>:

static size_t
default_nr_free_pages(void) {
c010470d:	55                   	push   %ebp
c010470e:	89 e5                	mov    %esp,%ebp
    return nr_free;
c0104710:	a1 24 af 11 c0       	mov    0xc011af24,%eax
}
c0104715:	5d                   	pop    %ebp
c0104716:	c3                   	ret    

c0104717 <basic_check>:

static void
basic_check(void) {
c0104717:	55                   	push   %ebp
c0104718:	89 e5                	mov    %esp,%ebp
c010471a:	83 ec 38             	sub    $0x38,%esp
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
c010471d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0104724:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104727:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010472a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010472d:	89 45 ec             	mov    %eax,-0x14(%ebp)
	//连续三次分配页，每次一页
    assert((p0 = alloc_page()) != NULL);
c0104730:	83 ec 0c             	sub    $0xc,%esp
c0104733:	6a 01                	push   $0x1
c0104735:	e8 65 e5 ff ff       	call   c0102c9f <alloc_pages>
c010473a:	83 c4 10             	add    $0x10,%esp
c010473d:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0104740:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c0104744:	75 19                	jne    c010475f <basic_check+0x48>
c0104746:	68 18 6a 10 c0       	push   $0xc0106a18
c010474b:	68 9e 69 10 c0       	push   $0xc010699e
c0104750:	68 d6 00 00 00       	push   $0xd6
c0104755:	68 b3 69 10 c0       	push   $0xc01069b3
c010475a:	e8 84 bc ff ff       	call   c01003e3 <__panic>
    assert((p1 = alloc_page()) != NULL);
c010475f:	83 ec 0c             	sub    $0xc,%esp
c0104762:	6a 01                	push   $0x1
c0104764:	e8 36 e5 ff ff       	call   c0102c9f <alloc_pages>
c0104769:	83 c4 10             	add    $0x10,%esp
c010476c:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010476f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0104773:	75 19                	jne    c010478e <basic_check+0x77>
c0104775:	68 34 6a 10 c0       	push   $0xc0106a34
c010477a:	68 9e 69 10 c0       	push   $0xc010699e
c010477f:	68 d7 00 00 00       	push   $0xd7
c0104784:	68 b3 69 10 c0       	push   $0xc01069b3
c0104789:	e8 55 bc ff ff       	call   c01003e3 <__panic>
    assert((p2 = alloc_page()) != NULL);
c010478e:	83 ec 0c             	sub    $0xc,%esp
c0104791:	6a 01                	push   $0x1
c0104793:	e8 07 e5 ff ff       	call   c0102c9f <alloc_pages>
c0104798:	83 c4 10             	add    $0x10,%esp
c010479b:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010479e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01047a2:	75 19                	jne    c01047bd <basic_check+0xa6>
c01047a4:	68 50 6a 10 c0       	push   $0xc0106a50
c01047a9:	68 9e 69 10 c0       	push   $0xc010699e
c01047ae:	68 d8 00 00 00       	push   $0xd8
c01047b3:	68 b3 69 10 c0       	push   $0xc01069b3
c01047b8:	e8 26 bc ff ff       	call   c01003e3 <__panic>
	
	//两两不等
    assert(p0 != p1 && p0 != p2 && p1 != p2);
c01047bd:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01047c0:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c01047c3:	74 10                	je     c01047d5 <basic_check+0xbe>
c01047c5:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01047c8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01047cb:	74 08                	je     c01047d5 <basic_check+0xbe>
c01047cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01047d0:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01047d3:	75 19                	jne    c01047ee <basic_check+0xd7>
c01047d5:	68 6c 6a 10 c0       	push   $0xc0106a6c
c01047da:	68 9e 69 10 c0       	push   $0xc010699e
c01047df:	68 db 00 00 00       	push   $0xdb
c01047e4:	68 b3 69 10 c0       	push   $0xc01069b3
c01047e9:	e8 f5 bb ff ff       	call   c01003e3 <__panic>
	//当钱物理页面被虚拟页面引用的次数都为0
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
c01047ee:	83 ec 0c             	sub    $0xc,%esp
c01047f1:	ff 75 ec             	pushl  -0x14(%ebp)
c01047f4:	e8 0d f9 ff ff       	call   c0104106 <page_ref>
c01047f9:	83 c4 10             	add    $0x10,%esp
c01047fc:	85 c0                	test   %eax,%eax
c01047fe:	75 24                	jne    c0104824 <basic_check+0x10d>
c0104800:	83 ec 0c             	sub    $0xc,%esp
c0104803:	ff 75 f0             	pushl  -0x10(%ebp)
c0104806:	e8 fb f8 ff ff       	call   c0104106 <page_ref>
c010480b:	83 c4 10             	add    $0x10,%esp
c010480e:	85 c0                	test   %eax,%eax
c0104810:	75 12                	jne    c0104824 <basic_check+0x10d>
c0104812:	83 ec 0c             	sub    $0xc,%esp
c0104815:	ff 75 f4             	pushl  -0xc(%ebp)
c0104818:	e8 e9 f8 ff ff       	call   c0104106 <page_ref>
c010481d:	83 c4 10             	add    $0x10,%esp
c0104820:	85 c0                	test   %eax,%eax
c0104822:	74 19                	je     c010483d <basic_check+0x126>
c0104824:	68 90 6a 10 c0       	push   $0xc0106a90
c0104829:	68 9e 69 10 c0       	push   $0xc010699e
c010482e:	68 dd 00 00 00       	push   $0xdd
c0104833:	68 b3 69 10 c0       	push   $0xc01069b3
c0104838:	e8 a6 bb ff ff       	call   c01003e3 <__panic>
	//转换为物理地址后都小于最大物理地址 896M
    assert(page2pa(p0) < npage * PGSIZE);
c010483d:	83 ec 0c             	sub    $0xc,%esp
c0104840:	ff 75 ec             	pushl  -0x14(%ebp)
c0104843:	e8 ab f8 ff ff       	call   c01040f3 <page2pa>
c0104848:	83 c4 10             	add    $0x10,%esp
c010484b:	89 c2                	mov    %eax,%edx
c010484d:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0104852:	c1 e0 0c             	shl    $0xc,%eax
c0104855:	39 c2                	cmp    %eax,%edx
c0104857:	72 19                	jb     c0104872 <basic_check+0x15b>
c0104859:	68 cc 6a 10 c0       	push   $0xc0106acc
c010485e:	68 9e 69 10 c0       	push   $0xc010699e
c0104863:	68 df 00 00 00       	push   $0xdf
c0104868:	68 b3 69 10 c0       	push   $0xc01069b3
c010486d:	e8 71 bb ff ff       	call   c01003e3 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
c0104872:	83 ec 0c             	sub    $0xc,%esp
c0104875:	ff 75 f0             	pushl  -0x10(%ebp)
c0104878:	e8 76 f8 ff ff       	call   c01040f3 <page2pa>
c010487d:	83 c4 10             	add    $0x10,%esp
c0104880:	89 c2                	mov    %eax,%edx
c0104882:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0104887:	c1 e0 0c             	shl    $0xc,%eax
c010488a:	39 c2                	cmp    %eax,%edx
c010488c:	72 19                	jb     c01048a7 <basic_check+0x190>
c010488e:	68 e9 6a 10 c0       	push   $0xc0106ae9
c0104893:	68 9e 69 10 c0       	push   $0xc010699e
c0104898:	68 e0 00 00 00       	push   $0xe0
c010489d:	68 b3 69 10 c0       	push   $0xc01069b3
c01048a2:	e8 3c bb ff ff       	call   c01003e3 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
c01048a7:	83 ec 0c             	sub    $0xc,%esp
c01048aa:	ff 75 f4             	pushl  -0xc(%ebp)
c01048ad:	e8 41 f8 ff ff       	call   c01040f3 <page2pa>
c01048b2:	83 c4 10             	add    $0x10,%esp
c01048b5:	89 c2                	mov    %eax,%edx
c01048b7:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01048bc:	c1 e0 0c             	shl    $0xc,%eax
c01048bf:	39 c2                	cmp    %eax,%edx
c01048c1:	72 19                	jb     c01048dc <basic_check+0x1c5>
c01048c3:	68 06 6b 10 c0       	push   $0xc0106b06
c01048c8:	68 9e 69 10 c0       	push   $0xc010699e
c01048cd:	68 e1 00 00 00       	push   $0xe1
c01048d2:	68 b3 69 10 c0       	push   $0xc01069b3
c01048d7:	e8 07 bb ff ff       	call   c01003e3 <__panic>

    list_entry_t free_list_store = free_list;
c01048dc:	a1 1c af 11 c0       	mov    0xc011af1c,%eax
c01048e1:	8b 15 20 af 11 c0    	mov    0xc011af20,%edx
c01048e7:	89 45 d0             	mov    %eax,-0x30(%ebp)
c01048ea:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c01048ed:	c7 45 e4 1c af 11 c0 	movl   $0xc011af1c,-0x1c(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c01048f4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01048f7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01048fa:	89 50 04             	mov    %edx,0x4(%eax)
c01048fd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104900:	8b 50 04             	mov    0x4(%eax),%edx
c0104903:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104906:	89 10                	mov    %edx,(%eax)
c0104908:	c7 45 d8 1c af 11 c0 	movl   $0xc011af1c,-0x28(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
c010490f:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104912:	8b 40 04             	mov    0x4(%eax),%eax
c0104915:	39 45 d8             	cmp    %eax,-0x28(%ebp)
c0104918:	0f 94 c0             	sete   %al
c010491b:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
c010491e:	85 c0                	test   %eax,%eax
c0104920:	75 19                	jne    c010493b <basic_check+0x224>
c0104922:	68 23 6b 10 c0       	push   $0xc0106b23
c0104927:	68 9e 69 10 c0       	push   $0xc010699e
c010492c:	68 e5 00 00 00       	push   $0xe5
c0104931:	68 b3 69 10 c0       	push   $0xc01069b3
c0104936:	e8 a8 ba ff ff       	call   c01003e3 <__panic>

    unsigned int nr_free_store = nr_free;
c010493b:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104940:	89 45 e0             	mov    %eax,-0x20(%ebp)
    nr_free = 0;
c0104943:	c7 05 24 af 11 c0 00 	movl   $0x0,0xc011af24
c010494a:	00 00 00 
	//检测当空页表为0时确认无法分配
    assert(alloc_page() == NULL);
c010494d:	83 ec 0c             	sub    $0xc,%esp
c0104950:	6a 01                	push   $0x1
c0104952:	e8 48 e3 ff ff       	call   c0102c9f <alloc_pages>
c0104957:	83 c4 10             	add    $0x10,%esp
c010495a:	85 c0                	test   %eax,%eax
c010495c:	74 19                	je     c0104977 <basic_check+0x260>
c010495e:	68 3a 6b 10 c0       	push   $0xc0106b3a
c0104963:	68 9e 69 10 c0       	push   $0xc010699e
c0104968:	68 ea 00 00 00       	push   $0xea
c010496d:	68 b3 69 10 c0       	push   $0xc01069b3
c0104972:	e8 6c ba ff ff       	call   c01003e3 <__panic>
	//释放三个页表并确认free操作正常
    free_page(p0);
c0104977:	83 ec 08             	sub    $0x8,%esp
c010497a:	6a 01                	push   $0x1
c010497c:	ff 75 ec             	pushl  -0x14(%ebp)
c010497f:	e8 59 e3 ff ff       	call   c0102cdd <free_pages>
c0104984:	83 c4 10             	add    $0x10,%esp
    free_page(p1);
c0104987:	83 ec 08             	sub    $0x8,%esp
c010498a:	6a 01                	push   $0x1
c010498c:	ff 75 f0             	pushl  -0x10(%ebp)
c010498f:	e8 49 e3 ff ff       	call   c0102cdd <free_pages>
c0104994:	83 c4 10             	add    $0x10,%esp
    free_page(p2);
c0104997:	83 ec 08             	sub    $0x8,%esp
c010499a:	6a 01                	push   $0x1
c010499c:	ff 75 f4             	pushl  -0xc(%ebp)
c010499f:	e8 39 e3 ff ff       	call   c0102cdd <free_pages>
c01049a4:	83 c4 10             	add    $0x10,%esp
    assert(nr_free == 3);
c01049a7:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c01049ac:	83 f8 03             	cmp    $0x3,%eax
c01049af:	74 19                	je     c01049ca <basic_check+0x2b3>
c01049b1:	68 4f 6b 10 c0       	push   $0xc0106b4f
c01049b6:	68 9e 69 10 c0       	push   $0xc010699e
c01049bb:	68 ef 00 00 00       	push   $0xef
c01049c0:	68 b3 69 10 c0       	push   $0xc01069b3
c01049c5:	e8 19 ba ff ff       	call   c01003e3 <__panic>
	//释放后可再正常分配
    assert((p0 = alloc_page()) != NULL);
c01049ca:	83 ec 0c             	sub    $0xc,%esp
c01049cd:	6a 01                	push   $0x1
c01049cf:	e8 cb e2 ff ff       	call   c0102c9f <alloc_pages>
c01049d4:	83 c4 10             	add    $0x10,%esp
c01049d7:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01049da:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c01049de:	75 19                	jne    c01049f9 <basic_check+0x2e2>
c01049e0:	68 18 6a 10 c0       	push   $0xc0106a18
c01049e5:	68 9e 69 10 c0       	push   $0xc010699e
c01049ea:	68 f1 00 00 00       	push   $0xf1
c01049ef:	68 b3 69 10 c0       	push   $0xc01069b3
c01049f4:	e8 ea b9 ff ff       	call   c01003e3 <__panic>
    assert((p1 = alloc_page()) != NULL);
c01049f9:	83 ec 0c             	sub    $0xc,%esp
c01049fc:	6a 01                	push   $0x1
c01049fe:	e8 9c e2 ff ff       	call   c0102c9f <alloc_pages>
c0104a03:	83 c4 10             	add    $0x10,%esp
c0104a06:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0104a09:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0104a0d:	75 19                	jne    c0104a28 <basic_check+0x311>
c0104a0f:	68 34 6a 10 c0       	push   $0xc0106a34
c0104a14:	68 9e 69 10 c0       	push   $0xc010699e
c0104a19:	68 f2 00 00 00       	push   $0xf2
c0104a1e:	68 b3 69 10 c0       	push   $0xc01069b3
c0104a23:	e8 bb b9 ff ff       	call   c01003e3 <__panic>
    assert((p2 = alloc_page()) != NULL);
c0104a28:	83 ec 0c             	sub    $0xc,%esp
c0104a2b:	6a 01                	push   $0x1
c0104a2d:	e8 6d e2 ff ff       	call   c0102c9f <alloc_pages>
c0104a32:	83 c4 10             	add    $0x10,%esp
c0104a35:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0104a38:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0104a3c:	75 19                	jne    c0104a57 <basic_check+0x340>
c0104a3e:	68 50 6a 10 c0       	push   $0xc0106a50
c0104a43:	68 9e 69 10 c0       	push   $0xc010699e
c0104a48:	68 f3 00 00 00       	push   $0xf3
c0104a4d:	68 b3 69 10 c0       	push   $0xc01069b3
c0104a52:	e8 8c b9 ff ff       	call   c01003e3 <__panic>
	//再次分配失败
    assert(alloc_page() == NULL);
c0104a57:	83 ec 0c             	sub    $0xc,%esp
c0104a5a:	6a 01                	push   $0x1
c0104a5c:	e8 3e e2 ff ff       	call   c0102c9f <alloc_pages>
c0104a61:	83 c4 10             	add    $0x10,%esp
c0104a64:	85 c0                	test   %eax,%eax
c0104a66:	74 19                	je     c0104a81 <basic_check+0x36a>
c0104a68:	68 3a 6b 10 c0       	push   $0xc0106b3a
c0104a6d:	68 9e 69 10 c0       	push   $0xc010699e
c0104a72:	68 f5 00 00 00       	push   $0xf5
c0104a77:	68 b3 69 10 c0       	push   $0xc01069b3
c0104a7c:	e8 62 b9 ff ff       	call   c01003e3 <__panic>
	//分配后链表不为空
    free_page(p0);
c0104a81:	83 ec 08             	sub    $0x8,%esp
c0104a84:	6a 01                	push   $0x1
c0104a86:	ff 75 ec             	pushl  -0x14(%ebp)
c0104a89:	e8 4f e2 ff ff       	call   c0102cdd <free_pages>
c0104a8e:	83 c4 10             	add    $0x10,%esp
c0104a91:	c7 45 e8 1c af 11 c0 	movl   $0xc011af1c,-0x18(%ebp)
c0104a98:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0104a9b:	8b 40 04             	mov    0x4(%eax),%eax
c0104a9e:	39 45 e8             	cmp    %eax,-0x18(%ebp)
c0104aa1:	0f 94 c0             	sete   %al
c0104aa4:	0f b6 c0             	movzbl %al,%eax
    assert(!list_empty(&free_list));
c0104aa7:	85 c0                	test   %eax,%eax
c0104aa9:	74 19                	je     c0104ac4 <basic_check+0x3ad>
c0104aab:	68 5c 6b 10 c0       	push   $0xc0106b5c
c0104ab0:	68 9e 69 10 c0       	push   $0xc010699e
c0104ab5:	68 f8 00 00 00       	push   $0xf8
c0104aba:	68 b3 69 10 c0       	push   $0xc01069b3
c0104abf:	e8 1f b9 ff ff       	call   c01003e3 <__panic>
	
    struct Page *p;
    assert((p = alloc_page()) == p0);
c0104ac4:	83 ec 0c             	sub    $0xc,%esp
c0104ac7:	6a 01                	push   $0x1
c0104ac9:	e8 d1 e1 ff ff       	call   c0102c9f <alloc_pages>
c0104ace:	83 c4 10             	add    $0x10,%esp
c0104ad1:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104ad4:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104ad7:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c0104ada:	74 19                	je     c0104af5 <basic_check+0x3de>
c0104adc:	68 74 6b 10 c0       	push   $0xc0106b74
c0104ae1:	68 9e 69 10 c0       	push   $0xc010699e
c0104ae6:	68 fb 00 00 00       	push   $0xfb
c0104aeb:	68 b3 69 10 c0       	push   $0xc01069b3
c0104af0:	e8 ee b8 ff ff       	call   c01003e3 <__panic>
    assert(alloc_page() == NULL);
c0104af5:	83 ec 0c             	sub    $0xc,%esp
c0104af8:	6a 01                	push   $0x1
c0104afa:	e8 a0 e1 ff ff       	call   c0102c9f <alloc_pages>
c0104aff:	83 c4 10             	add    $0x10,%esp
c0104b02:	85 c0                	test   %eax,%eax
c0104b04:	74 19                	je     c0104b1f <basic_check+0x408>
c0104b06:	68 3a 6b 10 c0       	push   $0xc0106b3a
c0104b0b:	68 9e 69 10 c0       	push   $0xc010699e
c0104b10:	68 fc 00 00 00       	push   $0xfc
c0104b15:	68 b3 69 10 c0       	push   $0xc01069b3
c0104b1a:	e8 c4 b8 ff ff       	call   c01003e3 <__panic>

    assert(nr_free == 0);
c0104b1f:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104b24:	85 c0                	test   %eax,%eax
c0104b26:	74 19                	je     c0104b41 <basic_check+0x42a>
c0104b28:	68 8d 6b 10 c0       	push   $0xc0106b8d
c0104b2d:	68 9e 69 10 c0       	push   $0xc010699e
c0104b32:	68 fe 00 00 00       	push   $0xfe
c0104b37:	68 b3 69 10 c0       	push   $0xc01069b3
c0104b3c:	e8 a2 b8 ff ff       	call   c01003e3 <__panic>
    free_list = free_list_store;
c0104b41:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104b44:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104b47:	a3 1c af 11 c0       	mov    %eax,0xc011af1c
c0104b4c:	89 15 20 af 11 c0    	mov    %edx,0xc011af20
    nr_free = nr_free_store;
c0104b52:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0104b55:	a3 24 af 11 c0       	mov    %eax,0xc011af24

    free_page(p);
c0104b5a:	83 ec 08             	sub    $0x8,%esp
c0104b5d:	6a 01                	push   $0x1
c0104b5f:	ff 75 dc             	pushl  -0x24(%ebp)
c0104b62:	e8 76 e1 ff ff       	call   c0102cdd <free_pages>
c0104b67:	83 c4 10             	add    $0x10,%esp
    free_page(p1);
c0104b6a:	83 ec 08             	sub    $0x8,%esp
c0104b6d:	6a 01                	push   $0x1
c0104b6f:	ff 75 f0             	pushl  -0x10(%ebp)
c0104b72:	e8 66 e1 ff ff       	call   c0102cdd <free_pages>
c0104b77:	83 c4 10             	add    $0x10,%esp
    free_page(p2);
c0104b7a:	83 ec 08             	sub    $0x8,%esp
c0104b7d:	6a 01                	push   $0x1
c0104b7f:	ff 75 f4             	pushl  -0xc(%ebp)
c0104b82:	e8 56 e1 ff ff       	call   c0102cdd <free_pages>
c0104b87:	83 c4 10             	add    $0x10,%esp
}
c0104b8a:	90                   	nop
c0104b8b:	c9                   	leave  
c0104b8c:	c3                   	ret    

c0104b8d <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
c0104b8d:	55                   	push   %ebp
c0104b8e:	89 e5                	mov    %esp,%ebp
c0104b90:	81 ec 88 00 00 00    	sub    $0x88,%esp
    int count = 0, total = 0;
c0104b96:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0104b9d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    list_entry_t *le = &free_list;
c0104ba4:	c7 45 ec 1c af 11 c0 	movl   $0xc011af1c,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
c0104bab:	eb 60                	jmp    c0104c0d <default_check+0x80>
        struct Page *p = le2page(le, page_link);
c0104bad:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104bb0:	83 e8 0c             	sub    $0xc,%eax
c0104bb3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        assert(PageProperty(p));
c0104bb6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104bb9:	83 c0 04             	add    $0x4,%eax
c0104bbc:	c7 45 b0 01 00 00 00 	movl   $0x1,-0x50(%ebp)
c0104bc3:	89 45 ac             	mov    %eax,-0x54(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104bc6:	8b 45 ac             	mov    -0x54(%ebp),%eax
c0104bc9:	8b 55 b0             	mov    -0x50(%ebp),%edx
c0104bcc:	0f a3 10             	bt     %edx,(%eax)
c0104bcf:	19 c0                	sbb    %eax,%eax
c0104bd1:	89 45 a8             	mov    %eax,-0x58(%ebp)
    return oldbit != 0;
c0104bd4:	83 7d a8 00          	cmpl   $0x0,-0x58(%ebp)
c0104bd8:	0f 95 c0             	setne  %al
c0104bdb:	0f b6 c0             	movzbl %al,%eax
c0104bde:	85 c0                	test   %eax,%eax
c0104be0:	75 19                	jne    c0104bfb <default_check+0x6e>
c0104be2:	68 9a 6b 10 c0       	push   $0xc0106b9a
c0104be7:	68 9e 69 10 c0       	push   $0xc010699e
c0104bec:	68 0f 01 00 00       	push   $0x10f
c0104bf1:	68 b3 69 10 c0       	push   $0xc01069b3
c0104bf6:	e8 e8 b7 ff ff       	call   c01003e3 <__panic>
        count ++, total += p->property;
c0104bfb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0104bff:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104c02:	8b 50 08             	mov    0x8(%eax),%edx
c0104c05:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104c08:	01 d0                	add    %edx,%eax
c0104c0a:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0104c0d:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104c10:	89 45 e0             	mov    %eax,-0x20(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0104c13:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0104c16:	8b 40 04             	mov    0x4(%eax),%eax
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
c0104c19:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0104c1c:	81 7d ec 1c af 11 c0 	cmpl   $0xc011af1c,-0x14(%ebp)
c0104c23:	75 88                	jne    c0104bad <default_check+0x20>
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages()); //以上检查首页标记
c0104c25:	e8 e8 e0 ff ff       	call   c0102d12 <nr_free_pages>
c0104c2a:	89 c2                	mov    %eax,%edx
c0104c2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104c2f:	39 c2                	cmp    %eax,%edx
c0104c31:	74 19                	je     c0104c4c <default_check+0xbf>
c0104c33:	68 aa 6b 10 c0       	push   $0xc0106baa
c0104c38:	68 9e 69 10 c0       	push   $0xc010699e
c0104c3d:	68 12 01 00 00       	push   $0x112
c0104c42:	68 b3 69 10 c0       	push   $0xc01069b3
c0104c47:	e8 97 b7 ff ff       	call   c01003e3 <__panic>

    basic_check();//对页表分配释放等基本操作的一系列检查
c0104c4c:	e8 c6 fa ff ff       	call   c0104717 <basic_check>

	//可以分配五个连续页表，并且头部标记清零
    struct Page *p0 = alloc_pages(5), *p1, *p2;
c0104c51:	83 ec 0c             	sub    $0xc,%esp
c0104c54:	6a 05                	push   $0x5
c0104c56:	e8 44 e0 ff ff       	call   c0102c9f <alloc_pages>
c0104c5b:	83 c4 10             	add    $0x10,%esp
c0104c5e:	89 45 dc             	mov    %eax,-0x24(%ebp)
    assert(p0 != NULL);
c0104c61:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c0104c65:	75 19                	jne    c0104c80 <default_check+0xf3>
c0104c67:	68 c3 6b 10 c0       	push   $0xc0106bc3
c0104c6c:	68 9e 69 10 c0       	push   $0xc010699e
c0104c71:	68 18 01 00 00       	push   $0x118
c0104c76:	68 b3 69 10 c0       	push   $0xc01069b3
c0104c7b:	e8 63 b7 ff ff       	call   c01003e3 <__panic>
    assert(!PageProperty(p0));
c0104c80:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104c83:	83 c0 04             	add    $0x4,%eax
c0104c86:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
c0104c8d:	89 45 a4             	mov    %eax,-0x5c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104c90:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0104c93:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0104c96:	0f a3 10             	bt     %edx,(%eax)
c0104c99:	19 c0                	sbb    %eax,%eax
c0104c9b:	89 45 a0             	mov    %eax,-0x60(%ebp)
    return oldbit != 0;
c0104c9e:	83 7d a0 00          	cmpl   $0x0,-0x60(%ebp)
c0104ca2:	0f 95 c0             	setne  %al
c0104ca5:	0f b6 c0             	movzbl %al,%eax
c0104ca8:	85 c0                	test   %eax,%eax
c0104caa:	74 19                	je     c0104cc5 <default_check+0x138>
c0104cac:	68 ce 6b 10 c0       	push   $0xc0106bce
c0104cb1:	68 9e 69 10 c0       	push   $0xc010699e
c0104cb6:	68 19 01 00 00       	push   $0x119
c0104cbb:	68 b3 69 10 c0       	push   $0xc01069b3
c0104cc0:	e8 1e b7 ff ff       	call   c01003e3 <__panic>

    list_entry_t free_list_store = free_list;
c0104cc5:	a1 1c af 11 c0       	mov    0xc011af1c,%eax
c0104cca:	8b 15 20 af 11 c0    	mov    0xc011af20,%edx
c0104cd0:	89 45 80             	mov    %eax,-0x80(%ebp)
c0104cd3:	89 55 84             	mov    %edx,-0x7c(%ebp)
c0104cd6:	c7 45 d0 1c af 11 c0 	movl   $0xc011af1c,-0x30(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c0104cdd:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104ce0:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0104ce3:	89 50 04             	mov    %edx,0x4(%eax)
c0104ce6:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104ce9:	8b 50 04             	mov    0x4(%eax),%edx
c0104cec:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104cef:	89 10                	mov    %edx,(%eax)
c0104cf1:	c7 45 d8 1c af 11 c0 	movl   $0xc011af1c,-0x28(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
c0104cf8:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104cfb:	8b 40 04             	mov    0x4(%eax),%eax
c0104cfe:	39 45 d8             	cmp    %eax,-0x28(%ebp)
c0104d01:	0f 94 c0             	sete   %al
c0104d04:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
c0104d07:	85 c0                	test   %eax,%eax
c0104d09:	75 19                	jne    c0104d24 <default_check+0x197>
c0104d0b:	68 23 6b 10 c0       	push   $0xc0106b23
c0104d10:	68 9e 69 10 c0       	push   $0xc010699e
c0104d15:	68 1d 01 00 00       	push   $0x11d
c0104d1a:	68 b3 69 10 c0       	push   $0xc01069b3
c0104d1f:	e8 bf b6 ff ff       	call   c01003e3 <__panic>
    assert(alloc_page() == NULL);
c0104d24:	83 ec 0c             	sub    $0xc,%esp
c0104d27:	6a 01                	push   $0x1
c0104d29:	e8 71 df ff ff       	call   c0102c9f <alloc_pages>
c0104d2e:	83 c4 10             	add    $0x10,%esp
c0104d31:	85 c0                	test   %eax,%eax
c0104d33:	74 19                	je     c0104d4e <default_check+0x1c1>
c0104d35:	68 3a 6b 10 c0       	push   $0xc0106b3a
c0104d3a:	68 9e 69 10 c0       	push   $0xc010699e
c0104d3f:	68 1e 01 00 00       	push   $0x11e
c0104d44:	68 b3 69 10 c0       	push   $0xc01069b3
c0104d49:	e8 95 b6 ff ff       	call   c01003e3 <__panic>

    unsigned int nr_free_store = nr_free;
c0104d4e:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104d53:	89 45 cc             	mov    %eax,-0x34(%ebp)
    nr_free = 0;
c0104d56:	c7 05 24 af 11 c0 00 	movl   $0x0,0xc011af24
c0104d5d:	00 00 00 

    free_pages(p0 + 2, 3);
c0104d60:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104d63:	83 c0 28             	add    $0x28,%eax
c0104d66:	83 ec 08             	sub    $0x8,%esp
c0104d69:	6a 03                	push   $0x3
c0104d6b:	50                   	push   %eax
c0104d6c:	e8 6c df ff ff       	call   c0102cdd <free_pages>
c0104d71:	83 c4 10             	add    $0x10,%esp
    assert(alloc_pages(4) == NULL);
c0104d74:	83 ec 0c             	sub    $0xc,%esp
c0104d77:	6a 04                	push   $0x4
c0104d79:	e8 21 df ff ff       	call   c0102c9f <alloc_pages>
c0104d7e:	83 c4 10             	add    $0x10,%esp
c0104d81:	85 c0                	test   %eax,%eax
c0104d83:	74 19                	je     c0104d9e <default_check+0x211>
c0104d85:	68 e0 6b 10 c0       	push   $0xc0106be0
c0104d8a:	68 9e 69 10 c0       	push   $0xc010699e
c0104d8f:	68 24 01 00 00       	push   $0x124
c0104d94:	68 b3 69 10 c0       	push   $0xc01069b3
c0104d99:	e8 45 b6 ff ff       	call   c01003e3 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
c0104d9e:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104da1:	83 c0 28             	add    $0x28,%eax
c0104da4:	83 c0 04             	add    $0x4,%eax
c0104da7:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
c0104dae:	89 45 9c             	mov    %eax,-0x64(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104db1:	8b 45 9c             	mov    -0x64(%ebp),%eax
c0104db4:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104db7:	0f a3 10             	bt     %edx,(%eax)
c0104dba:	19 c0                	sbb    %eax,%eax
c0104dbc:	89 45 98             	mov    %eax,-0x68(%ebp)
    return oldbit != 0;
c0104dbf:	83 7d 98 00          	cmpl   $0x0,-0x68(%ebp)
c0104dc3:	0f 95 c0             	setne  %al
c0104dc6:	0f b6 c0             	movzbl %al,%eax
c0104dc9:	85 c0                	test   %eax,%eax
c0104dcb:	74 0e                	je     c0104ddb <default_check+0x24e>
c0104dcd:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104dd0:	83 c0 28             	add    $0x28,%eax
c0104dd3:	8b 40 08             	mov    0x8(%eax),%eax
c0104dd6:	83 f8 03             	cmp    $0x3,%eax
c0104dd9:	74 19                	je     c0104df4 <default_check+0x267>
c0104ddb:	68 f8 6b 10 c0       	push   $0xc0106bf8
c0104de0:	68 9e 69 10 c0       	push   $0xc010699e
c0104de5:	68 25 01 00 00       	push   $0x125
c0104dea:	68 b3 69 10 c0       	push   $0xc01069b3
c0104def:	e8 ef b5 ff ff       	call   c01003e3 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
c0104df4:	83 ec 0c             	sub    $0xc,%esp
c0104df7:	6a 03                	push   $0x3
c0104df9:	e8 a1 de ff ff       	call   c0102c9f <alloc_pages>
c0104dfe:	83 c4 10             	add    $0x10,%esp
c0104e01:	89 45 c4             	mov    %eax,-0x3c(%ebp)
c0104e04:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
c0104e08:	75 19                	jne    c0104e23 <default_check+0x296>
c0104e0a:	68 24 6c 10 c0       	push   $0xc0106c24
c0104e0f:	68 9e 69 10 c0       	push   $0xc010699e
c0104e14:	68 26 01 00 00       	push   $0x126
c0104e19:	68 b3 69 10 c0       	push   $0xc01069b3
c0104e1e:	e8 c0 b5 ff ff       	call   c01003e3 <__panic>
    assert(alloc_page() == NULL);
c0104e23:	83 ec 0c             	sub    $0xc,%esp
c0104e26:	6a 01                	push   $0x1
c0104e28:	e8 72 de ff ff       	call   c0102c9f <alloc_pages>
c0104e2d:	83 c4 10             	add    $0x10,%esp
c0104e30:	85 c0                	test   %eax,%eax
c0104e32:	74 19                	je     c0104e4d <default_check+0x2c0>
c0104e34:	68 3a 6b 10 c0       	push   $0xc0106b3a
c0104e39:	68 9e 69 10 c0       	push   $0xc010699e
c0104e3e:	68 27 01 00 00       	push   $0x127
c0104e43:	68 b3 69 10 c0       	push   $0xc01069b3
c0104e48:	e8 96 b5 ff ff       	call   c01003e3 <__panic>
    assert(p0 + 2 == p1);
c0104e4d:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104e50:	83 c0 28             	add    $0x28,%eax
c0104e53:	3b 45 c4             	cmp    -0x3c(%ebp),%eax
c0104e56:	74 19                	je     c0104e71 <default_check+0x2e4>
c0104e58:	68 42 6c 10 c0       	push   $0xc0106c42
c0104e5d:	68 9e 69 10 c0       	push   $0xc010699e
c0104e62:	68 28 01 00 00       	push   $0x128
c0104e67:	68 b3 69 10 c0       	push   $0xc01069b3
c0104e6c:	e8 72 b5 ff ff       	call   c01003e3 <__panic>

    p2 = p0 + 1;
c0104e71:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104e74:	83 c0 14             	add    $0x14,%eax
c0104e77:	89 45 c0             	mov    %eax,-0x40(%ebp)
    free_page(p0);//默认释放1个
c0104e7a:	83 ec 08             	sub    $0x8,%esp
c0104e7d:	6a 01                	push   $0x1
c0104e7f:	ff 75 dc             	pushl  -0x24(%ebp)
c0104e82:	e8 56 de ff ff       	call   c0102cdd <free_pages>
c0104e87:	83 c4 10             	add    $0x10,%esp
    free_pages(p1, 3);
c0104e8a:	83 ec 08             	sub    $0x8,%esp
c0104e8d:	6a 03                	push   $0x3
c0104e8f:	ff 75 c4             	pushl  -0x3c(%ebp)
c0104e92:	e8 46 de ff ff       	call   c0102cdd <free_pages>
c0104e97:	83 c4 10             	add    $0x10,%esp
    assert(PageProperty(p0) && p0->property == 1);
c0104e9a:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104e9d:	83 c0 04             	add    $0x4,%eax
c0104ea0:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
c0104ea7:	89 45 94             	mov    %eax,-0x6c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104eaa:	8b 45 94             	mov    -0x6c(%ebp),%eax
c0104ead:	8b 55 c8             	mov    -0x38(%ebp),%edx
c0104eb0:	0f a3 10             	bt     %edx,(%eax)
c0104eb3:	19 c0                	sbb    %eax,%eax
c0104eb5:	89 45 90             	mov    %eax,-0x70(%ebp)
    return oldbit != 0;
c0104eb8:	83 7d 90 00          	cmpl   $0x0,-0x70(%ebp)
c0104ebc:	0f 95 c0             	setne  %al
c0104ebf:	0f b6 c0             	movzbl %al,%eax
c0104ec2:	85 c0                	test   %eax,%eax
c0104ec4:	74 0b                	je     c0104ed1 <default_check+0x344>
c0104ec6:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104ec9:	8b 40 08             	mov    0x8(%eax),%eax
c0104ecc:	83 f8 01             	cmp    $0x1,%eax
c0104ecf:	74 19                	je     c0104eea <default_check+0x35d>
c0104ed1:	68 50 6c 10 c0       	push   $0xc0106c50
c0104ed6:	68 9e 69 10 c0       	push   $0xc010699e
c0104edb:	68 2d 01 00 00       	push   $0x12d
c0104ee0:	68 b3 69 10 c0       	push   $0xc01069b3
c0104ee5:	e8 f9 b4 ff ff       	call   c01003e3 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
c0104eea:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104eed:	83 c0 04             	add    $0x4,%eax
c0104ef0:	c7 45 bc 01 00 00 00 	movl   $0x1,-0x44(%ebp)
c0104ef7:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104efa:	8b 45 8c             	mov    -0x74(%ebp),%eax
c0104efd:	8b 55 bc             	mov    -0x44(%ebp),%edx
c0104f00:	0f a3 10             	bt     %edx,(%eax)
c0104f03:	19 c0                	sbb    %eax,%eax
c0104f05:	89 45 88             	mov    %eax,-0x78(%ebp)
    return oldbit != 0;
c0104f08:	83 7d 88 00          	cmpl   $0x0,-0x78(%ebp)
c0104f0c:	0f 95 c0             	setne  %al
c0104f0f:	0f b6 c0             	movzbl %al,%eax
c0104f12:	85 c0                	test   %eax,%eax
c0104f14:	74 0b                	je     c0104f21 <default_check+0x394>
c0104f16:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104f19:	8b 40 08             	mov    0x8(%eax),%eax
c0104f1c:	83 f8 03             	cmp    $0x3,%eax
c0104f1f:	74 19                	je     c0104f3a <default_check+0x3ad>
c0104f21:	68 78 6c 10 c0       	push   $0xc0106c78
c0104f26:	68 9e 69 10 c0       	push   $0xc010699e
c0104f2b:	68 2e 01 00 00       	push   $0x12e
c0104f30:	68 b3 69 10 c0       	push   $0xc01069b3
c0104f35:	e8 a9 b4 ff ff       	call   c01003e3 <__panic>
	//对空闲页表按照地址从小到大排列的检测
    assert((p0 = alloc_page()) == p2 - 1);
c0104f3a:	83 ec 0c             	sub    $0xc,%esp
c0104f3d:	6a 01                	push   $0x1
c0104f3f:	e8 5b dd ff ff       	call   c0102c9f <alloc_pages>
c0104f44:	83 c4 10             	add    $0x10,%esp
c0104f47:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104f4a:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0104f4d:	83 e8 14             	sub    $0x14,%eax
c0104f50:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c0104f53:	74 19                	je     c0104f6e <default_check+0x3e1>
c0104f55:	68 9e 6c 10 c0       	push   $0xc0106c9e
c0104f5a:	68 9e 69 10 c0       	push   $0xc010699e
c0104f5f:	68 30 01 00 00       	push   $0x130
c0104f64:	68 b3 69 10 c0       	push   $0xc01069b3
c0104f69:	e8 75 b4 ff ff       	call   c01003e3 <__panic>
    free_page(p0);
c0104f6e:	83 ec 08             	sub    $0x8,%esp
c0104f71:	6a 01                	push   $0x1
c0104f73:	ff 75 dc             	pushl  -0x24(%ebp)
c0104f76:	e8 62 dd ff ff       	call   c0102cdd <free_pages>
c0104f7b:	83 c4 10             	add    $0x10,%esp
    assert((p0 = alloc_pages(2)) == p2 + 1);
c0104f7e:	83 ec 0c             	sub    $0xc,%esp
c0104f81:	6a 02                	push   $0x2
c0104f83:	e8 17 dd ff ff       	call   c0102c9f <alloc_pages>
c0104f88:	83 c4 10             	add    $0x10,%esp
c0104f8b:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104f8e:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0104f91:	83 c0 14             	add    $0x14,%eax
c0104f94:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c0104f97:	74 19                	je     c0104fb2 <default_check+0x425>
c0104f99:	68 bc 6c 10 c0       	push   $0xc0106cbc
c0104f9e:	68 9e 69 10 c0       	push   $0xc010699e
c0104fa3:	68 32 01 00 00       	push   $0x132
c0104fa8:	68 b3 69 10 c0       	push   $0xc01069b3
c0104fad:	e8 31 b4 ff ff       	call   c01003e3 <__panic>

    free_pages(p0, 2);
c0104fb2:	83 ec 08             	sub    $0x8,%esp
c0104fb5:	6a 02                	push   $0x2
c0104fb7:	ff 75 dc             	pushl  -0x24(%ebp)
c0104fba:	e8 1e dd ff ff       	call   c0102cdd <free_pages>
c0104fbf:	83 c4 10             	add    $0x10,%esp
    free_page(p2);
c0104fc2:	83 ec 08             	sub    $0x8,%esp
c0104fc5:	6a 01                	push   $0x1
c0104fc7:	ff 75 c0             	pushl  -0x40(%ebp)
c0104fca:	e8 0e dd ff ff       	call   c0102cdd <free_pages>
c0104fcf:	83 c4 10             	add    $0x10,%esp
	//检查页表合并
    assert((p0 = alloc_pages(5)) != NULL);
c0104fd2:	83 ec 0c             	sub    $0xc,%esp
c0104fd5:	6a 05                	push   $0x5
c0104fd7:	e8 c3 dc ff ff       	call   c0102c9f <alloc_pages>
c0104fdc:	83 c4 10             	add    $0x10,%esp
c0104fdf:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104fe2:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c0104fe6:	75 19                	jne    c0105001 <default_check+0x474>
c0104fe8:	68 dc 6c 10 c0       	push   $0xc0106cdc
c0104fed:	68 9e 69 10 c0       	push   $0xc010699e
c0104ff2:	68 37 01 00 00       	push   $0x137
c0104ff7:	68 b3 69 10 c0       	push   $0xc01069b3
c0104ffc:	e8 e2 b3 ff ff       	call   c01003e3 <__panic>
    assert(alloc_page() == NULL);
c0105001:	83 ec 0c             	sub    $0xc,%esp
c0105004:	6a 01                	push   $0x1
c0105006:	e8 94 dc ff ff       	call   c0102c9f <alloc_pages>
c010500b:	83 c4 10             	add    $0x10,%esp
c010500e:	85 c0                	test   %eax,%eax
c0105010:	74 19                	je     c010502b <default_check+0x49e>
c0105012:	68 3a 6b 10 c0       	push   $0xc0106b3a
c0105017:	68 9e 69 10 c0       	push   $0xc010699e
c010501c:	68 38 01 00 00       	push   $0x138
c0105021:	68 b3 69 10 c0       	push   $0xc01069b3
c0105026:	e8 b8 b3 ff ff       	call   c01003e3 <__panic>

    assert(nr_free == 0);
c010502b:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0105030:	85 c0                	test   %eax,%eax
c0105032:	74 19                	je     c010504d <default_check+0x4c0>
c0105034:	68 8d 6b 10 c0       	push   $0xc0106b8d
c0105039:	68 9e 69 10 c0       	push   $0xc010699e
c010503e:	68 3a 01 00 00       	push   $0x13a
c0105043:	68 b3 69 10 c0       	push   $0xc01069b3
c0105048:	e8 96 b3 ff ff       	call   c01003e3 <__panic>
    nr_free = nr_free_store;
c010504d:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0105050:	a3 24 af 11 c0       	mov    %eax,0xc011af24

    free_list = free_list_store;
c0105055:	8b 45 80             	mov    -0x80(%ebp),%eax
c0105058:	8b 55 84             	mov    -0x7c(%ebp),%edx
c010505b:	a3 1c af 11 c0       	mov    %eax,0xc011af1c
c0105060:	89 15 20 af 11 c0    	mov    %edx,0xc011af20
    free_pages(p0, 5);
c0105066:	83 ec 08             	sub    $0x8,%esp
c0105069:	6a 05                	push   $0x5
c010506b:	ff 75 dc             	pushl  -0x24(%ebp)
c010506e:	e8 6a dc ff ff       	call   c0102cdd <free_pages>
c0105073:	83 c4 10             	add    $0x10,%esp

    le = &free_list;
c0105076:	c7 45 ec 1c af 11 c0 	movl   $0xc011af1c,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
c010507d:	eb 50                	jmp    c01050cf <default_check+0x542>
        assert(le->next->prev == le && le->prev->next == le);//对指针的检查
c010507f:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105082:	8b 40 04             	mov    0x4(%eax),%eax
c0105085:	8b 00                	mov    (%eax),%eax
c0105087:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c010508a:	75 0d                	jne    c0105099 <default_check+0x50c>
c010508c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010508f:	8b 00                	mov    (%eax),%eax
c0105091:	8b 40 04             	mov    0x4(%eax),%eax
c0105094:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c0105097:	74 19                	je     c01050b2 <default_check+0x525>
c0105099:	68 fc 6c 10 c0       	push   $0xc0106cfc
c010509e:	68 9e 69 10 c0       	push   $0xc010699e
c01050a3:	68 42 01 00 00       	push   $0x142
c01050a8:	68 b3 69 10 c0       	push   $0xc01069b3
c01050ad:	e8 31 b3 ff ff       	call   c01003e3 <__panic>
        struct Page *p = le2page(le, page_link);
c01050b2:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01050b5:	83 e8 0c             	sub    $0xc,%eax
c01050b8:	89 45 b4             	mov    %eax,-0x4c(%ebp)
        count --, total -= p->property;
c01050bb:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
c01050bf:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01050c2:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c01050c5:	8b 40 08             	mov    0x8(%eax),%eax
c01050c8:	29 c2                	sub    %eax,%edx
c01050ca:	89 d0                	mov    %edx,%eax
c01050cc:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01050cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01050d2:	89 45 b8             	mov    %eax,-0x48(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c01050d5:	8b 45 b8             	mov    -0x48(%ebp),%eax
c01050d8:	8b 40 04             	mov    0x4(%eax),%eax

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
c01050db:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01050de:	81 7d ec 1c af 11 c0 	cmpl   $0xc011af1c,-0x14(%ebp)
c01050e5:	75 98                	jne    c010507f <default_check+0x4f2>
        assert(le->next->prev == le && le->prev->next == le);//对指针的检查
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
	//对空快与空页表总数的检查
    assert(count == 0);
c01050e7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01050eb:	74 19                	je     c0105106 <default_check+0x579>
c01050ed:	68 29 6d 10 c0       	push   $0xc0106d29
c01050f2:	68 9e 69 10 c0       	push   $0xc010699e
c01050f7:	68 47 01 00 00       	push   $0x147
c01050fc:	68 b3 69 10 c0       	push   $0xc01069b3
c0105101:	e8 dd b2 ff ff       	call   c01003e3 <__panic>
    assert(total == 0);
c0105106:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c010510a:	74 19                	je     c0105125 <default_check+0x598>
c010510c:	68 34 6d 10 c0       	push   $0xc0106d34
c0105111:	68 9e 69 10 c0       	push   $0xc010699e
c0105116:	68 48 01 00 00       	push   $0x148
c010511b:	68 b3 69 10 c0       	push   $0xc01069b3
c0105120:	e8 be b2 ff ff       	call   c01003e3 <__panic>
}
c0105125:	90                   	nop
c0105126:	c9                   	leave  
c0105127:	c3                   	ret    

c0105128 <strlen>:
 * @s:      the input string
 *
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
c0105128:	55                   	push   %ebp
c0105129:	89 e5                	mov    %esp,%ebp
c010512b:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
c010512e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (*s ++ != '\0') {
c0105135:	eb 04                	jmp    c010513b <strlen+0x13>
        cnt ++;
c0105137:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
c010513b:	8b 45 08             	mov    0x8(%ebp),%eax
c010513e:	8d 50 01             	lea    0x1(%eax),%edx
c0105141:	89 55 08             	mov    %edx,0x8(%ebp)
c0105144:	0f b6 00             	movzbl (%eax),%eax
c0105147:	84 c0                	test   %al,%al
c0105149:	75 ec                	jne    c0105137 <strlen+0xf>
        cnt ++;
    }
    return cnt;
c010514b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c010514e:	c9                   	leave  
c010514f:	c3                   	ret    

c0105150 <strnlen>:
 * The return value is strlen(s), if that is less than @len, or
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
c0105150:	55                   	push   %ebp
c0105151:	89 e5                	mov    %esp,%ebp
c0105153:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
c0105156:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (cnt < len && *s ++ != '\0') {
c010515d:	eb 04                	jmp    c0105163 <strnlen+0x13>
        cnt ++;
c010515f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
c0105163:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0105166:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0105169:	73 10                	jae    c010517b <strnlen+0x2b>
c010516b:	8b 45 08             	mov    0x8(%ebp),%eax
c010516e:	8d 50 01             	lea    0x1(%eax),%edx
c0105171:	89 55 08             	mov    %edx,0x8(%ebp)
c0105174:	0f b6 00             	movzbl (%eax),%eax
c0105177:	84 c0                	test   %al,%al
c0105179:	75 e4                	jne    c010515f <strnlen+0xf>
        cnt ++;
    }
    return cnt;
c010517b:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c010517e:	c9                   	leave  
c010517f:	c3                   	ret    

c0105180 <strcpy>:
 * To avoid overflows, the size of array pointed by @dst should be long enough to
 * contain the same string as @src (including the terminating null character), and
 * should not overlap in memory with @src.
 * */
char *
strcpy(char *dst, const char *src) {
c0105180:	55                   	push   %ebp
c0105181:	89 e5                	mov    %esp,%ebp
c0105183:	57                   	push   %edi
c0105184:	56                   	push   %esi
c0105185:	83 ec 20             	sub    $0x20,%esp
c0105188:	8b 45 08             	mov    0x8(%ebp),%eax
c010518b:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010518e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105191:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCPY
#define __HAVE_ARCH_STRCPY
static inline char *
__strcpy(char *dst, const char *src) {
    int d0, d1, d2;
    asm volatile (
c0105194:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0105197:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010519a:	89 d1                	mov    %edx,%ecx
c010519c:	89 c2                	mov    %eax,%edx
c010519e:	89 ce                	mov    %ecx,%esi
c01051a0:	89 d7                	mov    %edx,%edi
c01051a2:	ac                   	lods   %ds:(%esi),%al
c01051a3:	aa                   	stos   %al,%es:(%edi)
c01051a4:	84 c0                	test   %al,%al
c01051a6:	75 fa                	jne    c01051a2 <strcpy+0x22>
c01051a8:	89 fa                	mov    %edi,%edx
c01051aa:	89 f1                	mov    %esi,%ecx
c01051ac:	89 4d ec             	mov    %ecx,-0x14(%ebp)
c01051af:	89 55 e8             	mov    %edx,-0x18(%ebp)
c01051b2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        "stosb;"
        "testb %%al, %%al;"
        "jne 1b;"
        : "=&S" (d0), "=&D" (d1), "=&a" (d2)
        : "0" (src), "1" (dst) : "memory");
    return dst;
c01051b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
c01051b8:	90                   	nop
    char *p = dst;
    while ((*p ++ = *src ++) != '\0')
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
c01051b9:	83 c4 20             	add    $0x20,%esp
c01051bc:	5e                   	pop    %esi
c01051bd:	5f                   	pop    %edi
c01051be:	5d                   	pop    %ebp
c01051bf:	c3                   	ret    

c01051c0 <strncpy>:
 * @len:    maximum number of characters to be copied from @src
 *
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
c01051c0:	55                   	push   %ebp
c01051c1:	89 e5                	mov    %esp,%ebp
c01051c3:	83 ec 10             	sub    $0x10,%esp
    char *p = dst;
c01051c6:	8b 45 08             	mov    0x8(%ebp),%eax
c01051c9:	89 45 fc             	mov    %eax,-0x4(%ebp)
    while (len > 0) {
c01051cc:	eb 21                	jmp    c01051ef <strncpy+0x2f>
        if ((*p = *src) != '\0') {
c01051ce:	8b 45 0c             	mov    0xc(%ebp),%eax
c01051d1:	0f b6 10             	movzbl (%eax),%edx
c01051d4:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01051d7:	88 10                	mov    %dl,(%eax)
c01051d9:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01051dc:	0f b6 00             	movzbl (%eax),%eax
c01051df:	84 c0                	test   %al,%al
c01051e1:	74 04                	je     c01051e7 <strncpy+0x27>
            src ++;
c01051e3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
        }
        p ++, len --;
c01051e7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c01051eb:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
    char *p = dst;
    while (len > 0) {
c01051ef:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01051f3:	75 d9                	jne    c01051ce <strncpy+0xe>
        if ((*p = *src) != '\0') {
            src ++;
        }
        p ++, len --;
    }
    return dst;
c01051f5:	8b 45 08             	mov    0x8(%ebp),%eax
}
c01051f8:	c9                   	leave  
c01051f9:	c3                   	ret    

c01051fa <strcmp>:
 * - A value greater than zero indicates that the first character that does
 *   not match has a greater value in @s1 than in @s2;
 * - And a value less than zero indicates the opposite.
 * */
int
strcmp(const char *s1, const char *s2) {
c01051fa:	55                   	push   %ebp
c01051fb:	89 e5                	mov    %esp,%ebp
c01051fd:	57                   	push   %edi
c01051fe:	56                   	push   %esi
c01051ff:	83 ec 20             	sub    $0x20,%esp
c0105202:	8b 45 08             	mov    0x8(%ebp),%eax
c0105205:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0105208:	8b 45 0c             	mov    0xc(%ebp),%eax
c010520b:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCMP
#define __HAVE_ARCH_STRCMP
static inline int
__strcmp(const char *s1, const char *s2) {
    int d0, d1, ret;
    asm volatile (
c010520e:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105211:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105214:	89 d1                	mov    %edx,%ecx
c0105216:	89 c2                	mov    %eax,%edx
c0105218:	89 ce                	mov    %ecx,%esi
c010521a:	89 d7                	mov    %edx,%edi
c010521c:	ac                   	lods   %ds:(%esi),%al
c010521d:	ae                   	scas   %es:(%edi),%al
c010521e:	75 08                	jne    c0105228 <strcmp+0x2e>
c0105220:	84 c0                	test   %al,%al
c0105222:	75 f8                	jne    c010521c <strcmp+0x22>
c0105224:	31 c0                	xor    %eax,%eax
c0105226:	eb 04                	jmp    c010522c <strcmp+0x32>
c0105228:	19 c0                	sbb    %eax,%eax
c010522a:	0c 01                	or     $0x1,%al
c010522c:	89 fa                	mov    %edi,%edx
c010522e:	89 f1                	mov    %esi,%ecx
c0105230:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0105233:	89 4d e8             	mov    %ecx,-0x18(%ebp)
c0105236:	89 55 e4             	mov    %edx,-0x1c(%ebp)
        "orb $1, %%al;"
        "3:"
        : "=a" (ret), "=&S" (d0), "=&D" (d1)
        : "1" (s1), "2" (s2)
        : "memory");
    return ret;
c0105239:	8b 45 ec             	mov    -0x14(%ebp),%eax
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
c010523c:	90                   	nop
    while (*s1 != '\0' && *s1 == *s2) {
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
#endif /* __HAVE_ARCH_STRCMP */
}
c010523d:	83 c4 20             	add    $0x20,%esp
c0105240:	5e                   	pop    %esi
c0105241:	5f                   	pop    %edi
c0105242:	5d                   	pop    %ebp
c0105243:	c3                   	ret    

c0105244 <strncmp>:
 * they are equal to each other, it continues with the following pairs until
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
c0105244:	55                   	push   %ebp
c0105245:	89 e5                	mov    %esp,%ebp
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
c0105247:	eb 0c                	jmp    c0105255 <strncmp+0x11>
        n --, s1 ++, s2 ++;
c0105249:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
c010524d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c0105251:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
c0105255:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0105259:	74 1a                	je     c0105275 <strncmp+0x31>
c010525b:	8b 45 08             	mov    0x8(%ebp),%eax
c010525e:	0f b6 00             	movzbl (%eax),%eax
c0105261:	84 c0                	test   %al,%al
c0105263:	74 10                	je     c0105275 <strncmp+0x31>
c0105265:	8b 45 08             	mov    0x8(%ebp),%eax
c0105268:	0f b6 10             	movzbl (%eax),%edx
c010526b:	8b 45 0c             	mov    0xc(%ebp),%eax
c010526e:	0f b6 00             	movzbl (%eax),%eax
c0105271:	38 c2                	cmp    %al,%dl
c0105273:	74 d4                	je     c0105249 <strncmp+0x5>
        n --, s1 ++, s2 ++;
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
c0105275:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0105279:	74 18                	je     c0105293 <strncmp+0x4f>
c010527b:	8b 45 08             	mov    0x8(%ebp),%eax
c010527e:	0f b6 00             	movzbl (%eax),%eax
c0105281:	0f b6 d0             	movzbl %al,%edx
c0105284:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105287:	0f b6 00             	movzbl (%eax),%eax
c010528a:	0f b6 c0             	movzbl %al,%eax
c010528d:	29 c2                	sub    %eax,%edx
c010528f:	89 d0                	mov    %edx,%eax
c0105291:	eb 05                	jmp    c0105298 <strncmp+0x54>
c0105293:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0105298:	5d                   	pop    %ebp
c0105299:	c3                   	ret    

c010529a <strchr>:
 *
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
c010529a:	55                   	push   %ebp
c010529b:	89 e5                	mov    %esp,%ebp
c010529d:	83 ec 04             	sub    $0x4,%esp
c01052a0:	8b 45 0c             	mov    0xc(%ebp),%eax
c01052a3:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
c01052a6:	eb 14                	jmp    c01052bc <strchr+0x22>
        if (*s == c) {
c01052a8:	8b 45 08             	mov    0x8(%ebp),%eax
c01052ab:	0f b6 00             	movzbl (%eax),%eax
c01052ae:	3a 45 fc             	cmp    -0x4(%ebp),%al
c01052b1:	75 05                	jne    c01052b8 <strchr+0x1e>
            return (char *)s;
c01052b3:	8b 45 08             	mov    0x8(%ebp),%eax
c01052b6:	eb 13                	jmp    c01052cb <strchr+0x31>
        }
        s ++;
c01052b8:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
c01052bc:	8b 45 08             	mov    0x8(%ebp),%eax
c01052bf:	0f b6 00             	movzbl (%eax),%eax
c01052c2:	84 c0                	test   %al,%al
c01052c4:	75 e2                	jne    c01052a8 <strchr+0xe>
        if (*s == c) {
            return (char *)s;
        }
        s ++;
    }
    return NULL;
c01052c6:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01052cb:	c9                   	leave  
c01052cc:	c3                   	ret    

c01052cd <strfind>:
 * The strfind() function is like strchr() except that if @c is
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
c01052cd:	55                   	push   %ebp
c01052ce:	89 e5                	mov    %esp,%ebp
c01052d0:	83 ec 04             	sub    $0x4,%esp
c01052d3:	8b 45 0c             	mov    0xc(%ebp),%eax
c01052d6:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
c01052d9:	eb 0f                	jmp    c01052ea <strfind+0x1d>
        if (*s == c) {
c01052db:	8b 45 08             	mov    0x8(%ebp),%eax
c01052de:	0f b6 00             	movzbl (%eax),%eax
c01052e1:	3a 45 fc             	cmp    -0x4(%ebp),%al
c01052e4:	74 10                	je     c01052f6 <strfind+0x29>
            break;
        }
        s ++;
c01052e6:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
    while (*s != '\0') {
c01052ea:	8b 45 08             	mov    0x8(%ebp),%eax
c01052ed:	0f b6 00             	movzbl (%eax),%eax
c01052f0:	84 c0                	test   %al,%al
c01052f2:	75 e7                	jne    c01052db <strfind+0xe>
c01052f4:	eb 01                	jmp    c01052f7 <strfind+0x2a>
        if (*s == c) {
            break;
c01052f6:	90                   	nop
        }
        s ++;
    }
    return (char *)s;
c01052f7:	8b 45 08             	mov    0x8(%ebp),%eax
}
c01052fa:	c9                   	leave  
c01052fb:	c3                   	ret    

c01052fc <strtol>:
 * an optional "0x" or "0X" prefix.
 *
 * The strtol() function returns the converted integral number as a long int value.
 * */
long
strtol(const char *s, char **endptr, int base) {
c01052fc:	55                   	push   %ebp
c01052fd:	89 e5                	mov    %esp,%ebp
c01052ff:	83 ec 10             	sub    $0x10,%esp
    int neg = 0;
c0105302:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    long val = 0;
c0105309:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
c0105310:	eb 04                	jmp    c0105316 <strtol+0x1a>
        s ++;
c0105312:	83 45 08 01          	addl   $0x1,0x8(%ebp)
strtol(const char *s, char **endptr, int base) {
    int neg = 0;
    long val = 0;

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
c0105316:	8b 45 08             	mov    0x8(%ebp),%eax
c0105319:	0f b6 00             	movzbl (%eax),%eax
c010531c:	3c 20                	cmp    $0x20,%al
c010531e:	74 f2                	je     c0105312 <strtol+0x16>
c0105320:	8b 45 08             	mov    0x8(%ebp),%eax
c0105323:	0f b6 00             	movzbl (%eax),%eax
c0105326:	3c 09                	cmp    $0x9,%al
c0105328:	74 e8                	je     c0105312 <strtol+0x16>
        s ++;
    }

    // plus/minus sign
    if (*s == '+') {
c010532a:	8b 45 08             	mov    0x8(%ebp),%eax
c010532d:	0f b6 00             	movzbl (%eax),%eax
c0105330:	3c 2b                	cmp    $0x2b,%al
c0105332:	75 06                	jne    c010533a <strtol+0x3e>
        s ++;
c0105334:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c0105338:	eb 15                	jmp    c010534f <strtol+0x53>
    }
    else if (*s == '-') {
c010533a:	8b 45 08             	mov    0x8(%ebp),%eax
c010533d:	0f b6 00             	movzbl (%eax),%eax
c0105340:	3c 2d                	cmp    $0x2d,%al
c0105342:	75 0b                	jne    c010534f <strtol+0x53>
        s ++, neg = 1;
c0105344:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c0105348:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)
    }

    // hex or octal base prefix
    if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x')) {
c010534f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0105353:	74 06                	je     c010535b <strtol+0x5f>
c0105355:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
c0105359:	75 24                	jne    c010537f <strtol+0x83>
c010535b:	8b 45 08             	mov    0x8(%ebp),%eax
c010535e:	0f b6 00             	movzbl (%eax),%eax
c0105361:	3c 30                	cmp    $0x30,%al
c0105363:	75 1a                	jne    c010537f <strtol+0x83>
c0105365:	8b 45 08             	mov    0x8(%ebp),%eax
c0105368:	83 c0 01             	add    $0x1,%eax
c010536b:	0f b6 00             	movzbl (%eax),%eax
c010536e:	3c 78                	cmp    $0x78,%al
c0105370:	75 0d                	jne    c010537f <strtol+0x83>
        s += 2, base = 16;
c0105372:	83 45 08 02          	addl   $0x2,0x8(%ebp)
c0105376:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
c010537d:	eb 2a                	jmp    c01053a9 <strtol+0xad>
    }
    else if (base == 0 && s[0] == '0') {
c010537f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0105383:	75 17                	jne    c010539c <strtol+0xa0>
c0105385:	8b 45 08             	mov    0x8(%ebp),%eax
c0105388:	0f b6 00             	movzbl (%eax),%eax
c010538b:	3c 30                	cmp    $0x30,%al
c010538d:	75 0d                	jne    c010539c <strtol+0xa0>
        s ++, base = 8;
c010538f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c0105393:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
c010539a:	eb 0d                	jmp    c01053a9 <strtol+0xad>
    }
    else if (base == 0) {
c010539c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01053a0:	75 07                	jne    c01053a9 <strtol+0xad>
        base = 10;
c01053a2:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

    // digits
    while (1) {
        int dig;

        if (*s >= '0' && *s <= '9') {
c01053a9:	8b 45 08             	mov    0x8(%ebp),%eax
c01053ac:	0f b6 00             	movzbl (%eax),%eax
c01053af:	3c 2f                	cmp    $0x2f,%al
c01053b1:	7e 1b                	jle    c01053ce <strtol+0xd2>
c01053b3:	8b 45 08             	mov    0x8(%ebp),%eax
c01053b6:	0f b6 00             	movzbl (%eax),%eax
c01053b9:	3c 39                	cmp    $0x39,%al
c01053bb:	7f 11                	jg     c01053ce <strtol+0xd2>
            dig = *s - '0';
c01053bd:	8b 45 08             	mov    0x8(%ebp),%eax
c01053c0:	0f b6 00             	movzbl (%eax),%eax
c01053c3:	0f be c0             	movsbl %al,%eax
c01053c6:	83 e8 30             	sub    $0x30,%eax
c01053c9:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01053cc:	eb 48                	jmp    c0105416 <strtol+0x11a>
        }
        else if (*s >= 'a' && *s <= 'z') {
c01053ce:	8b 45 08             	mov    0x8(%ebp),%eax
c01053d1:	0f b6 00             	movzbl (%eax),%eax
c01053d4:	3c 60                	cmp    $0x60,%al
c01053d6:	7e 1b                	jle    c01053f3 <strtol+0xf7>
c01053d8:	8b 45 08             	mov    0x8(%ebp),%eax
c01053db:	0f b6 00             	movzbl (%eax),%eax
c01053de:	3c 7a                	cmp    $0x7a,%al
c01053e0:	7f 11                	jg     c01053f3 <strtol+0xf7>
            dig = *s - 'a' + 10;
c01053e2:	8b 45 08             	mov    0x8(%ebp),%eax
c01053e5:	0f b6 00             	movzbl (%eax),%eax
c01053e8:	0f be c0             	movsbl %al,%eax
c01053eb:	83 e8 57             	sub    $0x57,%eax
c01053ee:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01053f1:	eb 23                	jmp    c0105416 <strtol+0x11a>
        }
        else if (*s >= 'A' && *s <= 'Z') {
c01053f3:	8b 45 08             	mov    0x8(%ebp),%eax
c01053f6:	0f b6 00             	movzbl (%eax),%eax
c01053f9:	3c 40                	cmp    $0x40,%al
c01053fb:	7e 3c                	jle    c0105439 <strtol+0x13d>
c01053fd:	8b 45 08             	mov    0x8(%ebp),%eax
c0105400:	0f b6 00             	movzbl (%eax),%eax
c0105403:	3c 5a                	cmp    $0x5a,%al
c0105405:	7f 32                	jg     c0105439 <strtol+0x13d>
            dig = *s - 'A' + 10;
c0105407:	8b 45 08             	mov    0x8(%ebp),%eax
c010540a:	0f b6 00             	movzbl (%eax),%eax
c010540d:	0f be c0             	movsbl %al,%eax
c0105410:	83 e8 37             	sub    $0x37,%eax
c0105413:	89 45 f4             	mov    %eax,-0xc(%ebp)
        }
        else {
            break;
        }
        if (dig >= base) {
c0105416:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105419:	3b 45 10             	cmp    0x10(%ebp),%eax
c010541c:	7d 1a                	jge    c0105438 <strtol+0x13c>
            break;
        }
        s ++, val = (val * base) + dig;
c010541e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c0105422:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0105425:	0f af 45 10          	imul   0x10(%ebp),%eax
c0105429:	89 c2                	mov    %eax,%edx
c010542b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010542e:	01 d0                	add    %edx,%eax
c0105430:	89 45 f8             	mov    %eax,-0x8(%ebp)
        // we don't properly detect overflow!
    }
c0105433:	e9 71 ff ff ff       	jmp    c01053a9 <strtol+0xad>
        }
        else {
            break;
        }
        if (dig >= base) {
            break;
c0105438:	90                   	nop
        }
        s ++, val = (val * base) + dig;
        // we don't properly detect overflow!
    }

    if (endptr) {
c0105439:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c010543d:	74 08                	je     c0105447 <strtol+0x14b>
        *endptr = (char *) s;
c010543f:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105442:	8b 55 08             	mov    0x8(%ebp),%edx
c0105445:	89 10                	mov    %edx,(%eax)
    }
    return (neg ? -val : val);
c0105447:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
c010544b:	74 07                	je     c0105454 <strtol+0x158>
c010544d:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0105450:	f7 d8                	neg    %eax
c0105452:	eb 03                	jmp    c0105457 <strtol+0x15b>
c0105454:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
c0105457:	c9                   	leave  
c0105458:	c3                   	ret    

c0105459 <memset>:
 * @n:      number of bytes to be set to the value
 *
 * The memset() function returns @s.
 * */
void *
memset(void *s, char c, size_t n) {
c0105459:	55                   	push   %ebp
c010545a:	89 e5                	mov    %esp,%ebp
c010545c:	57                   	push   %edi
c010545d:	83 ec 24             	sub    $0x24,%esp
c0105460:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105463:	88 45 d8             	mov    %al,-0x28(%ebp)
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
c0105466:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
c010546a:	8b 55 08             	mov    0x8(%ebp),%edx
c010546d:	89 55 f8             	mov    %edx,-0x8(%ebp)
c0105470:	88 45 f7             	mov    %al,-0x9(%ebp)
c0105473:	8b 45 10             	mov    0x10(%ebp),%eax
c0105476:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_MEMSET
#define __HAVE_ARCH_MEMSET
static inline void *
__memset(void *s, char c, size_t n) {
    int d0, d1;
    asm volatile (
c0105479:	8b 4d f0             	mov    -0x10(%ebp),%ecx
c010547c:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
c0105480:	8b 55 f8             	mov    -0x8(%ebp),%edx
c0105483:	89 d7                	mov    %edx,%edi
c0105485:	f3 aa                	rep stos %al,%es:(%edi)
c0105487:	89 fa                	mov    %edi,%edx
c0105489:	89 4d ec             	mov    %ecx,-0x14(%ebp)
c010548c:	89 55 e8             	mov    %edx,-0x18(%ebp)
        "rep; stosb;"
        : "=&c" (d0), "=&D" (d1)
        : "0" (n), "a" (c), "1" (s)
        : "memory");
    return s;
c010548f:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0105492:	90                   	nop
    while (n -- > 0) {
        *p ++ = c;
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
c0105493:	83 c4 24             	add    $0x24,%esp
c0105496:	5f                   	pop    %edi
c0105497:	5d                   	pop    %ebp
c0105498:	c3                   	ret    

c0105499 <memmove>:
 * @n:      number of bytes to copy
 *
 * The memmove() function returns @dst.
 * */
void *
memmove(void *dst, const void *src, size_t n) {
c0105499:	55                   	push   %ebp
c010549a:	89 e5                	mov    %esp,%ebp
c010549c:	57                   	push   %edi
c010549d:	56                   	push   %esi
c010549e:	53                   	push   %ebx
c010549f:	83 ec 30             	sub    $0x30,%esp
c01054a2:	8b 45 08             	mov    0x8(%ebp),%eax
c01054a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01054a8:	8b 45 0c             	mov    0xc(%ebp),%eax
c01054ab:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01054ae:	8b 45 10             	mov    0x10(%ebp),%eax
c01054b1:	89 45 e8             	mov    %eax,-0x18(%ebp)

#ifndef __HAVE_ARCH_MEMMOVE
#define __HAVE_ARCH_MEMMOVE
static inline void *
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
c01054b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01054b7:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c01054ba:	73 42                	jae    c01054fe <memmove+0x65>
c01054bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01054bf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c01054c2:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01054c5:	89 45 e0             	mov    %eax,-0x20(%ebp)
c01054c8:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01054cb:	89 45 dc             	mov    %eax,-0x24(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
c01054ce:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01054d1:	c1 e8 02             	shr    $0x2,%eax
c01054d4:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
c01054d6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01054d9:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01054dc:	89 d7                	mov    %edx,%edi
c01054de:	89 c6                	mov    %eax,%esi
c01054e0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
c01054e2:	8b 4d dc             	mov    -0x24(%ebp),%ecx
c01054e5:	83 e1 03             	and    $0x3,%ecx
c01054e8:	74 02                	je     c01054ec <memmove+0x53>
c01054ea:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c01054ec:	89 f0                	mov    %esi,%eax
c01054ee:	89 fa                	mov    %edi,%edx
c01054f0:	89 4d d8             	mov    %ecx,-0x28(%ebp)
c01054f3:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c01054f6:	89 45 d0             	mov    %eax,-0x30(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
c01054f9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
#ifdef __HAVE_ARCH_MEMMOVE
    return __memmove(dst, src, n);
c01054fc:	eb 36                	jmp    c0105534 <memmove+0x9b>
    asm volatile (
        "std;"
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
c01054fe:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105501:	8d 50 ff             	lea    -0x1(%eax),%edx
c0105504:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105507:	01 c2                	add    %eax,%edx
c0105509:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010550c:	8d 48 ff             	lea    -0x1(%eax),%ecx
c010550f:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105512:	8d 1c 01             	lea    (%ecx,%eax,1),%ebx
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
        return __memcpy(dst, src, n);
    }
    int d0, d1, d2;
    asm volatile (
c0105515:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105518:	89 c1                	mov    %eax,%ecx
c010551a:	89 d8                	mov    %ebx,%eax
c010551c:	89 d6                	mov    %edx,%esi
c010551e:	89 c7                	mov    %eax,%edi
c0105520:	fd                   	std    
c0105521:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c0105523:	fc                   	cld    
c0105524:	89 f8                	mov    %edi,%eax
c0105526:	89 f2                	mov    %esi,%edx
c0105528:	89 4d cc             	mov    %ecx,-0x34(%ebp)
c010552b:	89 55 c8             	mov    %edx,-0x38(%ebp)
c010552e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
        : "memory");
    return dst;
c0105531:	8b 45 f0             	mov    -0x10(%ebp),%eax
            *d ++ = *s ++;
        }
    }
    return dst;
#endif /* __HAVE_ARCH_MEMMOVE */
}
c0105534:	83 c4 30             	add    $0x30,%esp
c0105537:	5b                   	pop    %ebx
c0105538:	5e                   	pop    %esi
c0105539:	5f                   	pop    %edi
c010553a:	5d                   	pop    %ebp
c010553b:	c3                   	ret    

c010553c <memcpy>:
 * it always copies exactly @n bytes. To avoid overflows, the size of arrays pointed
 * by both @src and @dst, should be at least @n bytes, and should not overlap
 * (for overlapping memory area, memmove is a safer approach).
 * */
void *
memcpy(void *dst, const void *src, size_t n) {
c010553c:	55                   	push   %ebp
c010553d:	89 e5                	mov    %esp,%ebp
c010553f:	57                   	push   %edi
c0105540:	56                   	push   %esi
c0105541:	83 ec 20             	sub    $0x20,%esp
c0105544:	8b 45 08             	mov    0x8(%ebp),%eax
c0105547:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010554a:	8b 45 0c             	mov    0xc(%ebp),%eax
c010554d:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105550:	8b 45 10             	mov    0x10(%ebp),%eax
c0105553:	89 45 ec             	mov    %eax,-0x14(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
c0105556:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105559:	c1 e8 02             	shr    $0x2,%eax
c010555c:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
c010555e:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105561:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105564:	89 d7                	mov    %edx,%edi
c0105566:	89 c6                	mov    %eax,%esi
c0105568:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
c010556a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
c010556d:	83 e1 03             	and    $0x3,%ecx
c0105570:	74 02                	je     c0105574 <memcpy+0x38>
c0105572:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c0105574:	89 f0                	mov    %esi,%eax
c0105576:	89 fa                	mov    %edi,%edx
c0105578:	89 4d e8             	mov    %ecx,-0x18(%ebp)
c010557b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
c010557e:	89 45 e0             	mov    %eax,-0x20(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
c0105581:	8b 45 f4             	mov    -0xc(%ebp),%eax
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
c0105584:	90                   	nop
    while (n -- > 0) {
        *d ++ = *s ++;
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
c0105585:	83 c4 20             	add    $0x20,%esp
c0105588:	5e                   	pop    %esi
c0105589:	5f                   	pop    %edi
c010558a:	5d                   	pop    %ebp
c010558b:	c3                   	ret    

c010558c <memcmp>:
 *   match in both memory blocks has a greater value in @v1 than in @v2
 *   as if evaluated as unsigned char values;
 * - And a value less than zero indicates the opposite.
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
c010558c:	55                   	push   %ebp
c010558d:	89 e5                	mov    %esp,%ebp
c010558f:	83 ec 10             	sub    $0x10,%esp
    const char *s1 = (const char *)v1;
c0105592:	8b 45 08             	mov    0x8(%ebp),%eax
c0105595:	89 45 fc             	mov    %eax,-0x4(%ebp)
    const char *s2 = (const char *)v2;
c0105598:	8b 45 0c             	mov    0xc(%ebp),%eax
c010559b:	89 45 f8             	mov    %eax,-0x8(%ebp)
    while (n -- > 0) {
c010559e:	eb 30                	jmp    c01055d0 <memcmp+0x44>
        if (*s1 != *s2) {
c01055a0:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01055a3:	0f b6 10             	movzbl (%eax),%edx
c01055a6:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01055a9:	0f b6 00             	movzbl (%eax),%eax
c01055ac:	38 c2                	cmp    %al,%dl
c01055ae:	74 18                	je     c01055c8 <memcmp+0x3c>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
c01055b0:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01055b3:	0f b6 00             	movzbl (%eax),%eax
c01055b6:	0f b6 d0             	movzbl %al,%edx
c01055b9:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01055bc:	0f b6 00             	movzbl (%eax),%eax
c01055bf:	0f b6 c0             	movzbl %al,%eax
c01055c2:	29 c2                	sub    %eax,%edx
c01055c4:	89 d0                	mov    %edx,%eax
c01055c6:	eb 1a                	jmp    c01055e2 <memcmp+0x56>
        }
        s1 ++, s2 ++;
c01055c8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c01055cc:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
c01055d0:	8b 45 10             	mov    0x10(%ebp),%eax
c01055d3:	8d 50 ff             	lea    -0x1(%eax),%edx
c01055d6:	89 55 10             	mov    %edx,0x10(%ebp)
c01055d9:	85 c0                	test   %eax,%eax
c01055db:	75 c3                	jne    c01055a0 <memcmp+0x14>
        if (*s1 != *s2) {
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
    }
    return 0;
c01055dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01055e2:	c9                   	leave  
c01055e3:	c3                   	ret    

c01055e4 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
c01055e4:	55                   	push   %ebp
c01055e5:	89 e5                	mov    %esp,%ebp
c01055e7:	83 ec 38             	sub    $0x38,%esp
c01055ea:	8b 45 10             	mov    0x10(%ebp),%eax
c01055ed:	89 45 d0             	mov    %eax,-0x30(%ebp)
c01055f0:	8b 45 14             	mov    0x14(%ebp),%eax
c01055f3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    unsigned long long result = num;
c01055f6:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01055f9:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01055fc:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01055ff:	89 55 ec             	mov    %edx,-0x14(%ebp)
    unsigned mod = do_div(result, base);
c0105602:	8b 45 18             	mov    0x18(%ebp),%eax
c0105605:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0105608:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010560b:	8b 55 ec             	mov    -0x14(%ebp),%edx
c010560e:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0105611:	89 55 f0             	mov    %edx,-0x10(%ebp)
c0105614:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105617:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010561a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c010561e:	74 1c                	je     c010563c <printnum+0x58>
c0105620:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105623:	ba 00 00 00 00       	mov    $0x0,%edx
c0105628:	f7 75 e4             	divl   -0x1c(%ebp)
c010562b:	89 55 f4             	mov    %edx,-0xc(%ebp)
c010562e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105631:	ba 00 00 00 00       	mov    $0x0,%edx
c0105636:	f7 75 e4             	divl   -0x1c(%ebp)
c0105639:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010563c:	8b 45 e0             	mov    -0x20(%ebp),%eax
c010563f:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105642:	f7 75 e4             	divl   -0x1c(%ebp)
c0105645:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0105648:	89 55 dc             	mov    %edx,-0x24(%ebp)
c010564b:	8b 45 e0             	mov    -0x20(%ebp),%eax
c010564e:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0105651:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0105654:	89 55 ec             	mov    %edx,-0x14(%ebp)
c0105657:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010565a:	89 45 d8             	mov    %eax,-0x28(%ebp)

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
c010565d:	8b 45 18             	mov    0x18(%ebp),%eax
c0105660:	ba 00 00 00 00       	mov    $0x0,%edx
c0105665:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0105668:	77 41                	ja     c01056ab <printnum+0xc7>
c010566a:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c010566d:	72 05                	jb     c0105674 <printnum+0x90>
c010566f:	3b 45 d0             	cmp    -0x30(%ebp),%eax
c0105672:	77 37                	ja     c01056ab <printnum+0xc7>
        printnum(putch, putdat, result, base, width - 1, padc);
c0105674:	8b 45 1c             	mov    0x1c(%ebp),%eax
c0105677:	83 e8 01             	sub    $0x1,%eax
c010567a:	83 ec 04             	sub    $0x4,%esp
c010567d:	ff 75 20             	pushl  0x20(%ebp)
c0105680:	50                   	push   %eax
c0105681:	ff 75 18             	pushl  0x18(%ebp)
c0105684:	ff 75 ec             	pushl  -0x14(%ebp)
c0105687:	ff 75 e8             	pushl  -0x18(%ebp)
c010568a:	ff 75 0c             	pushl  0xc(%ebp)
c010568d:	ff 75 08             	pushl  0x8(%ebp)
c0105690:	e8 4f ff ff ff       	call   c01055e4 <printnum>
c0105695:	83 c4 20             	add    $0x20,%esp
c0105698:	eb 1b                	jmp    c01056b5 <printnum+0xd1>
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
            putch(padc, putdat);
c010569a:	83 ec 08             	sub    $0x8,%esp
c010569d:	ff 75 0c             	pushl  0xc(%ebp)
c01056a0:	ff 75 20             	pushl  0x20(%ebp)
c01056a3:	8b 45 08             	mov    0x8(%ebp),%eax
c01056a6:	ff d0                	call   *%eax
c01056a8:	83 c4 10             	add    $0x10,%esp
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
c01056ab:	83 6d 1c 01          	subl   $0x1,0x1c(%ebp)
c01056af:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
c01056b3:	7f e5                	jg     c010569a <printnum+0xb6>
            putch(padc, putdat);
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
c01056b5:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01056b8:	05 f0 6d 10 c0       	add    $0xc0106df0,%eax
c01056bd:	0f b6 00             	movzbl (%eax),%eax
c01056c0:	0f be c0             	movsbl %al,%eax
c01056c3:	83 ec 08             	sub    $0x8,%esp
c01056c6:	ff 75 0c             	pushl  0xc(%ebp)
c01056c9:	50                   	push   %eax
c01056ca:	8b 45 08             	mov    0x8(%ebp),%eax
c01056cd:	ff d0                	call   *%eax
c01056cf:	83 c4 10             	add    $0x10,%esp
}
c01056d2:	90                   	nop
c01056d3:	c9                   	leave  
c01056d4:	c3                   	ret    

c01056d5 <getuint>:
 * getuint - get an unsigned int of various possible sizes from a varargs list
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static unsigned long long
getuint(va_list *ap, int lflag) {
c01056d5:	55                   	push   %ebp
c01056d6:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
c01056d8:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
c01056dc:	7e 14                	jle    c01056f2 <getuint+0x1d>
        return va_arg(*ap, unsigned long long);
c01056de:	8b 45 08             	mov    0x8(%ebp),%eax
c01056e1:	8b 00                	mov    (%eax),%eax
c01056e3:	8d 48 08             	lea    0x8(%eax),%ecx
c01056e6:	8b 55 08             	mov    0x8(%ebp),%edx
c01056e9:	89 0a                	mov    %ecx,(%edx)
c01056eb:	8b 50 04             	mov    0x4(%eax),%edx
c01056ee:	8b 00                	mov    (%eax),%eax
c01056f0:	eb 30                	jmp    c0105722 <getuint+0x4d>
    }
    else if (lflag) {
c01056f2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c01056f6:	74 16                	je     c010570e <getuint+0x39>
        return va_arg(*ap, unsigned long);
c01056f8:	8b 45 08             	mov    0x8(%ebp),%eax
c01056fb:	8b 00                	mov    (%eax),%eax
c01056fd:	8d 48 04             	lea    0x4(%eax),%ecx
c0105700:	8b 55 08             	mov    0x8(%ebp),%edx
c0105703:	89 0a                	mov    %ecx,(%edx)
c0105705:	8b 00                	mov    (%eax),%eax
c0105707:	ba 00 00 00 00       	mov    $0x0,%edx
c010570c:	eb 14                	jmp    c0105722 <getuint+0x4d>
    }
    else {
        return va_arg(*ap, unsigned int);
c010570e:	8b 45 08             	mov    0x8(%ebp),%eax
c0105711:	8b 00                	mov    (%eax),%eax
c0105713:	8d 48 04             	lea    0x4(%eax),%ecx
c0105716:	8b 55 08             	mov    0x8(%ebp),%edx
c0105719:	89 0a                	mov    %ecx,(%edx)
c010571b:	8b 00                	mov    (%eax),%eax
c010571d:	ba 00 00 00 00       	mov    $0x0,%edx
    }
}
c0105722:	5d                   	pop    %ebp
c0105723:	c3                   	ret    

c0105724 <getint>:
 * getint - same as getuint but signed, we can't use getuint because of sign extension
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static long long
getint(va_list *ap, int lflag) {
c0105724:	55                   	push   %ebp
c0105725:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
c0105727:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
c010572b:	7e 14                	jle    c0105741 <getint+0x1d>
        return va_arg(*ap, long long);
c010572d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105730:	8b 00                	mov    (%eax),%eax
c0105732:	8d 48 08             	lea    0x8(%eax),%ecx
c0105735:	8b 55 08             	mov    0x8(%ebp),%edx
c0105738:	89 0a                	mov    %ecx,(%edx)
c010573a:	8b 50 04             	mov    0x4(%eax),%edx
c010573d:	8b 00                	mov    (%eax),%eax
c010573f:	eb 28                	jmp    c0105769 <getint+0x45>
    }
    else if (lflag) {
c0105741:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0105745:	74 12                	je     c0105759 <getint+0x35>
        return va_arg(*ap, long);
c0105747:	8b 45 08             	mov    0x8(%ebp),%eax
c010574a:	8b 00                	mov    (%eax),%eax
c010574c:	8d 48 04             	lea    0x4(%eax),%ecx
c010574f:	8b 55 08             	mov    0x8(%ebp),%edx
c0105752:	89 0a                	mov    %ecx,(%edx)
c0105754:	8b 00                	mov    (%eax),%eax
c0105756:	99                   	cltd   
c0105757:	eb 10                	jmp    c0105769 <getint+0x45>
    }
    else {
        return va_arg(*ap, int);
c0105759:	8b 45 08             	mov    0x8(%ebp),%eax
c010575c:	8b 00                	mov    (%eax),%eax
c010575e:	8d 48 04             	lea    0x4(%eax),%ecx
c0105761:	8b 55 08             	mov    0x8(%ebp),%edx
c0105764:	89 0a                	mov    %ecx,(%edx)
c0105766:	8b 00                	mov    (%eax),%eax
c0105768:	99                   	cltd   
    }
}
c0105769:	5d                   	pop    %ebp
c010576a:	c3                   	ret    

c010576b <printfmt>:
 * @putch:      specified putch function, print a single character
 * @putdat:     used by @putch function
 * @fmt:        the format string to use
 * */
void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
c010576b:	55                   	push   %ebp
c010576c:	89 e5                	mov    %esp,%ebp
c010576e:	83 ec 18             	sub    $0x18,%esp
    va_list ap;

    va_start(ap, fmt);
c0105771:	8d 45 14             	lea    0x14(%ebp),%eax
c0105774:	89 45 f4             	mov    %eax,-0xc(%ebp)
    vprintfmt(putch, putdat, fmt, ap);
c0105777:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010577a:	50                   	push   %eax
c010577b:	ff 75 10             	pushl  0x10(%ebp)
c010577e:	ff 75 0c             	pushl  0xc(%ebp)
c0105781:	ff 75 08             	pushl  0x8(%ebp)
c0105784:	e8 06 00 00 00       	call   c010578f <vprintfmt>
c0105789:	83 c4 10             	add    $0x10,%esp
    va_end(ap);
}
c010578c:	90                   	nop
c010578d:	c9                   	leave  
c010578e:	c3                   	ret    

c010578f <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
c010578f:	55                   	push   %ebp
c0105790:	89 e5                	mov    %esp,%ebp
c0105792:	56                   	push   %esi
c0105793:	53                   	push   %ebx
c0105794:	83 ec 20             	sub    $0x20,%esp
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
c0105797:	eb 17                	jmp    c01057b0 <vprintfmt+0x21>
            if (ch == '\0') {
c0105799:	85 db                	test   %ebx,%ebx
c010579b:	0f 84 8e 03 00 00    	je     c0105b2f <vprintfmt+0x3a0>
                return;
            }
            putch(ch, putdat);
c01057a1:	83 ec 08             	sub    $0x8,%esp
c01057a4:	ff 75 0c             	pushl  0xc(%ebp)
c01057a7:	53                   	push   %ebx
c01057a8:	8b 45 08             	mov    0x8(%ebp),%eax
c01057ab:	ff d0                	call   *%eax
c01057ad:	83 c4 10             	add    $0x10,%esp
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
c01057b0:	8b 45 10             	mov    0x10(%ebp),%eax
c01057b3:	8d 50 01             	lea    0x1(%eax),%edx
c01057b6:	89 55 10             	mov    %edx,0x10(%ebp)
c01057b9:	0f b6 00             	movzbl (%eax),%eax
c01057bc:	0f b6 d8             	movzbl %al,%ebx
c01057bf:	83 fb 25             	cmp    $0x25,%ebx
c01057c2:	75 d5                	jne    c0105799 <vprintfmt+0xa>
            }
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
c01057c4:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
        width = precision = -1;
c01057c8:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
c01057cf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01057d2:	89 45 e8             	mov    %eax,-0x18(%ebp)
        lflag = altflag = 0;
c01057d5:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c01057dc:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01057df:	89 45 e0             	mov    %eax,-0x20(%ebp)

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
c01057e2:	8b 45 10             	mov    0x10(%ebp),%eax
c01057e5:	8d 50 01             	lea    0x1(%eax),%edx
c01057e8:	89 55 10             	mov    %edx,0x10(%ebp)
c01057eb:	0f b6 00             	movzbl (%eax),%eax
c01057ee:	0f b6 d8             	movzbl %al,%ebx
c01057f1:	8d 43 dd             	lea    -0x23(%ebx),%eax
c01057f4:	83 f8 55             	cmp    $0x55,%eax
c01057f7:	0f 87 05 03 00 00    	ja     c0105b02 <vprintfmt+0x373>
c01057fd:	8b 04 85 14 6e 10 c0 	mov    -0x3fef91ec(,%eax,4),%eax
c0105804:	ff e0                	jmp    *%eax

        // flag to pad on the right
        case '-':
            padc = '-';
c0105806:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
            goto reswitch;
c010580a:	eb d6                	jmp    c01057e2 <vprintfmt+0x53>

        // flag to pad with 0's instead of spaces
        case '0':
            padc = '0';
c010580c:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
            goto reswitch;
c0105810:	eb d0                	jmp    c01057e2 <vprintfmt+0x53>

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
c0105812:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
                precision = precision * 10 + ch - '0';
c0105819:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c010581c:	89 d0                	mov    %edx,%eax
c010581e:	c1 e0 02             	shl    $0x2,%eax
c0105821:	01 d0                	add    %edx,%eax
c0105823:	01 c0                	add    %eax,%eax
c0105825:	01 d8                	add    %ebx,%eax
c0105827:	83 e8 30             	sub    $0x30,%eax
c010582a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
                ch = *fmt;
c010582d:	8b 45 10             	mov    0x10(%ebp),%eax
c0105830:	0f b6 00             	movzbl (%eax),%eax
c0105833:	0f be d8             	movsbl %al,%ebx
                if (ch < '0' || ch > '9') {
c0105836:	83 fb 2f             	cmp    $0x2f,%ebx
c0105839:	7e 39                	jle    c0105874 <vprintfmt+0xe5>
c010583b:	83 fb 39             	cmp    $0x39,%ebx
c010583e:	7f 34                	jg     c0105874 <vprintfmt+0xe5>
            padc = '0';
            goto reswitch;

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
c0105840:	83 45 10 01          	addl   $0x1,0x10(%ebp)
                precision = precision * 10 + ch - '0';
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
c0105844:	eb d3                	jmp    c0105819 <vprintfmt+0x8a>
            goto process_precision;

        case '*':
            precision = va_arg(ap, int);
c0105846:	8b 45 14             	mov    0x14(%ebp),%eax
c0105849:	8d 50 04             	lea    0x4(%eax),%edx
c010584c:	89 55 14             	mov    %edx,0x14(%ebp)
c010584f:	8b 00                	mov    (%eax),%eax
c0105851:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            goto process_precision;
c0105854:	eb 1f                	jmp    c0105875 <vprintfmt+0xe6>

        case '.':
            if (width < 0)
c0105856:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c010585a:	79 86                	jns    c01057e2 <vprintfmt+0x53>
                width = 0;
c010585c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
            goto reswitch;
c0105863:	e9 7a ff ff ff       	jmp    c01057e2 <vprintfmt+0x53>

        case '#':
            altflag = 1;
c0105868:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
            goto reswitch;
c010586f:	e9 6e ff ff ff       	jmp    c01057e2 <vprintfmt+0x53>
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
            goto process_precision;
c0105874:	90                   	nop
        case '#':
            altflag = 1;
            goto reswitch;

        process_precision:
            if (width < 0)
c0105875:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0105879:	0f 89 63 ff ff ff    	jns    c01057e2 <vprintfmt+0x53>
                width = precision, precision = -1;
c010587f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105882:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0105885:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
            goto reswitch;
c010588c:	e9 51 ff ff ff       	jmp    c01057e2 <vprintfmt+0x53>

        // long flag (doubled for long long)
        case 'l':
            lflag ++;
c0105891:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
            goto reswitch;
c0105895:	e9 48 ff ff ff       	jmp    c01057e2 <vprintfmt+0x53>

        // character
        case 'c':
            putch(va_arg(ap, int), putdat);
c010589a:	8b 45 14             	mov    0x14(%ebp),%eax
c010589d:	8d 50 04             	lea    0x4(%eax),%edx
c01058a0:	89 55 14             	mov    %edx,0x14(%ebp)
c01058a3:	8b 00                	mov    (%eax),%eax
c01058a5:	83 ec 08             	sub    $0x8,%esp
c01058a8:	ff 75 0c             	pushl  0xc(%ebp)
c01058ab:	50                   	push   %eax
c01058ac:	8b 45 08             	mov    0x8(%ebp),%eax
c01058af:	ff d0                	call   *%eax
c01058b1:	83 c4 10             	add    $0x10,%esp
            break;
c01058b4:	e9 71 02 00 00       	jmp    c0105b2a <vprintfmt+0x39b>

        // error message
        case 'e':
            err = va_arg(ap, int);
c01058b9:	8b 45 14             	mov    0x14(%ebp),%eax
c01058bc:	8d 50 04             	lea    0x4(%eax),%edx
c01058bf:	89 55 14             	mov    %edx,0x14(%ebp)
c01058c2:	8b 18                	mov    (%eax),%ebx
            if (err < 0) {
c01058c4:	85 db                	test   %ebx,%ebx
c01058c6:	79 02                	jns    c01058ca <vprintfmt+0x13b>
                err = -err;
c01058c8:	f7 db                	neg    %ebx
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
c01058ca:	83 fb 06             	cmp    $0x6,%ebx
c01058cd:	7f 0b                	jg     c01058da <vprintfmt+0x14b>
c01058cf:	8b 34 9d d4 6d 10 c0 	mov    -0x3fef922c(,%ebx,4),%esi
c01058d6:	85 f6                	test   %esi,%esi
c01058d8:	75 19                	jne    c01058f3 <vprintfmt+0x164>
                printfmt(putch, putdat, "error %d", err);
c01058da:	53                   	push   %ebx
c01058db:	68 01 6e 10 c0       	push   $0xc0106e01
c01058e0:	ff 75 0c             	pushl  0xc(%ebp)
c01058e3:	ff 75 08             	pushl  0x8(%ebp)
c01058e6:	e8 80 fe ff ff       	call   c010576b <printfmt>
c01058eb:	83 c4 10             	add    $0x10,%esp
            }
            else {
                printfmt(putch, putdat, "%s", p);
            }
            break;
c01058ee:	e9 37 02 00 00       	jmp    c0105b2a <vprintfmt+0x39b>
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
                printfmt(putch, putdat, "error %d", err);
            }
            else {
                printfmt(putch, putdat, "%s", p);
c01058f3:	56                   	push   %esi
c01058f4:	68 0a 6e 10 c0       	push   $0xc0106e0a
c01058f9:	ff 75 0c             	pushl  0xc(%ebp)
c01058fc:	ff 75 08             	pushl  0x8(%ebp)
c01058ff:	e8 67 fe ff ff       	call   c010576b <printfmt>
c0105904:	83 c4 10             	add    $0x10,%esp
            }
            break;
c0105907:	e9 1e 02 00 00       	jmp    c0105b2a <vprintfmt+0x39b>

        // string
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
c010590c:	8b 45 14             	mov    0x14(%ebp),%eax
c010590f:	8d 50 04             	lea    0x4(%eax),%edx
c0105912:	89 55 14             	mov    %edx,0x14(%ebp)
c0105915:	8b 30                	mov    (%eax),%esi
c0105917:	85 f6                	test   %esi,%esi
c0105919:	75 05                	jne    c0105920 <vprintfmt+0x191>
                p = "(null)";
c010591b:	be 0d 6e 10 c0       	mov    $0xc0106e0d,%esi
            }
            if (width > 0 && padc != '-') {
c0105920:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0105924:	7e 76                	jle    c010599c <vprintfmt+0x20d>
c0105926:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
c010592a:	74 70                	je     c010599c <vprintfmt+0x20d>
                for (width -= strnlen(p, precision); width > 0; width --) {
c010592c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010592f:	83 ec 08             	sub    $0x8,%esp
c0105932:	50                   	push   %eax
c0105933:	56                   	push   %esi
c0105934:	e8 17 f8 ff ff       	call   c0105150 <strnlen>
c0105939:	83 c4 10             	add    $0x10,%esp
c010593c:	89 c2                	mov    %eax,%edx
c010593e:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105941:	29 d0                	sub    %edx,%eax
c0105943:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0105946:	eb 17                	jmp    c010595f <vprintfmt+0x1d0>
                    putch(padc, putdat);
c0105948:	0f be 45 db          	movsbl -0x25(%ebp),%eax
c010594c:	83 ec 08             	sub    $0x8,%esp
c010594f:	ff 75 0c             	pushl  0xc(%ebp)
c0105952:	50                   	push   %eax
c0105953:	8b 45 08             	mov    0x8(%ebp),%eax
c0105956:	ff d0                	call   *%eax
c0105958:	83 c4 10             	add    $0x10,%esp
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
                p = "(null)";
            }
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
c010595b:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
c010595f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0105963:	7f e3                	jg     c0105948 <vprintfmt+0x1b9>
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
c0105965:	eb 35                	jmp    c010599c <vprintfmt+0x20d>
                if (altflag && (ch < ' ' || ch > '~')) {
c0105967:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c010596b:	74 1c                	je     c0105989 <vprintfmt+0x1fa>
c010596d:	83 fb 1f             	cmp    $0x1f,%ebx
c0105970:	7e 05                	jle    c0105977 <vprintfmt+0x1e8>
c0105972:	83 fb 7e             	cmp    $0x7e,%ebx
c0105975:	7e 12                	jle    c0105989 <vprintfmt+0x1fa>
                    putch('?', putdat);
c0105977:	83 ec 08             	sub    $0x8,%esp
c010597a:	ff 75 0c             	pushl  0xc(%ebp)
c010597d:	6a 3f                	push   $0x3f
c010597f:	8b 45 08             	mov    0x8(%ebp),%eax
c0105982:	ff d0                	call   *%eax
c0105984:	83 c4 10             	add    $0x10,%esp
c0105987:	eb 0f                	jmp    c0105998 <vprintfmt+0x209>
                }
                else {
                    putch(ch, putdat);
c0105989:	83 ec 08             	sub    $0x8,%esp
c010598c:	ff 75 0c             	pushl  0xc(%ebp)
c010598f:	53                   	push   %ebx
c0105990:	8b 45 08             	mov    0x8(%ebp),%eax
c0105993:	ff d0                	call   *%eax
c0105995:	83 c4 10             	add    $0x10,%esp
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
c0105998:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
c010599c:	89 f0                	mov    %esi,%eax
c010599e:	8d 70 01             	lea    0x1(%eax),%esi
c01059a1:	0f b6 00             	movzbl (%eax),%eax
c01059a4:	0f be d8             	movsbl %al,%ebx
c01059a7:	85 db                	test   %ebx,%ebx
c01059a9:	74 26                	je     c01059d1 <vprintfmt+0x242>
c01059ab:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c01059af:	78 b6                	js     c0105967 <vprintfmt+0x1d8>
c01059b1:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
c01059b5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c01059b9:	79 ac                	jns    c0105967 <vprintfmt+0x1d8>
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
c01059bb:	eb 14                	jmp    c01059d1 <vprintfmt+0x242>
                putch(' ', putdat);
c01059bd:	83 ec 08             	sub    $0x8,%esp
c01059c0:	ff 75 0c             	pushl  0xc(%ebp)
c01059c3:	6a 20                	push   $0x20
c01059c5:	8b 45 08             	mov    0x8(%ebp),%eax
c01059c8:	ff d0                	call   *%eax
c01059ca:	83 c4 10             	add    $0x10,%esp
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
c01059cd:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
c01059d1:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c01059d5:	7f e6                	jg     c01059bd <vprintfmt+0x22e>
                putch(' ', putdat);
            }
            break;
c01059d7:	e9 4e 01 00 00       	jmp    c0105b2a <vprintfmt+0x39b>

        // (signed) decimal
        case 'd':
            num = getint(&ap, lflag);
c01059dc:	83 ec 08             	sub    $0x8,%esp
c01059df:	ff 75 e0             	pushl  -0x20(%ebp)
c01059e2:	8d 45 14             	lea    0x14(%ebp),%eax
c01059e5:	50                   	push   %eax
c01059e6:	e8 39 fd ff ff       	call   c0105724 <getint>
c01059eb:	83 c4 10             	add    $0x10,%esp
c01059ee:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01059f1:	89 55 f4             	mov    %edx,-0xc(%ebp)
            if ((long long)num < 0) {
c01059f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01059f7:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01059fa:	85 d2                	test   %edx,%edx
c01059fc:	79 23                	jns    c0105a21 <vprintfmt+0x292>
                putch('-', putdat);
c01059fe:	83 ec 08             	sub    $0x8,%esp
c0105a01:	ff 75 0c             	pushl  0xc(%ebp)
c0105a04:	6a 2d                	push   $0x2d
c0105a06:	8b 45 08             	mov    0x8(%ebp),%eax
c0105a09:	ff d0                	call   *%eax
c0105a0b:	83 c4 10             	add    $0x10,%esp
                num = -(long long)num;
c0105a0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105a11:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105a14:	f7 d8                	neg    %eax
c0105a16:	83 d2 00             	adc    $0x0,%edx
c0105a19:	f7 da                	neg    %edx
c0105a1b:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105a1e:	89 55 f4             	mov    %edx,-0xc(%ebp)
            }
            base = 10;
c0105a21:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
c0105a28:	e9 9f 00 00 00       	jmp    c0105acc <vprintfmt+0x33d>

        // unsigned decimal
        case 'u':
            num = getuint(&ap, lflag);
c0105a2d:	83 ec 08             	sub    $0x8,%esp
c0105a30:	ff 75 e0             	pushl  -0x20(%ebp)
c0105a33:	8d 45 14             	lea    0x14(%ebp),%eax
c0105a36:	50                   	push   %eax
c0105a37:	e8 99 fc ff ff       	call   c01056d5 <getuint>
c0105a3c:	83 c4 10             	add    $0x10,%esp
c0105a3f:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105a42:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 10;
c0105a45:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
c0105a4c:	eb 7e                	jmp    c0105acc <vprintfmt+0x33d>

        // (unsigned) octal
        case 'o':
            num = getuint(&ap, lflag);
c0105a4e:	83 ec 08             	sub    $0x8,%esp
c0105a51:	ff 75 e0             	pushl  -0x20(%ebp)
c0105a54:	8d 45 14             	lea    0x14(%ebp),%eax
c0105a57:	50                   	push   %eax
c0105a58:	e8 78 fc ff ff       	call   c01056d5 <getuint>
c0105a5d:	83 c4 10             	add    $0x10,%esp
c0105a60:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105a63:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 8;
c0105a66:	c7 45 ec 08 00 00 00 	movl   $0x8,-0x14(%ebp)
            goto number;
c0105a6d:	eb 5d                	jmp    c0105acc <vprintfmt+0x33d>

        // pointer
        case 'p':
            putch('0', putdat);
c0105a6f:	83 ec 08             	sub    $0x8,%esp
c0105a72:	ff 75 0c             	pushl  0xc(%ebp)
c0105a75:	6a 30                	push   $0x30
c0105a77:	8b 45 08             	mov    0x8(%ebp),%eax
c0105a7a:	ff d0                	call   *%eax
c0105a7c:	83 c4 10             	add    $0x10,%esp
            putch('x', putdat);
c0105a7f:	83 ec 08             	sub    $0x8,%esp
c0105a82:	ff 75 0c             	pushl  0xc(%ebp)
c0105a85:	6a 78                	push   $0x78
c0105a87:	8b 45 08             	mov    0x8(%ebp),%eax
c0105a8a:	ff d0                	call   *%eax
c0105a8c:	83 c4 10             	add    $0x10,%esp
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
c0105a8f:	8b 45 14             	mov    0x14(%ebp),%eax
c0105a92:	8d 50 04             	lea    0x4(%eax),%edx
c0105a95:	89 55 14             	mov    %edx,0x14(%ebp)
c0105a98:	8b 00                	mov    (%eax),%eax
c0105a9a:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105a9d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
            base = 16;
c0105aa4:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
            goto number;
c0105aab:	eb 1f                	jmp    c0105acc <vprintfmt+0x33d>

        // (unsigned) hexadecimal
        case 'x':
            num = getuint(&ap, lflag);
c0105aad:	83 ec 08             	sub    $0x8,%esp
c0105ab0:	ff 75 e0             	pushl  -0x20(%ebp)
c0105ab3:	8d 45 14             	lea    0x14(%ebp),%eax
c0105ab6:	50                   	push   %eax
c0105ab7:	e8 19 fc ff ff       	call   c01056d5 <getuint>
c0105abc:	83 c4 10             	add    $0x10,%esp
c0105abf:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105ac2:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 16;
c0105ac5:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
        number:
            printnum(putch, putdat, num, base, width, padc);
c0105acc:	0f be 55 db          	movsbl -0x25(%ebp),%edx
c0105ad0:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105ad3:	83 ec 04             	sub    $0x4,%esp
c0105ad6:	52                   	push   %edx
c0105ad7:	ff 75 e8             	pushl  -0x18(%ebp)
c0105ada:	50                   	push   %eax
c0105adb:	ff 75 f4             	pushl  -0xc(%ebp)
c0105ade:	ff 75 f0             	pushl  -0x10(%ebp)
c0105ae1:	ff 75 0c             	pushl  0xc(%ebp)
c0105ae4:	ff 75 08             	pushl  0x8(%ebp)
c0105ae7:	e8 f8 fa ff ff       	call   c01055e4 <printnum>
c0105aec:	83 c4 20             	add    $0x20,%esp
            break;
c0105aef:	eb 39                	jmp    c0105b2a <vprintfmt+0x39b>

        // escaped '%' character
        case '%':
            putch(ch, putdat);
c0105af1:	83 ec 08             	sub    $0x8,%esp
c0105af4:	ff 75 0c             	pushl  0xc(%ebp)
c0105af7:	53                   	push   %ebx
c0105af8:	8b 45 08             	mov    0x8(%ebp),%eax
c0105afb:	ff d0                	call   *%eax
c0105afd:	83 c4 10             	add    $0x10,%esp
            break;
c0105b00:	eb 28                	jmp    c0105b2a <vprintfmt+0x39b>

        // unrecognized escape sequence - just print it literally
        default:
            putch('%', putdat);
c0105b02:	83 ec 08             	sub    $0x8,%esp
c0105b05:	ff 75 0c             	pushl  0xc(%ebp)
c0105b08:	6a 25                	push   $0x25
c0105b0a:	8b 45 08             	mov    0x8(%ebp),%eax
c0105b0d:	ff d0                	call   *%eax
c0105b0f:	83 c4 10             	add    $0x10,%esp
            for (fmt --; fmt[-1] != '%'; fmt --)
c0105b12:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
c0105b16:	eb 04                	jmp    c0105b1c <vprintfmt+0x38d>
c0105b18:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
c0105b1c:	8b 45 10             	mov    0x10(%ebp),%eax
c0105b1f:	83 e8 01             	sub    $0x1,%eax
c0105b22:	0f b6 00             	movzbl (%eax),%eax
c0105b25:	3c 25                	cmp    $0x25,%al
c0105b27:	75 ef                	jne    c0105b18 <vprintfmt+0x389>
                /* do nothing */;
            break;
c0105b29:	90                   	nop
        }
    }
c0105b2a:	e9 68 fc ff ff       	jmp    c0105797 <vprintfmt+0x8>
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
            if (ch == '\0') {
                return;
c0105b2f:	90                   	nop
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
c0105b30:	8d 65 f8             	lea    -0x8(%ebp),%esp
c0105b33:	5b                   	pop    %ebx
c0105b34:	5e                   	pop    %esi
c0105b35:	5d                   	pop    %ebp
c0105b36:	c3                   	ret    

c0105b37 <sprintputch>:
 * sprintputch - 'print' a single character in a buffer
 * @ch:         the character will be printed
 * @b:          the buffer to place the character @ch
 * */
static void
sprintputch(int ch, struct sprintbuf *b) {
c0105b37:	55                   	push   %ebp
c0105b38:	89 e5                	mov    %esp,%ebp
    b->cnt ++;
c0105b3a:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105b3d:	8b 40 08             	mov    0x8(%eax),%eax
c0105b40:	8d 50 01             	lea    0x1(%eax),%edx
c0105b43:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105b46:	89 50 08             	mov    %edx,0x8(%eax)
    if (b->buf < b->ebuf) {
c0105b49:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105b4c:	8b 10                	mov    (%eax),%edx
c0105b4e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105b51:	8b 40 04             	mov    0x4(%eax),%eax
c0105b54:	39 c2                	cmp    %eax,%edx
c0105b56:	73 12                	jae    c0105b6a <sprintputch+0x33>
        *b->buf ++ = ch;
c0105b58:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105b5b:	8b 00                	mov    (%eax),%eax
c0105b5d:	8d 48 01             	lea    0x1(%eax),%ecx
c0105b60:	8b 55 0c             	mov    0xc(%ebp),%edx
c0105b63:	89 0a                	mov    %ecx,(%edx)
c0105b65:	8b 55 08             	mov    0x8(%ebp),%edx
c0105b68:	88 10                	mov    %dl,(%eax)
    }
}
c0105b6a:	90                   	nop
c0105b6b:	5d                   	pop    %ebp
c0105b6c:	c3                   	ret    

c0105b6d <snprintf>:
 * @str:        the buffer to place the result into
 * @size:       the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * */
int
snprintf(char *str, size_t size, const char *fmt, ...) {
c0105b6d:	55                   	push   %ebp
c0105b6e:	89 e5                	mov    %esp,%ebp
c0105b70:	83 ec 18             	sub    $0x18,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
c0105b73:	8d 45 14             	lea    0x14(%ebp),%eax
c0105b76:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vsnprintf(str, size, fmt, ap);
c0105b79:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105b7c:	50                   	push   %eax
c0105b7d:	ff 75 10             	pushl  0x10(%ebp)
c0105b80:	ff 75 0c             	pushl  0xc(%ebp)
c0105b83:	ff 75 08             	pushl  0x8(%ebp)
c0105b86:	e8 0b 00 00 00       	call   c0105b96 <vsnprintf>
c0105b8b:	83 c4 10             	add    $0x10,%esp
c0105b8e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
c0105b91:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0105b94:	c9                   	leave  
c0105b95:	c3                   	ret    

c0105b96 <vsnprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want snprintf() instead.
 * */
int
vsnprintf(char *str, size_t size, const char *fmt, va_list ap) {
c0105b96:	55                   	push   %ebp
c0105b97:	89 e5                	mov    %esp,%ebp
c0105b99:	83 ec 18             	sub    $0x18,%esp
    struct sprintbuf b = {str, str + size - 1, 0};
c0105b9c:	8b 45 08             	mov    0x8(%ebp),%eax
c0105b9f:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0105ba2:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105ba5:	8d 50 ff             	lea    -0x1(%eax),%edx
c0105ba8:	8b 45 08             	mov    0x8(%ebp),%eax
c0105bab:	01 d0                	add    %edx,%eax
c0105bad:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105bb0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if (str == NULL || b.buf > b.ebuf) {
c0105bb7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0105bbb:	74 0a                	je     c0105bc7 <vsnprintf+0x31>
c0105bbd:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0105bc0:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105bc3:	39 c2                	cmp    %eax,%edx
c0105bc5:	76 07                	jbe    c0105bce <vsnprintf+0x38>
        return -E_INVAL;
c0105bc7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
c0105bcc:	eb 20                	jmp    c0105bee <vsnprintf+0x58>
    }
    // print the string to the buffer
    vprintfmt((void*)sprintputch, &b, fmt, ap);
c0105bce:	ff 75 14             	pushl  0x14(%ebp)
c0105bd1:	ff 75 10             	pushl  0x10(%ebp)
c0105bd4:	8d 45 ec             	lea    -0x14(%ebp),%eax
c0105bd7:	50                   	push   %eax
c0105bd8:	68 37 5b 10 c0       	push   $0xc0105b37
c0105bdd:	e8 ad fb ff ff       	call   c010578f <vprintfmt>
c0105be2:	83 c4 10             	add    $0x10,%esp
    // null terminate the buffer
    *b.buf = '\0';
c0105be5:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105be8:	c6 00 00             	movb   $0x0,(%eax)
    return b.cnt;
c0105beb:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0105bee:	c9                   	leave  
c0105bef:	c3                   	ret    
