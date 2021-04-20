
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
c0100055:	e8 a4 53 00 00       	call   c01053fe <memset>
c010005a:	83 c4 10             	add    $0x10,%esp

    cons_init();                // init the console
c010005d:	e8 67 15 00 00       	call   c01015c9 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
c0100062:	c7 45 f4 a0 5b 10 c0 	movl   $0xc0105ba0,-0xc(%ebp)
    cprintf("%s\n\n", message);
c0100069:	83 ec 08             	sub    $0x8,%esp
c010006c:	ff 75 f4             	pushl  -0xc(%ebp)
c010006f:	68 bc 5b 10 c0       	push   $0xc0105bbc
c0100074:	e8 04 02 00 00       	call   c010027d <cprintf>
c0100079:	83 c4 10             	add    $0x10,%esp

    print_kerninfo();
c010007c:	e8 9b 08 00 00       	call   c010091c <print_kerninfo>

    grade_backtrace();
c0100081:	e8 74 00 00 00       	call   c01000fa <grade_backtrace>

    pmm_init();                 // init physical memory management
c0100086:	e8 42 31 00 00       	call   c01031cd <pmm_init>

    pic_init();                 // init interrupt controller
c010008b:	e8 ab 16 00 00       	call   c010173b <pic_init>
    idt_init();                 // init interrupt descriptor table
c0100090:	e8 2d 18 00 00       	call   c01018c2 <idt_init>

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
c0100143:	68 c1 5b 10 c0       	push   $0xc0105bc1
c0100148:	e8 30 01 00 00       	call   c010027d <cprintf>
c010014d:	83 c4 10             	add    $0x10,%esp
    cprintf("%d:  cs = %x\n", round, reg1);
c0100150:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0100154:	0f b7 d0             	movzwl %ax,%edx
c0100157:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c010015c:	83 ec 04             	sub    $0x4,%esp
c010015f:	52                   	push   %edx
c0100160:	50                   	push   %eax
c0100161:	68 cf 5b 10 c0       	push   $0xc0105bcf
c0100166:	e8 12 01 00 00       	call   c010027d <cprintf>
c010016b:	83 c4 10             	add    $0x10,%esp
    cprintf("%d:  ds = %x\n", round, reg2);
c010016e:	0f b7 45 f4          	movzwl -0xc(%ebp),%eax
c0100172:	0f b7 d0             	movzwl %ax,%edx
c0100175:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c010017a:	83 ec 04             	sub    $0x4,%esp
c010017d:	52                   	push   %edx
c010017e:	50                   	push   %eax
c010017f:	68 dd 5b 10 c0       	push   $0xc0105bdd
c0100184:	e8 f4 00 00 00       	call   c010027d <cprintf>
c0100189:	83 c4 10             	add    $0x10,%esp
    cprintf("%d:  es = %x\n", round, reg3);
c010018c:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c0100190:	0f b7 d0             	movzwl %ax,%edx
c0100193:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c0100198:	83 ec 04             	sub    $0x4,%esp
c010019b:	52                   	push   %edx
c010019c:	50                   	push   %eax
c010019d:	68 eb 5b 10 c0       	push   $0xc0105beb
c01001a2:	e8 d6 00 00 00       	call   c010027d <cprintf>
c01001a7:	83 c4 10             	add    $0x10,%esp
    cprintf("%d:  ss = %x\n", round, reg4);
c01001aa:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
c01001ae:	0f b7 d0             	movzwl %ax,%edx
c01001b1:	a1 00 a0 11 c0       	mov    0xc011a000,%eax
c01001b6:	83 ec 04             	sub    $0x4,%esp
c01001b9:	52                   	push   %edx
c01001ba:	50                   	push   %eax
c01001bb:	68 f9 5b 10 c0       	push   $0xc0105bf9
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
c01001fc:	68 08 5c 10 c0       	push   $0xc0105c08
c0100201:	e8 77 00 00 00       	call   c010027d <cprintf>
c0100206:	83 c4 10             	add    $0x10,%esp
    lab1_switch_to_user();
c0100209:	e8 ca ff ff ff       	call   c01001d8 <lab1_switch_to_user>
    lab1_print_cur_status();
c010020e:	e8 08 ff ff ff       	call   c010011b <lab1_print_cur_status>
    cprintf("+++ switch to kernel mode +++\n");
c0100213:	83 ec 0c             	sub    $0xc,%esp
c0100216:	68 28 5c 10 c0       	push   $0xc0105c28
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
c0100270:	e8 bf 54 00 00       	call   c0105734 <vprintfmt>
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
c0100333:	68 47 5c 10 c0       	push   $0xc0105c47
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
c010040b:	68 4a 5c 10 c0       	push   $0xc0105c4a
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
c010042d:	68 66 5c 10 c0       	push   $0xc0105c66
c0100432:	e8 46 fe ff ff       	call   c010027d <cprintf>
c0100437:	83 c4 10             	add    $0x10,%esp
    
    cprintf("stack trackback:\n");
c010043a:	83 ec 0c             	sub    $0xc,%esp
c010043d:	68 68 5c 10 c0       	push   $0xc0105c68
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
c010047b:	68 7a 5c 10 c0       	push   $0xc0105c7a
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
c010049d:	68 66 5c 10 c0       	push   $0xc0105c66
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
c0100617:	c7 00 98 5c 10 c0    	movl   $0xc0105c98,(%eax)
    info->eip_line = 0;
c010061d:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100620:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
    info->eip_fn_name = "<unknown>";
c0100627:	8b 45 0c             	mov    0xc(%ebp),%eax
c010062a:	c7 40 08 98 5c 10 c0 	movl   $0xc0105c98,0x8(%eax)
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
c010064e:	c7 45 f4 2c 6f 10 c0 	movl   $0xc0106f2c,-0xc(%ebp)
    stab_end = __STAB_END__;
c0100655:	c7 45 f0 58 1e 11 c0 	movl   $0xc0111e58,-0x10(%ebp)
    stabstr = __STABSTR_BEGIN__;
c010065c:	c7 45 ec 59 1e 11 c0 	movl   $0xc0111e59,-0x14(%ebp)
    stabstr_end = __STABSTR_END__;
c0100663:	c7 45 e8 d4 48 11 c0 	movl   $0xc01148d4,-0x18(%ebp)

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
c010079d:	e8 d0 4a 00 00       	call   c0105272 <strfind>
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
c0100925:	68 a2 5c 10 c0       	push   $0xc0105ca2
c010092a:	e8 4e f9 ff ff       	call   c010027d <cprintf>
c010092f:	83 c4 10             	add    $0x10,%esp
    cprintf("  entry  0x%08x (phys)\n", kern_init);
c0100932:	83 ec 08             	sub    $0x8,%esp
c0100935:	68 36 00 10 c0       	push   $0xc0100036
c010093a:	68 bb 5c 10 c0       	push   $0xc0105cbb
c010093f:	e8 39 f9 ff ff       	call   c010027d <cprintf>
c0100944:	83 c4 10             	add    $0x10,%esp
    cprintf("  etext  0x%08x (phys)\n", etext);
c0100947:	83 ec 08             	sub    $0x8,%esp
c010094a:	68 95 5b 10 c0       	push   $0xc0105b95
c010094f:	68 d3 5c 10 c0       	push   $0xc0105cd3
c0100954:	e8 24 f9 ff ff       	call   c010027d <cprintf>
c0100959:	83 c4 10             	add    $0x10,%esp
    cprintf("  edata  0x%08x (phys)\n", edata);
c010095c:	83 ec 08             	sub    $0x8,%esp
c010095f:	68 00 a0 11 c0       	push   $0xc011a000
c0100964:	68 eb 5c 10 c0       	push   $0xc0105ceb
c0100969:	e8 0f f9 ff ff       	call   c010027d <cprintf>
c010096e:	83 c4 10             	add    $0x10,%esp
    cprintf("  end    0x%08x (phys)\n", end);
c0100971:	83 ec 08             	sub    $0x8,%esp
c0100974:	68 28 af 11 c0       	push   $0xc011af28
c0100979:	68 03 5d 10 c0       	push   $0xc0105d03
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
c01009a9:	68 1c 5d 10 c0       	push   $0xc0105d1c
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
c01009de:	68 46 5d 10 c0       	push   $0xc0105d46
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
c0100a45:	68 62 5d 10 c0       	push   $0xc0105d62
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
c0100abc:	68 74 5d 10 c0       	push   $0xc0105d74
c0100ac1:	e8 b7 f7 ff ff       	call   c010027d <cprintf>
c0100ac6:	83 c4 20             	add    $0x20,%esp
             ebp,eip,call_arguments[0],call_arguments[1],
             call_arguments[2],call_arguments[3]);
     cprintf("\n");
c0100ac9:	83 ec 0c             	sub    $0xc,%esp
c0100acc:	68 ab 5d 10 c0       	push   $0xc0105dab
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
c0100b4a:	68 30 5e 10 c0       	push   $0xc0105e30
c0100b4f:	e8 eb 46 00 00       	call   c010523f <strchr>
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
c0100b70:	68 35 5e 10 c0       	push   $0xc0105e35
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
c0100bb8:	68 30 5e 10 c0       	push   $0xc0105e30
c0100bbd:	e8 7d 46 00 00       	call   c010523f <strchr>
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
c0100c23:	e8 77 45 00 00       	call   c010519f <strcmp>
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
c0100c70:	68 53 5e 10 c0       	push   $0xc0105e53
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
c0100c8d:	68 6c 5e 10 c0       	push   $0xc0105e6c
c0100c92:	e8 e6 f5 ff ff       	call   c010027d <cprintf>
c0100c97:	83 c4 10             	add    $0x10,%esp
    cprintf("Type 'help' for a list of commands.\n");
c0100c9a:	83 ec 0c             	sub    $0xc,%esp
c0100c9d:	68 94 5e 10 c0       	push   $0xc0105e94
c0100ca2:	e8 d6 f5 ff ff       	call   c010027d <cprintf>
c0100ca7:	83 c4 10             	add    $0x10,%esp

    if (tf != NULL) {
c0100caa:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0100cae:	74 0e                	je     c0100cbe <kmonitor+0x3a>
        print_trapframe(tf);
c0100cb0:	83 ec 0c             	sub    $0xc,%esp
c0100cb3:	ff 75 08             	pushl  0x8(%ebp)
c0100cb6:	e8 40 0d 00 00       	call   c01019fb <print_trapframe>
c0100cbb:	83 c4 10             	add    $0x10,%esp
    }

    char *buf;
    while (1) {
        if ((buf = readline("K> ")) != NULL) {
c0100cbe:	83 ec 0c             	sub    $0xc,%esp
c0100cc1:	68 b9 5e 10 c0       	push   $0xc0105eb9
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
c0100d2c:	68 bd 5e 10 c0       	push   $0xc0105ebd
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
c0100dbc:	68 c6 5e 10 c0       	push   $0xc0105ec6
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
c01011e5:	e8 54 42 00 00       	call   c010543e <memmove>
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
c0101570:	68 e1 5e 10 c0       	push   $0xc0105ee1
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
c01015ea:	68 ed 5e 10 c0       	push   $0xc0105eed
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
c0101891:	68 20 5f 10 c0       	push   $0xc0105f20
c0101896:	e8 e2 e9 ff ff       	call   c010027d <cprintf>
c010189b:	83 c4 10             	add    $0x10,%esp
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
c010189e:	83 ec 0c             	sub    $0xc,%esp
c01018a1:	68 2a 5f 10 c0       	push   $0xc0105f2a
c01018a6:	e8 d2 e9 ff ff       	call   c010027d <cprintf>
c01018ab:	83 c4 10             	add    $0x10,%esp
    panic("EOT: kernel seems ok.");
c01018ae:	83 ec 04             	sub    $0x4,%esp
c01018b1:	68 38 5f 10 c0       	push   $0xc0105f38
c01018b6:	6a 12                	push   $0x12
c01018b8:	68 4e 5f 10 c0       	push   $0xc0105f4e
c01018bd:	e8 21 eb ff ff       	call   c01003e3 <__panic>

c01018c2 <idt_init>:
    sizeof(idt) - 1, (uintptr_t)idt
};

/* idt_init - initialize IDT to each of the entry points in kern/trap/vectors.S */
void
idt_init(void) {
c01018c2:	55                   	push   %ebp
c01018c3:	89 e5                	mov    %esp,%ebp
c01018c5:	83 ec 10             	sub    $0x10,%esp
      * (3) After setup the contents of IDT, you will let CPU know where is the IDT by using 'lidt' instruction.
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
      extern uintptr_t __vectors[];
      for(int i=0;i<256;i++){
c01018c8:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c01018cf:	e9 c3 00 00 00       	jmp    c0101997 <idt_init+0xd5>
      SETGATE(idt[i],0,GD_KTEXT,__vectors[i],DPL_KERNEL);
c01018d4:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018d7:	8b 04 85 e0 75 11 c0 	mov    -0x3fee8a20(,%eax,4),%eax
c01018de:	89 c2                	mov    %eax,%edx
c01018e0:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018e3:	66 89 14 c5 80 a6 11 	mov    %dx,-0x3fee5980(,%eax,8)
c01018ea:	c0 
c01018eb:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018ee:	66 c7 04 c5 82 a6 11 	movw   $0x8,-0x3fee597e(,%eax,8)
c01018f5:	c0 08 00 
c01018f8:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01018fb:	0f b6 14 c5 84 a6 11 	movzbl -0x3fee597c(,%eax,8),%edx
c0101902:	c0 
c0101903:	83 e2 e0             	and    $0xffffffe0,%edx
c0101906:	88 14 c5 84 a6 11 c0 	mov    %dl,-0x3fee597c(,%eax,8)
c010190d:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101910:	0f b6 14 c5 84 a6 11 	movzbl -0x3fee597c(,%eax,8),%edx
c0101917:	c0 
c0101918:	83 e2 1f             	and    $0x1f,%edx
c010191b:	88 14 c5 84 a6 11 c0 	mov    %dl,-0x3fee597c(,%eax,8)
c0101922:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101925:	0f b6 14 c5 85 a6 11 	movzbl -0x3fee597b(,%eax,8),%edx
c010192c:	c0 
c010192d:	83 e2 f0             	and    $0xfffffff0,%edx
c0101930:	83 ca 0e             	or     $0xe,%edx
c0101933:	88 14 c5 85 a6 11 c0 	mov    %dl,-0x3fee597b(,%eax,8)
c010193a:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010193d:	0f b6 14 c5 85 a6 11 	movzbl -0x3fee597b(,%eax,8),%edx
c0101944:	c0 
c0101945:	83 e2 ef             	and    $0xffffffef,%edx
c0101948:	88 14 c5 85 a6 11 c0 	mov    %dl,-0x3fee597b(,%eax,8)
c010194f:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101952:	0f b6 14 c5 85 a6 11 	movzbl -0x3fee597b(,%eax,8),%edx
c0101959:	c0 
c010195a:	83 e2 9f             	and    $0xffffff9f,%edx
c010195d:	88 14 c5 85 a6 11 c0 	mov    %dl,-0x3fee597b(,%eax,8)
c0101964:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101967:	0f b6 14 c5 85 a6 11 	movzbl -0x3fee597b(,%eax,8),%edx
c010196e:	c0 
c010196f:	83 ca 80             	or     $0xffffff80,%edx
c0101972:	88 14 c5 85 a6 11 c0 	mov    %dl,-0x3fee597b(,%eax,8)
c0101979:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010197c:	8b 04 85 e0 75 11 c0 	mov    -0x3fee8a20(,%eax,4),%eax
c0101983:	c1 e8 10             	shr    $0x10,%eax
c0101986:	89 c2                	mov    %eax,%edx
c0101988:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010198b:	66 89 14 c5 86 a6 11 	mov    %dx,-0x3fee597a(,%eax,8)
c0101992:	c0 
      * (3) After setup the contents of IDT, you will let CPU know where is the IDT by using 'lidt' instruction.
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
      extern uintptr_t __vectors[];
      for(int i=0;i<256;i++){
c0101993:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c0101997:	81 7d fc ff 00 00 00 	cmpl   $0xff,-0x4(%ebp)
c010199e:	0f 8e 30 ff ff ff    	jle    c01018d4 <idt_init+0x12>
c01019a4:	c7 45 f8 60 75 11 c0 	movl   $0xc0117560,-0x8(%ebp)
    }
}

static inline void
lidt(struct pseudodesc *pd) {
    asm volatile ("lidt (%0)" :: "r" (pd) : "memory");
c01019ab:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01019ae:	0f 01 18             	lidtl  (%eax)
      }
      //SETGATE(idt[T_SWITCH_TOK],1,KERNEL_CS,__vectors[T_SWITCH_TOK],DPL_USER);
      lidt(&idt_pd);
      
      
}
c01019b1:	90                   	nop
c01019b2:	c9                   	leave  
c01019b3:	c3                   	ret    

c01019b4 <trapname>:

static const char *
trapname(int trapno) {
c01019b4:	55                   	push   %ebp
c01019b5:	89 e5                	mov    %esp,%ebp
        "Alignment Check",
        "Machine-Check",
        "SIMD Floating-Point Exception"
    };

    if (trapno < sizeof(excnames)/sizeof(const char * const)) {
c01019b7:	8b 45 08             	mov    0x8(%ebp),%eax
c01019ba:	83 f8 13             	cmp    $0x13,%eax
c01019bd:	77 0c                	ja     c01019cb <trapname+0x17>
        return excnames[trapno];
c01019bf:	8b 45 08             	mov    0x8(%ebp),%eax
c01019c2:	8b 04 85 a0 62 10 c0 	mov    -0x3fef9d60(,%eax,4),%eax
c01019c9:	eb 18                	jmp    c01019e3 <trapname+0x2f>
    }
    if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16) {
c01019cb:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
c01019cf:	7e 0d                	jle    c01019de <trapname+0x2a>
c01019d1:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
c01019d5:	7f 07                	jg     c01019de <trapname+0x2a>
        return "Hardware Interrupt";
c01019d7:	b8 5f 5f 10 c0       	mov    $0xc0105f5f,%eax
c01019dc:	eb 05                	jmp    c01019e3 <trapname+0x2f>
    }
    return "(unknown trap)";
c01019de:	b8 72 5f 10 c0       	mov    $0xc0105f72,%eax
}
c01019e3:	5d                   	pop    %ebp
c01019e4:	c3                   	ret    

c01019e5 <trap_in_kernel>:

/* trap_in_kernel - test if trap happened in kernel */
bool
trap_in_kernel(struct trapframe *tf) {
c01019e5:	55                   	push   %ebp
c01019e6:	89 e5                	mov    %esp,%ebp
    return (tf->tf_cs == (uint16_t)KERNEL_CS);
c01019e8:	8b 45 08             	mov    0x8(%ebp),%eax
c01019eb:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c01019ef:	66 83 f8 08          	cmp    $0x8,%ax
c01019f3:	0f 94 c0             	sete   %al
c01019f6:	0f b6 c0             	movzbl %al,%eax
}
c01019f9:	5d                   	pop    %ebp
c01019fa:	c3                   	ret    

c01019fb <print_trapframe>:
    "TF", "IF", "DF", "OF", NULL, NULL, "NT", NULL,
    "RF", "VM", "AC", "VIF", "VIP", "ID", NULL, NULL,
};

void
print_trapframe(struct trapframe *tf) {
c01019fb:	55                   	push   %ebp
c01019fc:	89 e5                	mov    %esp,%ebp
c01019fe:	83 ec 18             	sub    $0x18,%esp
    cprintf("trapframe at %p\n", tf);
c0101a01:	83 ec 08             	sub    $0x8,%esp
c0101a04:	ff 75 08             	pushl  0x8(%ebp)
c0101a07:	68 b3 5f 10 c0       	push   $0xc0105fb3
c0101a0c:	e8 6c e8 ff ff       	call   c010027d <cprintf>
c0101a11:	83 c4 10             	add    $0x10,%esp
    print_regs(&tf->tf_regs);
c0101a14:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a17:	83 ec 0c             	sub    $0xc,%esp
c0101a1a:	50                   	push   %eax
c0101a1b:	e8 b8 01 00 00       	call   c0101bd8 <print_regs>
c0101a20:	83 c4 10             	add    $0x10,%esp
    cprintf("  ds   0x----%04x\n", tf->tf_ds);
c0101a23:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a26:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
c0101a2a:	0f b7 c0             	movzwl %ax,%eax
c0101a2d:	83 ec 08             	sub    $0x8,%esp
c0101a30:	50                   	push   %eax
c0101a31:	68 c4 5f 10 c0       	push   $0xc0105fc4
c0101a36:	e8 42 e8 ff ff       	call   c010027d <cprintf>
c0101a3b:	83 c4 10             	add    $0x10,%esp
    cprintf("  es   0x----%04x\n", tf->tf_es);
c0101a3e:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a41:	0f b7 40 28          	movzwl 0x28(%eax),%eax
c0101a45:	0f b7 c0             	movzwl %ax,%eax
c0101a48:	83 ec 08             	sub    $0x8,%esp
c0101a4b:	50                   	push   %eax
c0101a4c:	68 d7 5f 10 c0       	push   $0xc0105fd7
c0101a51:	e8 27 e8 ff ff       	call   c010027d <cprintf>
c0101a56:	83 c4 10             	add    $0x10,%esp
    cprintf("  fs   0x----%04x\n", tf->tf_fs);
c0101a59:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a5c:	0f b7 40 24          	movzwl 0x24(%eax),%eax
c0101a60:	0f b7 c0             	movzwl %ax,%eax
c0101a63:	83 ec 08             	sub    $0x8,%esp
c0101a66:	50                   	push   %eax
c0101a67:	68 ea 5f 10 c0       	push   $0xc0105fea
c0101a6c:	e8 0c e8 ff ff       	call   c010027d <cprintf>
c0101a71:	83 c4 10             	add    $0x10,%esp
    cprintf("  gs   0x----%04x\n", tf->tf_gs);
c0101a74:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a77:	0f b7 40 20          	movzwl 0x20(%eax),%eax
c0101a7b:	0f b7 c0             	movzwl %ax,%eax
c0101a7e:	83 ec 08             	sub    $0x8,%esp
c0101a81:	50                   	push   %eax
c0101a82:	68 fd 5f 10 c0       	push   $0xc0105ffd
c0101a87:	e8 f1 e7 ff ff       	call   c010027d <cprintf>
c0101a8c:	83 c4 10             	add    $0x10,%esp
    cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
c0101a8f:	8b 45 08             	mov    0x8(%ebp),%eax
c0101a92:	8b 40 30             	mov    0x30(%eax),%eax
c0101a95:	83 ec 0c             	sub    $0xc,%esp
c0101a98:	50                   	push   %eax
c0101a99:	e8 16 ff ff ff       	call   c01019b4 <trapname>
c0101a9e:	83 c4 10             	add    $0x10,%esp
c0101aa1:	89 c2                	mov    %eax,%edx
c0101aa3:	8b 45 08             	mov    0x8(%ebp),%eax
c0101aa6:	8b 40 30             	mov    0x30(%eax),%eax
c0101aa9:	83 ec 04             	sub    $0x4,%esp
c0101aac:	52                   	push   %edx
c0101aad:	50                   	push   %eax
c0101aae:	68 10 60 10 c0       	push   $0xc0106010
c0101ab3:	e8 c5 e7 ff ff       	call   c010027d <cprintf>
c0101ab8:	83 c4 10             	add    $0x10,%esp
    cprintf("  err  0x%08x\n", tf->tf_err);
c0101abb:	8b 45 08             	mov    0x8(%ebp),%eax
c0101abe:	8b 40 34             	mov    0x34(%eax),%eax
c0101ac1:	83 ec 08             	sub    $0x8,%esp
c0101ac4:	50                   	push   %eax
c0101ac5:	68 22 60 10 c0       	push   $0xc0106022
c0101aca:	e8 ae e7 ff ff       	call   c010027d <cprintf>
c0101acf:	83 c4 10             	add    $0x10,%esp
    cprintf("  eip  0x%08x\n", tf->tf_eip);
c0101ad2:	8b 45 08             	mov    0x8(%ebp),%eax
c0101ad5:	8b 40 38             	mov    0x38(%eax),%eax
c0101ad8:	83 ec 08             	sub    $0x8,%esp
c0101adb:	50                   	push   %eax
c0101adc:	68 31 60 10 c0       	push   $0xc0106031
c0101ae1:	e8 97 e7 ff ff       	call   c010027d <cprintf>
c0101ae6:	83 c4 10             	add    $0x10,%esp
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
c0101ae9:	8b 45 08             	mov    0x8(%ebp),%eax
c0101aec:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101af0:	0f b7 c0             	movzwl %ax,%eax
c0101af3:	83 ec 08             	sub    $0x8,%esp
c0101af6:	50                   	push   %eax
c0101af7:	68 40 60 10 c0       	push   $0xc0106040
c0101afc:	e8 7c e7 ff ff       	call   c010027d <cprintf>
c0101b01:	83 c4 10             	add    $0x10,%esp
    cprintf("  flag 0x%08x ", tf->tf_eflags);
c0101b04:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b07:	8b 40 40             	mov    0x40(%eax),%eax
c0101b0a:	83 ec 08             	sub    $0x8,%esp
c0101b0d:	50                   	push   %eax
c0101b0e:	68 53 60 10 c0       	push   $0xc0106053
c0101b13:	e8 65 e7 ff ff       	call   c010027d <cprintf>
c0101b18:	83 c4 10             	add    $0x10,%esp

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
c0101b1b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0101b22:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
c0101b29:	eb 3f                	jmp    c0101b6a <print_trapframe+0x16f>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
c0101b2b:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b2e:	8b 50 40             	mov    0x40(%eax),%edx
c0101b31:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0101b34:	21 d0                	and    %edx,%eax
c0101b36:	85 c0                	test   %eax,%eax
c0101b38:	74 29                	je     c0101b63 <print_trapframe+0x168>
c0101b3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101b3d:	8b 04 85 80 75 11 c0 	mov    -0x3fee8a80(,%eax,4),%eax
c0101b44:	85 c0                	test   %eax,%eax
c0101b46:	74 1b                	je     c0101b63 <print_trapframe+0x168>
            cprintf("%s,", IA32flags[i]);
c0101b48:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101b4b:	8b 04 85 80 75 11 c0 	mov    -0x3fee8a80(,%eax,4),%eax
c0101b52:	83 ec 08             	sub    $0x8,%esp
c0101b55:	50                   	push   %eax
c0101b56:	68 62 60 10 c0       	push   $0xc0106062
c0101b5b:	e8 1d e7 ff ff       	call   c010027d <cprintf>
c0101b60:	83 c4 10             	add    $0x10,%esp
    cprintf("  eip  0x%08x\n", tf->tf_eip);
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
    cprintf("  flag 0x%08x ", tf->tf_eflags);

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
c0101b63:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0101b67:	d1 65 f0             	shll   -0x10(%ebp)
c0101b6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101b6d:	83 f8 17             	cmp    $0x17,%eax
c0101b70:	76 b9                	jbe    c0101b2b <print_trapframe+0x130>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
            cprintf("%s,", IA32flags[i]);
        }
    }
    cprintf("IOPL=%d\n", (tf->tf_eflags & FL_IOPL_MASK) >> 12);
c0101b72:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b75:	8b 40 40             	mov    0x40(%eax),%eax
c0101b78:	25 00 30 00 00       	and    $0x3000,%eax
c0101b7d:	c1 e8 0c             	shr    $0xc,%eax
c0101b80:	83 ec 08             	sub    $0x8,%esp
c0101b83:	50                   	push   %eax
c0101b84:	68 66 60 10 c0       	push   $0xc0106066
c0101b89:	e8 ef e6 ff ff       	call   c010027d <cprintf>
c0101b8e:	83 c4 10             	add    $0x10,%esp

    if (!trap_in_kernel(tf)) {
c0101b91:	83 ec 0c             	sub    $0xc,%esp
c0101b94:	ff 75 08             	pushl  0x8(%ebp)
c0101b97:	e8 49 fe ff ff       	call   c01019e5 <trap_in_kernel>
c0101b9c:	83 c4 10             	add    $0x10,%esp
c0101b9f:	85 c0                	test   %eax,%eax
c0101ba1:	75 32                	jne    c0101bd5 <print_trapframe+0x1da>
        cprintf("  esp  0x%08x\n", tf->tf_esp);
c0101ba3:	8b 45 08             	mov    0x8(%ebp),%eax
c0101ba6:	8b 40 44             	mov    0x44(%eax),%eax
c0101ba9:	83 ec 08             	sub    $0x8,%esp
c0101bac:	50                   	push   %eax
c0101bad:	68 6f 60 10 c0       	push   $0xc010606f
c0101bb2:	e8 c6 e6 ff ff       	call   c010027d <cprintf>
c0101bb7:	83 c4 10             	add    $0x10,%esp
        cprintf("  ss   0x----%04x\n", tf->tf_ss);
c0101bba:	8b 45 08             	mov    0x8(%ebp),%eax
c0101bbd:	0f b7 40 48          	movzwl 0x48(%eax),%eax
c0101bc1:	0f b7 c0             	movzwl %ax,%eax
c0101bc4:	83 ec 08             	sub    $0x8,%esp
c0101bc7:	50                   	push   %eax
c0101bc8:	68 7e 60 10 c0       	push   $0xc010607e
c0101bcd:	e8 ab e6 ff ff       	call   c010027d <cprintf>
c0101bd2:	83 c4 10             	add    $0x10,%esp
    }
}
c0101bd5:	90                   	nop
c0101bd6:	c9                   	leave  
c0101bd7:	c3                   	ret    

c0101bd8 <print_regs>:

void
print_regs(struct pushregs *regs) {
c0101bd8:	55                   	push   %ebp
c0101bd9:	89 e5                	mov    %esp,%ebp
c0101bdb:	83 ec 08             	sub    $0x8,%esp
    cprintf("  edi  0x%08x\n", regs->reg_edi);
c0101bde:	8b 45 08             	mov    0x8(%ebp),%eax
c0101be1:	8b 00                	mov    (%eax),%eax
c0101be3:	83 ec 08             	sub    $0x8,%esp
c0101be6:	50                   	push   %eax
c0101be7:	68 91 60 10 c0       	push   $0xc0106091
c0101bec:	e8 8c e6 ff ff       	call   c010027d <cprintf>
c0101bf1:	83 c4 10             	add    $0x10,%esp
    cprintf("  esi  0x%08x\n", regs->reg_esi);
c0101bf4:	8b 45 08             	mov    0x8(%ebp),%eax
c0101bf7:	8b 40 04             	mov    0x4(%eax),%eax
c0101bfa:	83 ec 08             	sub    $0x8,%esp
c0101bfd:	50                   	push   %eax
c0101bfe:	68 a0 60 10 c0       	push   $0xc01060a0
c0101c03:	e8 75 e6 ff ff       	call   c010027d <cprintf>
c0101c08:	83 c4 10             	add    $0x10,%esp
    cprintf("  ebp  0x%08x\n", regs->reg_ebp);
c0101c0b:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c0e:	8b 40 08             	mov    0x8(%eax),%eax
c0101c11:	83 ec 08             	sub    $0x8,%esp
c0101c14:	50                   	push   %eax
c0101c15:	68 af 60 10 c0       	push   $0xc01060af
c0101c1a:	e8 5e e6 ff ff       	call   c010027d <cprintf>
c0101c1f:	83 c4 10             	add    $0x10,%esp
    cprintf("  oesp 0x%08x\n", regs->reg_oesp);
c0101c22:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c25:	8b 40 0c             	mov    0xc(%eax),%eax
c0101c28:	83 ec 08             	sub    $0x8,%esp
c0101c2b:	50                   	push   %eax
c0101c2c:	68 be 60 10 c0       	push   $0xc01060be
c0101c31:	e8 47 e6 ff ff       	call   c010027d <cprintf>
c0101c36:	83 c4 10             	add    $0x10,%esp
    cprintf("  ebx  0x%08x\n", regs->reg_ebx);
c0101c39:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c3c:	8b 40 10             	mov    0x10(%eax),%eax
c0101c3f:	83 ec 08             	sub    $0x8,%esp
c0101c42:	50                   	push   %eax
c0101c43:	68 cd 60 10 c0       	push   $0xc01060cd
c0101c48:	e8 30 e6 ff ff       	call   c010027d <cprintf>
c0101c4d:	83 c4 10             	add    $0x10,%esp
    cprintf("  edx  0x%08x\n", regs->reg_edx);
c0101c50:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c53:	8b 40 14             	mov    0x14(%eax),%eax
c0101c56:	83 ec 08             	sub    $0x8,%esp
c0101c59:	50                   	push   %eax
c0101c5a:	68 dc 60 10 c0       	push   $0xc01060dc
c0101c5f:	e8 19 e6 ff ff       	call   c010027d <cprintf>
c0101c64:	83 c4 10             	add    $0x10,%esp
    cprintf("  ecx  0x%08x\n", regs->reg_ecx);
c0101c67:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c6a:	8b 40 18             	mov    0x18(%eax),%eax
c0101c6d:	83 ec 08             	sub    $0x8,%esp
c0101c70:	50                   	push   %eax
c0101c71:	68 eb 60 10 c0       	push   $0xc01060eb
c0101c76:	e8 02 e6 ff ff       	call   c010027d <cprintf>
c0101c7b:	83 c4 10             	add    $0x10,%esp
    cprintf("  eax  0x%08x\n", regs->reg_eax);
c0101c7e:	8b 45 08             	mov    0x8(%ebp),%eax
c0101c81:	8b 40 1c             	mov    0x1c(%eax),%eax
c0101c84:	83 ec 08             	sub    $0x8,%esp
c0101c87:	50                   	push   %eax
c0101c88:	68 fa 60 10 c0       	push   $0xc01060fa
c0101c8d:	e8 eb e5 ff ff       	call   c010027d <cprintf>
c0101c92:	83 c4 10             	add    $0x10,%esp
}
c0101c95:	90                   	nop
c0101c96:	c9                   	leave  
c0101c97:	c3                   	ret    

c0101c98 <trap_dispatch>:

/* trap_dispatch - dispatch based on what type of trap occurred */
static void
trap_dispatch(struct trapframe *tf) {
c0101c98:	55                   	push   %ebp
c0101c99:	89 e5                	mov    %esp,%ebp
c0101c9b:	83 ec 18             	sub    $0x18,%esp
    char c;

    switch (tf->tf_trapno) {
c0101c9e:	8b 45 08             	mov    0x8(%ebp),%eax
c0101ca1:	8b 40 30             	mov    0x30(%eax),%eax
c0101ca4:	83 f8 2f             	cmp    $0x2f,%eax
c0101ca7:	77 21                	ja     c0101cca <trap_dispatch+0x32>
c0101ca9:	83 f8 2e             	cmp    $0x2e,%eax
c0101cac:	0f 83 be 01 00 00    	jae    c0101e70 <trap_dispatch+0x1d8>
c0101cb2:	83 f8 21             	cmp    $0x21,%eax
c0101cb5:	0f 84 91 00 00 00    	je     c0101d4c <trap_dispatch+0xb4>
c0101cbb:	83 f8 24             	cmp    $0x24,%eax
c0101cbe:	74 65                	je     c0101d25 <trap_dispatch+0x8d>
c0101cc0:	83 f8 20             	cmp    $0x20,%eax
c0101cc3:	74 1c                	je     c0101ce1 <trap_dispatch+0x49>
c0101cc5:	e9 70 01 00 00       	jmp    c0101e3a <trap_dispatch+0x1a2>
c0101cca:	83 f8 78             	cmp    $0x78,%eax
c0101ccd:	0f 84 a0 00 00 00    	je     c0101d73 <trap_dispatch+0xdb>
c0101cd3:	83 f8 79             	cmp    $0x79,%eax
c0101cd6:	0f 84 fe 00 00 00    	je     c0101dda <trap_dispatch+0x142>
c0101cdc:	e9 59 01 00 00       	jmp    c0101e3a <trap_dispatch+0x1a2>
        /* handle the timer interrupt */
        /* (1) After a timer interrupt, you should record this event using a global variable (increase it), such as ticks in kern/driver/clock.c
         * (2) Every TICK_NUM cycle, you can print some info using a funciton, such as print_ticks().
         * (3) Too Simple? Yes, I think so!
         */
        ticks++;
c0101ce1:	a1 0c af 11 c0       	mov    0xc011af0c,%eax
c0101ce6:	83 c0 01             	add    $0x1,%eax
c0101ce9:	a3 0c af 11 c0       	mov    %eax,0xc011af0c
        if(ticks % TICK_NUM == 0){
c0101cee:	8b 0d 0c af 11 c0    	mov    0xc011af0c,%ecx
c0101cf4:	ba 1f 85 eb 51       	mov    $0x51eb851f,%edx
c0101cf9:	89 c8                	mov    %ecx,%eax
c0101cfb:	f7 e2                	mul    %edx
c0101cfd:	89 d0                	mov    %edx,%eax
c0101cff:	c1 e8 05             	shr    $0x5,%eax
c0101d02:	6b c0 64             	imul   $0x64,%eax,%eax
c0101d05:	29 c1                	sub    %eax,%ecx
c0101d07:	89 c8                	mov    %ecx,%eax
c0101d09:	85 c0                	test   %eax,%eax
c0101d0b:	0f 85 62 01 00 00    	jne    c0101e73 <trap_dispatch+0x1db>
            print_ticks();
c0101d11:	e8 70 fb ff ff       	call   c0101886 <print_ticks>
            ticks=0;
c0101d16:	c7 05 0c af 11 c0 00 	movl   $0x0,0xc011af0c
c0101d1d:	00 00 00 
        }
        break;
c0101d20:	e9 4e 01 00 00       	jmp    c0101e73 <trap_dispatch+0x1db>
    case IRQ_OFFSET + IRQ_COM1:
        c = cons_getc();
c0101d25:	e8 19 f9 ff ff       	call   c0101643 <cons_getc>
c0101d2a:	88 45 f7             	mov    %al,-0x9(%ebp)
        cprintf("serial [%03d] %c\n", c, c);
c0101d2d:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
c0101d31:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c0101d35:	83 ec 04             	sub    $0x4,%esp
c0101d38:	52                   	push   %edx
c0101d39:	50                   	push   %eax
c0101d3a:	68 09 61 10 c0       	push   $0xc0106109
c0101d3f:	e8 39 e5 ff ff       	call   c010027d <cprintf>
c0101d44:	83 c4 10             	add    $0x10,%esp
	
	
        break;
c0101d47:	e9 2e 01 00 00       	jmp    c0101e7a <trap_dispatch+0x1e2>
    case IRQ_OFFSET + IRQ_KBD:
        c = cons_getc();
c0101d4c:	e8 f2 f8 ff ff       	call   c0101643 <cons_getc>
c0101d51:	88 45 f7             	mov    %al,-0x9(%ebp)
        cprintf("kbd [%03d] %c\n", c, c);
c0101d54:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
c0101d58:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c0101d5c:	83 ec 04             	sub    $0x4,%esp
c0101d5f:	52                   	push   %edx
c0101d60:	50                   	push   %eax
c0101d61:	68 1b 61 10 c0       	push   $0xc010611b
c0101d66:	e8 12 e5 ff ff       	call   c010027d <cprintf>
c0101d6b:	83 c4 10             	add    $0x10,%esp
	   tf->tf_ds=tf->tf_gs=tf->tf_fs=tf->tf_es = KERNEL_DS;
	   tf->tf_eflags = tf->tf_eflags&(~FL_IOPL_MASK);
	   print_trapframe(tf);
	   }
	}*/
        break;
c0101d6e:	e9 07 01 00 00       	jmp    c0101e7a <trap_dispatch+0x1e2>
    //LAB1 CHALLENGE 1 : YOUR CODE you should modify below codes.
    case T_SWITCH_TOU:
	if(tf->tf_cs !=USER_CS){
c0101d73:	8b 45 08             	mov    0x8(%ebp),%eax
c0101d76:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101d7a:	66 83 f8 1b          	cmp    $0x1b,%ax
c0101d7e:	0f 84 f2 00 00 00    	je     c0101e76 <trap_dispatch+0x1de>
	   tf->tf_cs=USER_CS;
c0101d84:	8b 45 08             	mov    0x8(%ebp),%eax
c0101d87:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
	   tf->tf_ds=USER_DS;
c0101d8d:	8b 45 08             	mov    0x8(%ebp),%eax
c0101d90:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
	   tf->tf_gs=tf->tf_fs=tf->tf_es = USER_DS;
c0101d96:	8b 45 08             	mov    0x8(%ebp),%eax
c0101d99:	66 c7 40 28 23 00    	movw   $0x23,0x28(%eax)
c0101d9f:	8b 45 08             	mov    0x8(%ebp),%eax
c0101da2:	0f b7 50 28          	movzwl 0x28(%eax),%edx
c0101da6:	8b 45 08             	mov    0x8(%ebp),%eax
c0101da9:	66 89 50 24          	mov    %dx,0x24(%eax)
c0101dad:	8b 45 08             	mov    0x8(%ebp),%eax
c0101db0:	0f b7 50 24          	movzwl 0x24(%eax),%edx
c0101db4:	8b 45 08             	mov    0x8(%ebp),%eax
c0101db7:	66 89 50 20          	mov    %dx,0x20(%eax)
	   tf->tf_eflags = tf->tf_eflags|FL_IOPL_MASK;
c0101dbb:	8b 45 08             	mov    0x8(%ebp),%eax
c0101dbe:	8b 40 40             	mov    0x40(%eax),%eax
c0101dc1:	80 cc 30             	or     $0x30,%ah
c0101dc4:	89 c2                	mov    %eax,%edx
c0101dc6:	8b 45 08             	mov    0x8(%ebp),%eax
c0101dc9:	89 50 40             	mov    %edx,0x40(%eax)
	   tf->tf_ss=USER_DS;
c0101dcc:	8b 45 08             	mov    0x8(%ebp),%eax
c0101dcf:	66 c7 40 48 23 00    	movw   $0x23,0x48(%eax)
	  }
	break;
c0101dd5:	e9 9c 00 00 00       	jmp    c0101e76 <trap_dispatch+0x1de>
    case T_SWITCH_TOK:
	if(tf->tf_cs !=KERNEL_CS){
c0101dda:	8b 45 08             	mov    0x8(%ebp),%eax
c0101ddd:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101de1:	66 83 f8 08          	cmp    $0x8,%ax
c0101de5:	0f 84 8e 00 00 00    	je     c0101e79 <trap_dispatch+0x1e1>
	   tf->tf_cs =KERNEL_CS;
c0101deb:	8b 45 08             	mov    0x8(%ebp),%eax
c0101dee:	66 c7 40 3c 08 00    	movw   $0x8,0x3c(%eax)
	   tf->tf_ds=tf->tf_gs=tf->tf_fs=tf->tf_es = KERNEL_DS;
c0101df4:	8b 45 08             	mov    0x8(%ebp),%eax
c0101df7:	66 c7 40 28 10 00    	movw   $0x10,0x28(%eax)
c0101dfd:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e00:	0f b7 50 28          	movzwl 0x28(%eax),%edx
c0101e04:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e07:	66 89 50 24          	mov    %dx,0x24(%eax)
c0101e0b:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e0e:	0f b7 50 24          	movzwl 0x24(%eax),%edx
c0101e12:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e15:	66 89 50 20          	mov    %dx,0x20(%eax)
c0101e19:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e1c:	0f b7 50 20          	movzwl 0x20(%eax),%edx
c0101e20:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e23:	66 89 50 2c          	mov    %dx,0x2c(%eax)
	   tf->tf_eflags = tf->tf_eflags&(~FL_IOPL_MASK);
c0101e27:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e2a:	8b 40 40             	mov    0x40(%eax),%eax
c0101e2d:	80 e4 cf             	and    $0xcf,%ah
c0101e30:	89 c2                	mov    %eax,%edx
c0101e32:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e35:	89 50 40             	mov    %edx,0x40(%eax)
	   
	}
        break;
c0101e38:	eb 3f                	jmp    c0101e79 <trap_dispatch+0x1e1>
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
    default:
        // in kernel, it must be a mistake
        if ((tf->tf_cs & 3) == 0) {
c0101e3a:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e3d:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0101e41:	0f b7 c0             	movzwl %ax,%eax
c0101e44:	83 e0 03             	and    $0x3,%eax
c0101e47:	85 c0                	test   %eax,%eax
c0101e49:	75 2f                	jne    c0101e7a <trap_dispatch+0x1e2>
            print_trapframe(tf);
c0101e4b:	83 ec 0c             	sub    $0xc,%esp
c0101e4e:	ff 75 08             	pushl  0x8(%ebp)
c0101e51:	e8 a5 fb ff ff       	call   c01019fb <print_trapframe>
c0101e56:	83 c4 10             	add    $0x10,%esp
            panic("unexpected trap in kernel.\n");
c0101e59:	83 ec 04             	sub    $0x4,%esp
c0101e5c:	68 2a 61 10 c0       	push   $0xc010612a
c0101e61:	68 da 00 00 00       	push   $0xda
c0101e66:	68 4e 5f 10 c0       	push   $0xc0105f4e
c0101e6b:	e8 73 e5 ff ff       	call   c01003e3 <__panic>
	}
        break;
    case IRQ_OFFSET + IRQ_IDE1:
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
c0101e70:	90                   	nop
c0101e71:	eb 07                	jmp    c0101e7a <trap_dispatch+0x1e2>
        ticks++;
        if(ticks % TICK_NUM == 0){
            print_ticks();
            ticks=0;
        }
        break;
c0101e73:	90                   	nop
c0101e74:	eb 04                	jmp    c0101e7a <trap_dispatch+0x1e2>
	   tf->tf_ds=USER_DS;
	   tf->tf_gs=tf->tf_fs=tf->tf_es = USER_DS;
	   tf->tf_eflags = tf->tf_eflags|FL_IOPL_MASK;
	   tf->tf_ss=USER_DS;
	  }
	break;
c0101e76:	90                   	nop
c0101e77:	eb 01                	jmp    c0101e7a <trap_dispatch+0x1e2>
	   tf->tf_cs =KERNEL_CS;
	   tf->tf_ds=tf->tf_gs=tf->tf_fs=tf->tf_es = KERNEL_DS;
	   tf->tf_eflags = tf->tf_eflags&(~FL_IOPL_MASK);
	   
	}
        break;
c0101e79:	90                   	nop
        if ((tf->tf_cs & 3) == 0) {
            print_trapframe(tf);
            panic("unexpected trap in kernel.\n");
        }
    }
}
c0101e7a:	90                   	nop
c0101e7b:	c9                   	leave  
c0101e7c:	c3                   	ret    

c0101e7d <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
c0101e7d:	55                   	push   %ebp
c0101e7e:	89 e5                	mov    %esp,%ebp
c0101e80:	83 ec 08             	sub    $0x8,%esp
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
c0101e83:	83 ec 0c             	sub    $0xc,%esp
c0101e86:	ff 75 08             	pushl  0x8(%ebp)
c0101e89:	e8 0a fe ff ff       	call   c0101c98 <trap_dispatch>
c0101e8e:	83 c4 10             	add    $0x10,%esp
}
c0101e91:	90                   	nop
c0101e92:	c9                   	leave  
c0101e93:	c3                   	ret    

c0101e94 <vector0>:
# handler
.text
.globl __alltraps
.globl vector0
vector0:
  pushl $0
c0101e94:	6a 00                	push   $0x0
  pushl $0
c0101e96:	6a 00                	push   $0x0
  jmp __alltraps
c0101e98:	e9 69 0a 00 00       	jmp    c0102906 <__alltraps>

c0101e9d <vector1>:
.globl vector1
vector1:
  pushl $0
c0101e9d:	6a 00                	push   $0x0
  pushl $1
c0101e9f:	6a 01                	push   $0x1
  jmp __alltraps
c0101ea1:	e9 60 0a 00 00       	jmp    c0102906 <__alltraps>

c0101ea6 <vector2>:
.globl vector2
vector2:
  pushl $0
c0101ea6:	6a 00                	push   $0x0
  pushl $2
c0101ea8:	6a 02                	push   $0x2
  jmp __alltraps
c0101eaa:	e9 57 0a 00 00       	jmp    c0102906 <__alltraps>

c0101eaf <vector3>:
.globl vector3
vector3:
  pushl $0
c0101eaf:	6a 00                	push   $0x0
  pushl $3
c0101eb1:	6a 03                	push   $0x3
  jmp __alltraps
c0101eb3:	e9 4e 0a 00 00       	jmp    c0102906 <__alltraps>

c0101eb8 <vector4>:
.globl vector4
vector4:
  pushl $0
c0101eb8:	6a 00                	push   $0x0
  pushl $4
c0101eba:	6a 04                	push   $0x4
  jmp __alltraps
c0101ebc:	e9 45 0a 00 00       	jmp    c0102906 <__alltraps>

c0101ec1 <vector5>:
.globl vector5
vector5:
  pushl $0
c0101ec1:	6a 00                	push   $0x0
  pushl $5
c0101ec3:	6a 05                	push   $0x5
  jmp __alltraps
c0101ec5:	e9 3c 0a 00 00       	jmp    c0102906 <__alltraps>

c0101eca <vector6>:
.globl vector6
vector6:
  pushl $0
c0101eca:	6a 00                	push   $0x0
  pushl $6
c0101ecc:	6a 06                	push   $0x6
  jmp __alltraps
c0101ece:	e9 33 0a 00 00       	jmp    c0102906 <__alltraps>

c0101ed3 <vector7>:
.globl vector7
vector7:
  pushl $0
c0101ed3:	6a 00                	push   $0x0
  pushl $7
c0101ed5:	6a 07                	push   $0x7
  jmp __alltraps
c0101ed7:	e9 2a 0a 00 00       	jmp    c0102906 <__alltraps>

c0101edc <vector8>:
.globl vector8
vector8:
  pushl $8
c0101edc:	6a 08                	push   $0x8
  jmp __alltraps
c0101ede:	e9 23 0a 00 00       	jmp    c0102906 <__alltraps>

c0101ee3 <vector9>:
.globl vector9
vector9:
  pushl $0
c0101ee3:	6a 00                	push   $0x0
  pushl $9
c0101ee5:	6a 09                	push   $0x9
  jmp __alltraps
c0101ee7:	e9 1a 0a 00 00       	jmp    c0102906 <__alltraps>

c0101eec <vector10>:
.globl vector10
vector10:
  pushl $10
c0101eec:	6a 0a                	push   $0xa
  jmp __alltraps
c0101eee:	e9 13 0a 00 00       	jmp    c0102906 <__alltraps>

c0101ef3 <vector11>:
.globl vector11
vector11:
  pushl $11
c0101ef3:	6a 0b                	push   $0xb
  jmp __alltraps
c0101ef5:	e9 0c 0a 00 00       	jmp    c0102906 <__alltraps>

c0101efa <vector12>:
.globl vector12
vector12:
  pushl $12
c0101efa:	6a 0c                	push   $0xc
  jmp __alltraps
c0101efc:	e9 05 0a 00 00       	jmp    c0102906 <__alltraps>

c0101f01 <vector13>:
.globl vector13
vector13:
  pushl $13
c0101f01:	6a 0d                	push   $0xd
  jmp __alltraps
c0101f03:	e9 fe 09 00 00       	jmp    c0102906 <__alltraps>

c0101f08 <vector14>:
.globl vector14
vector14:
  pushl $14
c0101f08:	6a 0e                	push   $0xe
  jmp __alltraps
c0101f0a:	e9 f7 09 00 00       	jmp    c0102906 <__alltraps>

c0101f0f <vector15>:
.globl vector15
vector15:
  pushl $0
c0101f0f:	6a 00                	push   $0x0
  pushl $15
c0101f11:	6a 0f                	push   $0xf
  jmp __alltraps
c0101f13:	e9 ee 09 00 00       	jmp    c0102906 <__alltraps>

c0101f18 <vector16>:
.globl vector16
vector16:
  pushl $0
c0101f18:	6a 00                	push   $0x0
  pushl $16
c0101f1a:	6a 10                	push   $0x10
  jmp __alltraps
c0101f1c:	e9 e5 09 00 00       	jmp    c0102906 <__alltraps>

c0101f21 <vector17>:
.globl vector17
vector17:
  pushl $17
c0101f21:	6a 11                	push   $0x11
  jmp __alltraps
c0101f23:	e9 de 09 00 00       	jmp    c0102906 <__alltraps>

c0101f28 <vector18>:
.globl vector18
vector18:
  pushl $0
c0101f28:	6a 00                	push   $0x0
  pushl $18
c0101f2a:	6a 12                	push   $0x12
  jmp __alltraps
c0101f2c:	e9 d5 09 00 00       	jmp    c0102906 <__alltraps>

c0101f31 <vector19>:
.globl vector19
vector19:
  pushl $0
c0101f31:	6a 00                	push   $0x0
  pushl $19
c0101f33:	6a 13                	push   $0x13
  jmp __alltraps
c0101f35:	e9 cc 09 00 00       	jmp    c0102906 <__alltraps>

c0101f3a <vector20>:
.globl vector20
vector20:
  pushl $0
c0101f3a:	6a 00                	push   $0x0
  pushl $20
c0101f3c:	6a 14                	push   $0x14
  jmp __alltraps
c0101f3e:	e9 c3 09 00 00       	jmp    c0102906 <__alltraps>

c0101f43 <vector21>:
.globl vector21
vector21:
  pushl $0
c0101f43:	6a 00                	push   $0x0
  pushl $21
c0101f45:	6a 15                	push   $0x15
  jmp __alltraps
c0101f47:	e9 ba 09 00 00       	jmp    c0102906 <__alltraps>

c0101f4c <vector22>:
.globl vector22
vector22:
  pushl $0
c0101f4c:	6a 00                	push   $0x0
  pushl $22
c0101f4e:	6a 16                	push   $0x16
  jmp __alltraps
c0101f50:	e9 b1 09 00 00       	jmp    c0102906 <__alltraps>

c0101f55 <vector23>:
.globl vector23
vector23:
  pushl $0
c0101f55:	6a 00                	push   $0x0
  pushl $23
c0101f57:	6a 17                	push   $0x17
  jmp __alltraps
c0101f59:	e9 a8 09 00 00       	jmp    c0102906 <__alltraps>

c0101f5e <vector24>:
.globl vector24
vector24:
  pushl $0
c0101f5e:	6a 00                	push   $0x0
  pushl $24
c0101f60:	6a 18                	push   $0x18
  jmp __alltraps
c0101f62:	e9 9f 09 00 00       	jmp    c0102906 <__alltraps>

c0101f67 <vector25>:
.globl vector25
vector25:
  pushl $0
c0101f67:	6a 00                	push   $0x0
  pushl $25
c0101f69:	6a 19                	push   $0x19
  jmp __alltraps
c0101f6b:	e9 96 09 00 00       	jmp    c0102906 <__alltraps>

c0101f70 <vector26>:
.globl vector26
vector26:
  pushl $0
c0101f70:	6a 00                	push   $0x0
  pushl $26
c0101f72:	6a 1a                	push   $0x1a
  jmp __alltraps
c0101f74:	e9 8d 09 00 00       	jmp    c0102906 <__alltraps>

c0101f79 <vector27>:
.globl vector27
vector27:
  pushl $0
c0101f79:	6a 00                	push   $0x0
  pushl $27
c0101f7b:	6a 1b                	push   $0x1b
  jmp __alltraps
c0101f7d:	e9 84 09 00 00       	jmp    c0102906 <__alltraps>

c0101f82 <vector28>:
.globl vector28
vector28:
  pushl $0
c0101f82:	6a 00                	push   $0x0
  pushl $28
c0101f84:	6a 1c                	push   $0x1c
  jmp __alltraps
c0101f86:	e9 7b 09 00 00       	jmp    c0102906 <__alltraps>

c0101f8b <vector29>:
.globl vector29
vector29:
  pushl $0
c0101f8b:	6a 00                	push   $0x0
  pushl $29
c0101f8d:	6a 1d                	push   $0x1d
  jmp __alltraps
c0101f8f:	e9 72 09 00 00       	jmp    c0102906 <__alltraps>

c0101f94 <vector30>:
.globl vector30
vector30:
  pushl $0
c0101f94:	6a 00                	push   $0x0
  pushl $30
c0101f96:	6a 1e                	push   $0x1e
  jmp __alltraps
c0101f98:	e9 69 09 00 00       	jmp    c0102906 <__alltraps>

c0101f9d <vector31>:
.globl vector31
vector31:
  pushl $0
c0101f9d:	6a 00                	push   $0x0
  pushl $31
c0101f9f:	6a 1f                	push   $0x1f
  jmp __alltraps
c0101fa1:	e9 60 09 00 00       	jmp    c0102906 <__alltraps>

c0101fa6 <vector32>:
.globl vector32
vector32:
  pushl $0
c0101fa6:	6a 00                	push   $0x0
  pushl $32
c0101fa8:	6a 20                	push   $0x20
  jmp __alltraps
c0101faa:	e9 57 09 00 00       	jmp    c0102906 <__alltraps>

c0101faf <vector33>:
.globl vector33
vector33:
  pushl $0
c0101faf:	6a 00                	push   $0x0
  pushl $33
c0101fb1:	6a 21                	push   $0x21
  jmp __alltraps
c0101fb3:	e9 4e 09 00 00       	jmp    c0102906 <__alltraps>

c0101fb8 <vector34>:
.globl vector34
vector34:
  pushl $0
c0101fb8:	6a 00                	push   $0x0
  pushl $34
c0101fba:	6a 22                	push   $0x22
  jmp __alltraps
c0101fbc:	e9 45 09 00 00       	jmp    c0102906 <__alltraps>

c0101fc1 <vector35>:
.globl vector35
vector35:
  pushl $0
c0101fc1:	6a 00                	push   $0x0
  pushl $35
c0101fc3:	6a 23                	push   $0x23
  jmp __alltraps
c0101fc5:	e9 3c 09 00 00       	jmp    c0102906 <__alltraps>

c0101fca <vector36>:
.globl vector36
vector36:
  pushl $0
c0101fca:	6a 00                	push   $0x0
  pushl $36
c0101fcc:	6a 24                	push   $0x24
  jmp __alltraps
c0101fce:	e9 33 09 00 00       	jmp    c0102906 <__alltraps>

c0101fd3 <vector37>:
.globl vector37
vector37:
  pushl $0
c0101fd3:	6a 00                	push   $0x0
  pushl $37
c0101fd5:	6a 25                	push   $0x25
  jmp __alltraps
c0101fd7:	e9 2a 09 00 00       	jmp    c0102906 <__alltraps>

c0101fdc <vector38>:
.globl vector38
vector38:
  pushl $0
c0101fdc:	6a 00                	push   $0x0
  pushl $38
c0101fde:	6a 26                	push   $0x26
  jmp __alltraps
c0101fe0:	e9 21 09 00 00       	jmp    c0102906 <__alltraps>

c0101fe5 <vector39>:
.globl vector39
vector39:
  pushl $0
c0101fe5:	6a 00                	push   $0x0
  pushl $39
c0101fe7:	6a 27                	push   $0x27
  jmp __alltraps
c0101fe9:	e9 18 09 00 00       	jmp    c0102906 <__alltraps>

c0101fee <vector40>:
.globl vector40
vector40:
  pushl $0
c0101fee:	6a 00                	push   $0x0
  pushl $40
c0101ff0:	6a 28                	push   $0x28
  jmp __alltraps
c0101ff2:	e9 0f 09 00 00       	jmp    c0102906 <__alltraps>

c0101ff7 <vector41>:
.globl vector41
vector41:
  pushl $0
c0101ff7:	6a 00                	push   $0x0
  pushl $41
c0101ff9:	6a 29                	push   $0x29
  jmp __alltraps
c0101ffb:	e9 06 09 00 00       	jmp    c0102906 <__alltraps>

c0102000 <vector42>:
.globl vector42
vector42:
  pushl $0
c0102000:	6a 00                	push   $0x0
  pushl $42
c0102002:	6a 2a                	push   $0x2a
  jmp __alltraps
c0102004:	e9 fd 08 00 00       	jmp    c0102906 <__alltraps>

c0102009 <vector43>:
.globl vector43
vector43:
  pushl $0
c0102009:	6a 00                	push   $0x0
  pushl $43
c010200b:	6a 2b                	push   $0x2b
  jmp __alltraps
c010200d:	e9 f4 08 00 00       	jmp    c0102906 <__alltraps>

c0102012 <vector44>:
.globl vector44
vector44:
  pushl $0
c0102012:	6a 00                	push   $0x0
  pushl $44
c0102014:	6a 2c                	push   $0x2c
  jmp __alltraps
c0102016:	e9 eb 08 00 00       	jmp    c0102906 <__alltraps>

c010201b <vector45>:
.globl vector45
vector45:
  pushl $0
c010201b:	6a 00                	push   $0x0
  pushl $45
c010201d:	6a 2d                	push   $0x2d
  jmp __alltraps
c010201f:	e9 e2 08 00 00       	jmp    c0102906 <__alltraps>

c0102024 <vector46>:
.globl vector46
vector46:
  pushl $0
c0102024:	6a 00                	push   $0x0
  pushl $46
c0102026:	6a 2e                	push   $0x2e
  jmp __alltraps
c0102028:	e9 d9 08 00 00       	jmp    c0102906 <__alltraps>

c010202d <vector47>:
.globl vector47
vector47:
  pushl $0
c010202d:	6a 00                	push   $0x0
  pushl $47
c010202f:	6a 2f                	push   $0x2f
  jmp __alltraps
c0102031:	e9 d0 08 00 00       	jmp    c0102906 <__alltraps>

c0102036 <vector48>:
.globl vector48
vector48:
  pushl $0
c0102036:	6a 00                	push   $0x0
  pushl $48
c0102038:	6a 30                	push   $0x30
  jmp __alltraps
c010203a:	e9 c7 08 00 00       	jmp    c0102906 <__alltraps>

c010203f <vector49>:
.globl vector49
vector49:
  pushl $0
c010203f:	6a 00                	push   $0x0
  pushl $49
c0102041:	6a 31                	push   $0x31
  jmp __alltraps
c0102043:	e9 be 08 00 00       	jmp    c0102906 <__alltraps>

c0102048 <vector50>:
.globl vector50
vector50:
  pushl $0
c0102048:	6a 00                	push   $0x0
  pushl $50
c010204a:	6a 32                	push   $0x32
  jmp __alltraps
c010204c:	e9 b5 08 00 00       	jmp    c0102906 <__alltraps>

c0102051 <vector51>:
.globl vector51
vector51:
  pushl $0
c0102051:	6a 00                	push   $0x0
  pushl $51
c0102053:	6a 33                	push   $0x33
  jmp __alltraps
c0102055:	e9 ac 08 00 00       	jmp    c0102906 <__alltraps>

c010205a <vector52>:
.globl vector52
vector52:
  pushl $0
c010205a:	6a 00                	push   $0x0
  pushl $52
c010205c:	6a 34                	push   $0x34
  jmp __alltraps
c010205e:	e9 a3 08 00 00       	jmp    c0102906 <__alltraps>

c0102063 <vector53>:
.globl vector53
vector53:
  pushl $0
c0102063:	6a 00                	push   $0x0
  pushl $53
c0102065:	6a 35                	push   $0x35
  jmp __alltraps
c0102067:	e9 9a 08 00 00       	jmp    c0102906 <__alltraps>

c010206c <vector54>:
.globl vector54
vector54:
  pushl $0
c010206c:	6a 00                	push   $0x0
  pushl $54
c010206e:	6a 36                	push   $0x36
  jmp __alltraps
c0102070:	e9 91 08 00 00       	jmp    c0102906 <__alltraps>

c0102075 <vector55>:
.globl vector55
vector55:
  pushl $0
c0102075:	6a 00                	push   $0x0
  pushl $55
c0102077:	6a 37                	push   $0x37
  jmp __alltraps
c0102079:	e9 88 08 00 00       	jmp    c0102906 <__alltraps>

c010207e <vector56>:
.globl vector56
vector56:
  pushl $0
c010207e:	6a 00                	push   $0x0
  pushl $56
c0102080:	6a 38                	push   $0x38
  jmp __alltraps
c0102082:	e9 7f 08 00 00       	jmp    c0102906 <__alltraps>

c0102087 <vector57>:
.globl vector57
vector57:
  pushl $0
c0102087:	6a 00                	push   $0x0
  pushl $57
c0102089:	6a 39                	push   $0x39
  jmp __alltraps
c010208b:	e9 76 08 00 00       	jmp    c0102906 <__alltraps>

c0102090 <vector58>:
.globl vector58
vector58:
  pushl $0
c0102090:	6a 00                	push   $0x0
  pushl $58
c0102092:	6a 3a                	push   $0x3a
  jmp __alltraps
c0102094:	e9 6d 08 00 00       	jmp    c0102906 <__alltraps>

c0102099 <vector59>:
.globl vector59
vector59:
  pushl $0
c0102099:	6a 00                	push   $0x0
  pushl $59
c010209b:	6a 3b                	push   $0x3b
  jmp __alltraps
c010209d:	e9 64 08 00 00       	jmp    c0102906 <__alltraps>

c01020a2 <vector60>:
.globl vector60
vector60:
  pushl $0
c01020a2:	6a 00                	push   $0x0
  pushl $60
c01020a4:	6a 3c                	push   $0x3c
  jmp __alltraps
c01020a6:	e9 5b 08 00 00       	jmp    c0102906 <__alltraps>

c01020ab <vector61>:
.globl vector61
vector61:
  pushl $0
c01020ab:	6a 00                	push   $0x0
  pushl $61
c01020ad:	6a 3d                	push   $0x3d
  jmp __alltraps
c01020af:	e9 52 08 00 00       	jmp    c0102906 <__alltraps>

c01020b4 <vector62>:
.globl vector62
vector62:
  pushl $0
c01020b4:	6a 00                	push   $0x0
  pushl $62
c01020b6:	6a 3e                	push   $0x3e
  jmp __alltraps
c01020b8:	e9 49 08 00 00       	jmp    c0102906 <__alltraps>

c01020bd <vector63>:
.globl vector63
vector63:
  pushl $0
c01020bd:	6a 00                	push   $0x0
  pushl $63
c01020bf:	6a 3f                	push   $0x3f
  jmp __alltraps
c01020c1:	e9 40 08 00 00       	jmp    c0102906 <__alltraps>

c01020c6 <vector64>:
.globl vector64
vector64:
  pushl $0
c01020c6:	6a 00                	push   $0x0
  pushl $64
c01020c8:	6a 40                	push   $0x40
  jmp __alltraps
c01020ca:	e9 37 08 00 00       	jmp    c0102906 <__alltraps>

c01020cf <vector65>:
.globl vector65
vector65:
  pushl $0
c01020cf:	6a 00                	push   $0x0
  pushl $65
c01020d1:	6a 41                	push   $0x41
  jmp __alltraps
c01020d3:	e9 2e 08 00 00       	jmp    c0102906 <__alltraps>

c01020d8 <vector66>:
.globl vector66
vector66:
  pushl $0
c01020d8:	6a 00                	push   $0x0
  pushl $66
c01020da:	6a 42                	push   $0x42
  jmp __alltraps
c01020dc:	e9 25 08 00 00       	jmp    c0102906 <__alltraps>

c01020e1 <vector67>:
.globl vector67
vector67:
  pushl $0
c01020e1:	6a 00                	push   $0x0
  pushl $67
c01020e3:	6a 43                	push   $0x43
  jmp __alltraps
c01020e5:	e9 1c 08 00 00       	jmp    c0102906 <__alltraps>

c01020ea <vector68>:
.globl vector68
vector68:
  pushl $0
c01020ea:	6a 00                	push   $0x0
  pushl $68
c01020ec:	6a 44                	push   $0x44
  jmp __alltraps
c01020ee:	e9 13 08 00 00       	jmp    c0102906 <__alltraps>

c01020f3 <vector69>:
.globl vector69
vector69:
  pushl $0
c01020f3:	6a 00                	push   $0x0
  pushl $69
c01020f5:	6a 45                	push   $0x45
  jmp __alltraps
c01020f7:	e9 0a 08 00 00       	jmp    c0102906 <__alltraps>

c01020fc <vector70>:
.globl vector70
vector70:
  pushl $0
c01020fc:	6a 00                	push   $0x0
  pushl $70
c01020fe:	6a 46                	push   $0x46
  jmp __alltraps
c0102100:	e9 01 08 00 00       	jmp    c0102906 <__alltraps>

c0102105 <vector71>:
.globl vector71
vector71:
  pushl $0
c0102105:	6a 00                	push   $0x0
  pushl $71
c0102107:	6a 47                	push   $0x47
  jmp __alltraps
c0102109:	e9 f8 07 00 00       	jmp    c0102906 <__alltraps>

c010210e <vector72>:
.globl vector72
vector72:
  pushl $0
c010210e:	6a 00                	push   $0x0
  pushl $72
c0102110:	6a 48                	push   $0x48
  jmp __alltraps
c0102112:	e9 ef 07 00 00       	jmp    c0102906 <__alltraps>

c0102117 <vector73>:
.globl vector73
vector73:
  pushl $0
c0102117:	6a 00                	push   $0x0
  pushl $73
c0102119:	6a 49                	push   $0x49
  jmp __alltraps
c010211b:	e9 e6 07 00 00       	jmp    c0102906 <__alltraps>

c0102120 <vector74>:
.globl vector74
vector74:
  pushl $0
c0102120:	6a 00                	push   $0x0
  pushl $74
c0102122:	6a 4a                	push   $0x4a
  jmp __alltraps
c0102124:	e9 dd 07 00 00       	jmp    c0102906 <__alltraps>

c0102129 <vector75>:
.globl vector75
vector75:
  pushl $0
c0102129:	6a 00                	push   $0x0
  pushl $75
c010212b:	6a 4b                	push   $0x4b
  jmp __alltraps
c010212d:	e9 d4 07 00 00       	jmp    c0102906 <__alltraps>

c0102132 <vector76>:
.globl vector76
vector76:
  pushl $0
c0102132:	6a 00                	push   $0x0
  pushl $76
c0102134:	6a 4c                	push   $0x4c
  jmp __alltraps
c0102136:	e9 cb 07 00 00       	jmp    c0102906 <__alltraps>

c010213b <vector77>:
.globl vector77
vector77:
  pushl $0
c010213b:	6a 00                	push   $0x0
  pushl $77
c010213d:	6a 4d                	push   $0x4d
  jmp __alltraps
c010213f:	e9 c2 07 00 00       	jmp    c0102906 <__alltraps>

c0102144 <vector78>:
.globl vector78
vector78:
  pushl $0
c0102144:	6a 00                	push   $0x0
  pushl $78
c0102146:	6a 4e                	push   $0x4e
  jmp __alltraps
c0102148:	e9 b9 07 00 00       	jmp    c0102906 <__alltraps>

c010214d <vector79>:
.globl vector79
vector79:
  pushl $0
c010214d:	6a 00                	push   $0x0
  pushl $79
c010214f:	6a 4f                	push   $0x4f
  jmp __alltraps
c0102151:	e9 b0 07 00 00       	jmp    c0102906 <__alltraps>

c0102156 <vector80>:
.globl vector80
vector80:
  pushl $0
c0102156:	6a 00                	push   $0x0
  pushl $80
c0102158:	6a 50                	push   $0x50
  jmp __alltraps
c010215a:	e9 a7 07 00 00       	jmp    c0102906 <__alltraps>

c010215f <vector81>:
.globl vector81
vector81:
  pushl $0
c010215f:	6a 00                	push   $0x0
  pushl $81
c0102161:	6a 51                	push   $0x51
  jmp __alltraps
c0102163:	e9 9e 07 00 00       	jmp    c0102906 <__alltraps>

c0102168 <vector82>:
.globl vector82
vector82:
  pushl $0
c0102168:	6a 00                	push   $0x0
  pushl $82
c010216a:	6a 52                	push   $0x52
  jmp __alltraps
c010216c:	e9 95 07 00 00       	jmp    c0102906 <__alltraps>

c0102171 <vector83>:
.globl vector83
vector83:
  pushl $0
c0102171:	6a 00                	push   $0x0
  pushl $83
c0102173:	6a 53                	push   $0x53
  jmp __alltraps
c0102175:	e9 8c 07 00 00       	jmp    c0102906 <__alltraps>

c010217a <vector84>:
.globl vector84
vector84:
  pushl $0
c010217a:	6a 00                	push   $0x0
  pushl $84
c010217c:	6a 54                	push   $0x54
  jmp __alltraps
c010217e:	e9 83 07 00 00       	jmp    c0102906 <__alltraps>

c0102183 <vector85>:
.globl vector85
vector85:
  pushl $0
c0102183:	6a 00                	push   $0x0
  pushl $85
c0102185:	6a 55                	push   $0x55
  jmp __alltraps
c0102187:	e9 7a 07 00 00       	jmp    c0102906 <__alltraps>

c010218c <vector86>:
.globl vector86
vector86:
  pushl $0
c010218c:	6a 00                	push   $0x0
  pushl $86
c010218e:	6a 56                	push   $0x56
  jmp __alltraps
c0102190:	e9 71 07 00 00       	jmp    c0102906 <__alltraps>

c0102195 <vector87>:
.globl vector87
vector87:
  pushl $0
c0102195:	6a 00                	push   $0x0
  pushl $87
c0102197:	6a 57                	push   $0x57
  jmp __alltraps
c0102199:	e9 68 07 00 00       	jmp    c0102906 <__alltraps>

c010219e <vector88>:
.globl vector88
vector88:
  pushl $0
c010219e:	6a 00                	push   $0x0
  pushl $88
c01021a0:	6a 58                	push   $0x58
  jmp __alltraps
c01021a2:	e9 5f 07 00 00       	jmp    c0102906 <__alltraps>

c01021a7 <vector89>:
.globl vector89
vector89:
  pushl $0
c01021a7:	6a 00                	push   $0x0
  pushl $89
c01021a9:	6a 59                	push   $0x59
  jmp __alltraps
c01021ab:	e9 56 07 00 00       	jmp    c0102906 <__alltraps>

c01021b0 <vector90>:
.globl vector90
vector90:
  pushl $0
c01021b0:	6a 00                	push   $0x0
  pushl $90
c01021b2:	6a 5a                	push   $0x5a
  jmp __alltraps
c01021b4:	e9 4d 07 00 00       	jmp    c0102906 <__alltraps>

c01021b9 <vector91>:
.globl vector91
vector91:
  pushl $0
c01021b9:	6a 00                	push   $0x0
  pushl $91
c01021bb:	6a 5b                	push   $0x5b
  jmp __alltraps
c01021bd:	e9 44 07 00 00       	jmp    c0102906 <__alltraps>

c01021c2 <vector92>:
.globl vector92
vector92:
  pushl $0
c01021c2:	6a 00                	push   $0x0
  pushl $92
c01021c4:	6a 5c                	push   $0x5c
  jmp __alltraps
c01021c6:	e9 3b 07 00 00       	jmp    c0102906 <__alltraps>

c01021cb <vector93>:
.globl vector93
vector93:
  pushl $0
c01021cb:	6a 00                	push   $0x0
  pushl $93
c01021cd:	6a 5d                	push   $0x5d
  jmp __alltraps
c01021cf:	e9 32 07 00 00       	jmp    c0102906 <__alltraps>

c01021d4 <vector94>:
.globl vector94
vector94:
  pushl $0
c01021d4:	6a 00                	push   $0x0
  pushl $94
c01021d6:	6a 5e                	push   $0x5e
  jmp __alltraps
c01021d8:	e9 29 07 00 00       	jmp    c0102906 <__alltraps>

c01021dd <vector95>:
.globl vector95
vector95:
  pushl $0
c01021dd:	6a 00                	push   $0x0
  pushl $95
c01021df:	6a 5f                	push   $0x5f
  jmp __alltraps
c01021e1:	e9 20 07 00 00       	jmp    c0102906 <__alltraps>

c01021e6 <vector96>:
.globl vector96
vector96:
  pushl $0
c01021e6:	6a 00                	push   $0x0
  pushl $96
c01021e8:	6a 60                	push   $0x60
  jmp __alltraps
c01021ea:	e9 17 07 00 00       	jmp    c0102906 <__alltraps>

c01021ef <vector97>:
.globl vector97
vector97:
  pushl $0
c01021ef:	6a 00                	push   $0x0
  pushl $97
c01021f1:	6a 61                	push   $0x61
  jmp __alltraps
c01021f3:	e9 0e 07 00 00       	jmp    c0102906 <__alltraps>

c01021f8 <vector98>:
.globl vector98
vector98:
  pushl $0
c01021f8:	6a 00                	push   $0x0
  pushl $98
c01021fa:	6a 62                	push   $0x62
  jmp __alltraps
c01021fc:	e9 05 07 00 00       	jmp    c0102906 <__alltraps>

c0102201 <vector99>:
.globl vector99
vector99:
  pushl $0
c0102201:	6a 00                	push   $0x0
  pushl $99
c0102203:	6a 63                	push   $0x63
  jmp __alltraps
c0102205:	e9 fc 06 00 00       	jmp    c0102906 <__alltraps>

c010220a <vector100>:
.globl vector100
vector100:
  pushl $0
c010220a:	6a 00                	push   $0x0
  pushl $100
c010220c:	6a 64                	push   $0x64
  jmp __alltraps
c010220e:	e9 f3 06 00 00       	jmp    c0102906 <__alltraps>

c0102213 <vector101>:
.globl vector101
vector101:
  pushl $0
c0102213:	6a 00                	push   $0x0
  pushl $101
c0102215:	6a 65                	push   $0x65
  jmp __alltraps
c0102217:	e9 ea 06 00 00       	jmp    c0102906 <__alltraps>

c010221c <vector102>:
.globl vector102
vector102:
  pushl $0
c010221c:	6a 00                	push   $0x0
  pushl $102
c010221e:	6a 66                	push   $0x66
  jmp __alltraps
c0102220:	e9 e1 06 00 00       	jmp    c0102906 <__alltraps>

c0102225 <vector103>:
.globl vector103
vector103:
  pushl $0
c0102225:	6a 00                	push   $0x0
  pushl $103
c0102227:	6a 67                	push   $0x67
  jmp __alltraps
c0102229:	e9 d8 06 00 00       	jmp    c0102906 <__alltraps>

c010222e <vector104>:
.globl vector104
vector104:
  pushl $0
c010222e:	6a 00                	push   $0x0
  pushl $104
c0102230:	6a 68                	push   $0x68
  jmp __alltraps
c0102232:	e9 cf 06 00 00       	jmp    c0102906 <__alltraps>

c0102237 <vector105>:
.globl vector105
vector105:
  pushl $0
c0102237:	6a 00                	push   $0x0
  pushl $105
c0102239:	6a 69                	push   $0x69
  jmp __alltraps
c010223b:	e9 c6 06 00 00       	jmp    c0102906 <__alltraps>

c0102240 <vector106>:
.globl vector106
vector106:
  pushl $0
c0102240:	6a 00                	push   $0x0
  pushl $106
c0102242:	6a 6a                	push   $0x6a
  jmp __alltraps
c0102244:	e9 bd 06 00 00       	jmp    c0102906 <__alltraps>

c0102249 <vector107>:
.globl vector107
vector107:
  pushl $0
c0102249:	6a 00                	push   $0x0
  pushl $107
c010224b:	6a 6b                	push   $0x6b
  jmp __alltraps
c010224d:	e9 b4 06 00 00       	jmp    c0102906 <__alltraps>

c0102252 <vector108>:
.globl vector108
vector108:
  pushl $0
c0102252:	6a 00                	push   $0x0
  pushl $108
c0102254:	6a 6c                	push   $0x6c
  jmp __alltraps
c0102256:	e9 ab 06 00 00       	jmp    c0102906 <__alltraps>

c010225b <vector109>:
.globl vector109
vector109:
  pushl $0
c010225b:	6a 00                	push   $0x0
  pushl $109
c010225d:	6a 6d                	push   $0x6d
  jmp __alltraps
c010225f:	e9 a2 06 00 00       	jmp    c0102906 <__alltraps>

c0102264 <vector110>:
.globl vector110
vector110:
  pushl $0
c0102264:	6a 00                	push   $0x0
  pushl $110
c0102266:	6a 6e                	push   $0x6e
  jmp __alltraps
c0102268:	e9 99 06 00 00       	jmp    c0102906 <__alltraps>

c010226d <vector111>:
.globl vector111
vector111:
  pushl $0
c010226d:	6a 00                	push   $0x0
  pushl $111
c010226f:	6a 6f                	push   $0x6f
  jmp __alltraps
c0102271:	e9 90 06 00 00       	jmp    c0102906 <__alltraps>

c0102276 <vector112>:
.globl vector112
vector112:
  pushl $0
c0102276:	6a 00                	push   $0x0
  pushl $112
c0102278:	6a 70                	push   $0x70
  jmp __alltraps
c010227a:	e9 87 06 00 00       	jmp    c0102906 <__alltraps>

c010227f <vector113>:
.globl vector113
vector113:
  pushl $0
c010227f:	6a 00                	push   $0x0
  pushl $113
c0102281:	6a 71                	push   $0x71
  jmp __alltraps
c0102283:	e9 7e 06 00 00       	jmp    c0102906 <__alltraps>

c0102288 <vector114>:
.globl vector114
vector114:
  pushl $0
c0102288:	6a 00                	push   $0x0
  pushl $114
c010228a:	6a 72                	push   $0x72
  jmp __alltraps
c010228c:	e9 75 06 00 00       	jmp    c0102906 <__alltraps>

c0102291 <vector115>:
.globl vector115
vector115:
  pushl $0
c0102291:	6a 00                	push   $0x0
  pushl $115
c0102293:	6a 73                	push   $0x73
  jmp __alltraps
c0102295:	e9 6c 06 00 00       	jmp    c0102906 <__alltraps>

c010229a <vector116>:
.globl vector116
vector116:
  pushl $0
c010229a:	6a 00                	push   $0x0
  pushl $116
c010229c:	6a 74                	push   $0x74
  jmp __alltraps
c010229e:	e9 63 06 00 00       	jmp    c0102906 <__alltraps>

c01022a3 <vector117>:
.globl vector117
vector117:
  pushl $0
c01022a3:	6a 00                	push   $0x0
  pushl $117
c01022a5:	6a 75                	push   $0x75
  jmp __alltraps
c01022a7:	e9 5a 06 00 00       	jmp    c0102906 <__alltraps>

c01022ac <vector118>:
.globl vector118
vector118:
  pushl $0
c01022ac:	6a 00                	push   $0x0
  pushl $118
c01022ae:	6a 76                	push   $0x76
  jmp __alltraps
c01022b0:	e9 51 06 00 00       	jmp    c0102906 <__alltraps>

c01022b5 <vector119>:
.globl vector119
vector119:
  pushl $0
c01022b5:	6a 00                	push   $0x0
  pushl $119
c01022b7:	6a 77                	push   $0x77
  jmp __alltraps
c01022b9:	e9 48 06 00 00       	jmp    c0102906 <__alltraps>

c01022be <vector120>:
.globl vector120
vector120:
  pushl $0
c01022be:	6a 00                	push   $0x0
  pushl $120
c01022c0:	6a 78                	push   $0x78
  jmp __alltraps
c01022c2:	e9 3f 06 00 00       	jmp    c0102906 <__alltraps>

c01022c7 <vector121>:
.globl vector121
vector121:
  pushl $0
c01022c7:	6a 00                	push   $0x0
  pushl $121
c01022c9:	6a 79                	push   $0x79
  jmp __alltraps
c01022cb:	e9 36 06 00 00       	jmp    c0102906 <__alltraps>

c01022d0 <vector122>:
.globl vector122
vector122:
  pushl $0
c01022d0:	6a 00                	push   $0x0
  pushl $122
c01022d2:	6a 7a                	push   $0x7a
  jmp __alltraps
c01022d4:	e9 2d 06 00 00       	jmp    c0102906 <__alltraps>

c01022d9 <vector123>:
.globl vector123
vector123:
  pushl $0
c01022d9:	6a 00                	push   $0x0
  pushl $123
c01022db:	6a 7b                	push   $0x7b
  jmp __alltraps
c01022dd:	e9 24 06 00 00       	jmp    c0102906 <__alltraps>

c01022e2 <vector124>:
.globl vector124
vector124:
  pushl $0
c01022e2:	6a 00                	push   $0x0
  pushl $124
c01022e4:	6a 7c                	push   $0x7c
  jmp __alltraps
c01022e6:	e9 1b 06 00 00       	jmp    c0102906 <__alltraps>

c01022eb <vector125>:
.globl vector125
vector125:
  pushl $0
c01022eb:	6a 00                	push   $0x0
  pushl $125
c01022ed:	6a 7d                	push   $0x7d
  jmp __alltraps
c01022ef:	e9 12 06 00 00       	jmp    c0102906 <__alltraps>

c01022f4 <vector126>:
.globl vector126
vector126:
  pushl $0
c01022f4:	6a 00                	push   $0x0
  pushl $126
c01022f6:	6a 7e                	push   $0x7e
  jmp __alltraps
c01022f8:	e9 09 06 00 00       	jmp    c0102906 <__alltraps>

c01022fd <vector127>:
.globl vector127
vector127:
  pushl $0
c01022fd:	6a 00                	push   $0x0
  pushl $127
c01022ff:	6a 7f                	push   $0x7f
  jmp __alltraps
c0102301:	e9 00 06 00 00       	jmp    c0102906 <__alltraps>

c0102306 <vector128>:
.globl vector128
vector128:
  pushl $0
c0102306:	6a 00                	push   $0x0
  pushl $128
c0102308:	68 80 00 00 00       	push   $0x80
  jmp __alltraps
c010230d:	e9 f4 05 00 00       	jmp    c0102906 <__alltraps>

c0102312 <vector129>:
.globl vector129
vector129:
  pushl $0
c0102312:	6a 00                	push   $0x0
  pushl $129
c0102314:	68 81 00 00 00       	push   $0x81
  jmp __alltraps
c0102319:	e9 e8 05 00 00       	jmp    c0102906 <__alltraps>

c010231e <vector130>:
.globl vector130
vector130:
  pushl $0
c010231e:	6a 00                	push   $0x0
  pushl $130
c0102320:	68 82 00 00 00       	push   $0x82
  jmp __alltraps
c0102325:	e9 dc 05 00 00       	jmp    c0102906 <__alltraps>

c010232a <vector131>:
.globl vector131
vector131:
  pushl $0
c010232a:	6a 00                	push   $0x0
  pushl $131
c010232c:	68 83 00 00 00       	push   $0x83
  jmp __alltraps
c0102331:	e9 d0 05 00 00       	jmp    c0102906 <__alltraps>

c0102336 <vector132>:
.globl vector132
vector132:
  pushl $0
c0102336:	6a 00                	push   $0x0
  pushl $132
c0102338:	68 84 00 00 00       	push   $0x84
  jmp __alltraps
c010233d:	e9 c4 05 00 00       	jmp    c0102906 <__alltraps>

c0102342 <vector133>:
.globl vector133
vector133:
  pushl $0
c0102342:	6a 00                	push   $0x0
  pushl $133
c0102344:	68 85 00 00 00       	push   $0x85
  jmp __alltraps
c0102349:	e9 b8 05 00 00       	jmp    c0102906 <__alltraps>

c010234e <vector134>:
.globl vector134
vector134:
  pushl $0
c010234e:	6a 00                	push   $0x0
  pushl $134
c0102350:	68 86 00 00 00       	push   $0x86
  jmp __alltraps
c0102355:	e9 ac 05 00 00       	jmp    c0102906 <__alltraps>

c010235a <vector135>:
.globl vector135
vector135:
  pushl $0
c010235a:	6a 00                	push   $0x0
  pushl $135
c010235c:	68 87 00 00 00       	push   $0x87
  jmp __alltraps
c0102361:	e9 a0 05 00 00       	jmp    c0102906 <__alltraps>

c0102366 <vector136>:
.globl vector136
vector136:
  pushl $0
c0102366:	6a 00                	push   $0x0
  pushl $136
c0102368:	68 88 00 00 00       	push   $0x88
  jmp __alltraps
c010236d:	e9 94 05 00 00       	jmp    c0102906 <__alltraps>

c0102372 <vector137>:
.globl vector137
vector137:
  pushl $0
c0102372:	6a 00                	push   $0x0
  pushl $137
c0102374:	68 89 00 00 00       	push   $0x89
  jmp __alltraps
c0102379:	e9 88 05 00 00       	jmp    c0102906 <__alltraps>

c010237e <vector138>:
.globl vector138
vector138:
  pushl $0
c010237e:	6a 00                	push   $0x0
  pushl $138
c0102380:	68 8a 00 00 00       	push   $0x8a
  jmp __alltraps
c0102385:	e9 7c 05 00 00       	jmp    c0102906 <__alltraps>

c010238a <vector139>:
.globl vector139
vector139:
  pushl $0
c010238a:	6a 00                	push   $0x0
  pushl $139
c010238c:	68 8b 00 00 00       	push   $0x8b
  jmp __alltraps
c0102391:	e9 70 05 00 00       	jmp    c0102906 <__alltraps>

c0102396 <vector140>:
.globl vector140
vector140:
  pushl $0
c0102396:	6a 00                	push   $0x0
  pushl $140
c0102398:	68 8c 00 00 00       	push   $0x8c
  jmp __alltraps
c010239d:	e9 64 05 00 00       	jmp    c0102906 <__alltraps>

c01023a2 <vector141>:
.globl vector141
vector141:
  pushl $0
c01023a2:	6a 00                	push   $0x0
  pushl $141
c01023a4:	68 8d 00 00 00       	push   $0x8d
  jmp __alltraps
c01023a9:	e9 58 05 00 00       	jmp    c0102906 <__alltraps>

c01023ae <vector142>:
.globl vector142
vector142:
  pushl $0
c01023ae:	6a 00                	push   $0x0
  pushl $142
c01023b0:	68 8e 00 00 00       	push   $0x8e
  jmp __alltraps
c01023b5:	e9 4c 05 00 00       	jmp    c0102906 <__alltraps>

c01023ba <vector143>:
.globl vector143
vector143:
  pushl $0
c01023ba:	6a 00                	push   $0x0
  pushl $143
c01023bc:	68 8f 00 00 00       	push   $0x8f
  jmp __alltraps
c01023c1:	e9 40 05 00 00       	jmp    c0102906 <__alltraps>

c01023c6 <vector144>:
.globl vector144
vector144:
  pushl $0
c01023c6:	6a 00                	push   $0x0
  pushl $144
c01023c8:	68 90 00 00 00       	push   $0x90
  jmp __alltraps
c01023cd:	e9 34 05 00 00       	jmp    c0102906 <__alltraps>

c01023d2 <vector145>:
.globl vector145
vector145:
  pushl $0
c01023d2:	6a 00                	push   $0x0
  pushl $145
c01023d4:	68 91 00 00 00       	push   $0x91
  jmp __alltraps
c01023d9:	e9 28 05 00 00       	jmp    c0102906 <__alltraps>

c01023de <vector146>:
.globl vector146
vector146:
  pushl $0
c01023de:	6a 00                	push   $0x0
  pushl $146
c01023e0:	68 92 00 00 00       	push   $0x92
  jmp __alltraps
c01023e5:	e9 1c 05 00 00       	jmp    c0102906 <__alltraps>

c01023ea <vector147>:
.globl vector147
vector147:
  pushl $0
c01023ea:	6a 00                	push   $0x0
  pushl $147
c01023ec:	68 93 00 00 00       	push   $0x93
  jmp __alltraps
c01023f1:	e9 10 05 00 00       	jmp    c0102906 <__alltraps>

c01023f6 <vector148>:
.globl vector148
vector148:
  pushl $0
c01023f6:	6a 00                	push   $0x0
  pushl $148
c01023f8:	68 94 00 00 00       	push   $0x94
  jmp __alltraps
c01023fd:	e9 04 05 00 00       	jmp    c0102906 <__alltraps>

c0102402 <vector149>:
.globl vector149
vector149:
  pushl $0
c0102402:	6a 00                	push   $0x0
  pushl $149
c0102404:	68 95 00 00 00       	push   $0x95
  jmp __alltraps
c0102409:	e9 f8 04 00 00       	jmp    c0102906 <__alltraps>

c010240e <vector150>:
.globl vector150
vector150:
  pushl $0
c010240e:	6a 00                	push   $0x0
  pushl $150
c0102410:	68 96 00 00 00       	push   $0x96
  jmp __alltraps
c0102415:	e9 ec 04 00 00       	jmp    c0102906 <__alltraps>

c010241a <vector151>:
.globl vector151
vector151:
  pushl $0
c010241a:	6a 00                	push   $0x0
  pushl $151
c010241c:	68 97 00 00 00       	push   $0x97
  jmp __alltraps
c0102421:	e9 e0 04 00 00       	jmp    c0102906 <__alltraps>

c0102426 <vector152>:
.globl vector152
vector152:
  pushl $0
c0102426:	6a 00                	push   $0x0
  pushl $152
c0102428:	68 98 00 00 00       	push   $0x98
  jmp __alltraps
c010242d:	e9 d4 04 00 00       	jmp    c0102906 <__alltraps>

c0102432 <vector153>:
.globl vector153
vector153:
  pushl $0
c0102432:	6a 00                	push   $0x0
  pushl $153
c0102434:	68 99 00 00 00       	push   $0x99
  jmp __alltraps
c0102439:	e9 c8 04 00 00       	jmp    c0102906 <__alltraps>

c010243e <vector154>:
.globl vector154
vector154:
  pushl $0
c010243e:	6a 00                	push   $0x0
  pushl $154
c0102440:	68 9a 00 00 00       	push   $0x9a
  jmp __alltraps
c0102445:	e9 bc 04 00 00       	jmp    c0102906 <__alltraps>

c010244a <vector155>:
.globl vector155
vector155:
  pushl $0
c010244a:	6a 00                	push   $0x0
  pushl $155
c010244c:	68 9b 00 00 00       	push   $0x9b
  jmp __alltraps
c0102451:	e9 b0 04 00 00       	jmp    c0102906 <__alltraps>

c0102456 <vector156>:
.globl vector156
vector156:
  pushl $0
c0102456:	6a 00                	push   $0x0
  pushl $156
c0102458:	68 9c 00 00 00       	push   $0x9c
  jmp __alltraps
c010245d:	e9 a4 04 00 00       	jmp    c0102906 <__alltraps>

c0102462 <vector157>:
.globl vector157
vector157:
  pushl $0
c0102462:	6a 00                	push   $0x0
  pushl $157
c0102464:	68 9d 00 00 00       	push   $0x9d
  jmp __alltraps
c0102469:	e9 98 04 00 00       	jmp    c0102906 <__alltraps>

c010246e <vector158>:
.globl vector158
vector158:
  pushl $0
c010246e:	6a 00                	push   $0x0
  pushl $158
c0102470:	68 9e 00 00 00       	push   $0x9e
  jmp __alltraps
c0102475:	e9 8c 04 00 00       	jmp    c0102906 <__alltraps>

c010247a <vector159>:
.globl vector159
vector159:
  pushl $0
c010247a:	6a 00                	push   $0x0
  pushl $159
c010247c:	68 9f 00 00 00       	push   $0x9f
  jmp __alltraps
c0102481:	e9 80 04 00 00       	jmp    c0102906 <__alltraps>

c0102486 <vector160>:
.globl vector160
vector160:
  pushl $0
c0102486:	6a 00                	push   $0x0
  pushl $160
c0102488:	68 a0 00 00 00       	push   $0xa0
  jmp __alltraps
c010248d:	e9 74 04 00 00       	jmp    c0102906 <__alltraps>

c0102492 <vector161>:
.globl vector161
vector161:
  pushl $0
c0102492:	6a 00                	push   $0x0
  pushl $161
c0102494:	68 a1 00 00 00       	push   $0xa1
  jmp __alltraps
c0102499:	e9 68 04 00 00       	jmp    c0102906 <__alltraps>

c010249e <vector162>:
.globl vector162
vector162:
  pushl $0
c010249e:	6a 00                	push   $0x0
  pushl $162
c01024a0:	68 a2 00 00 00       	push   $0xa2
  jmp __alltraps
c01024a5:	e9 5c 04 00 00       	jmp    c0102906 <__alltraps>

c01024aa <vector163>:
.globl vector163
vector163:
  pushl $0
c01024aa:	6a 00                	push   $0x0
  pushl $163
c01024ac:	68 a3 00 00 00       	push   $0xa3
  jmp __alltraps
c01024b1:	e9 50 04 00 00       	jmp    c0102906 <__alltraps>

c01024b6 <vector164>:
.globl vector164
vector164:
  pushl $0
c01024b6:	6a 00                	push   $0x0
  pushl $164
c01024b8:	68 a4 00 00 00       	push   $0xa4
  jmp __alltraps
c01024bd:	e9 44 04 00 00       	jmp    c0102906 <__alltraps>

c01024c2 <vector165>:
.globl vector165
vector165:
  pushl $0
c01024c2:	6a 00                	push   $0x0
  pushl $165
c01024c4:	68 a5 00 00 00       	push   $0xa5
  jmp __alltraps
c01024c9:	e9 38 04 00 00       	jmp    c0102906 <__alltraps>

c01024ce <vector166>:
.globl vector166
vector166:
  pushl $0
c01024ce:	6a 00                	push   $0x0
  pushl $166
c01024d0:	68 a6 00 00 00       	push   $0xa6
  jmp __alltraps
c01024d5:	e9 2c 04 00 00       	jmp    c0102906 <__alltraps>

c01024da <vector167>:
.globl vector167
vector167:
  pushl $0
c01024da:	6a 00                	push   $0x0
  pushl $167
c01024dc:	68 a7 00 00 00       	push   $0xa7
  jmp __alltraps
c01024e1:	e9 20 04 00 00       	jmp    c0102906 <__alltraps>

c01024e6 <vector168>:
.globl vector168
vector168:
  pushl $0
c01024e6:	6a 00                	push   $0x0
  pushl $168
c01024e8:	68 a8 00 00 00       	push   $0xa8
  jmp __alltraps
c01024ed:	e9 14 04 00 00       	jmp    c0102906 <__alltraps>

c01024f2 <vector169>:
.globl vector169
vector169:
  pushl $0
c01024f2:	6a 00                	push   $0x0
  pushl $169
c01024f4:	68 a9 00 00 00       	push   $0xa9
  jmp __alltraps
c01024f9:	e9 08 04 00 00       	jmp    c0102906 <__alltraps>

c01024fe <vector170>:
.globl vector170
vector170:
  pushl $0
c01024fe:	6a 00                	push   $0x0
  pushl $170
c0102500:	68 aa 00 00 00       	push   $0xaa
  jmp __alltraps
c0102505:	e9 fc 03 00 00       	jmp    c0102906 <__alltraps>

c010250a <vector171>:
.globl vector171
vector171:
  pushl $0
c010250a:	6a 00                	push   $0x0
  pushl $171
c010250c:	68 ab 00 00 00       	push   $0xab
  jmp __alltraps
c0102511:	e9 f0 03 00 00       	jmp    c0102906 <__alltraps>

c0102516 <vector172>:
.globl vector172
vector172:
  pushl $0
c0102516:	6a 00                	push   $0x0
  pushl $172
c0102518:	68 ac 00 00 00       	push   $0xac
  jmp __alltraps
c010251d:	e9 e4 03 00 00       	jmp    c0102906 <__alltraps>

c0102522 <vector173>:
.globl vector173
vector173:
  pushl $0
c0102522:	6a 00                	push   $0x0
  pushl $173
c0102524:	68 ad 00 00 00       	push   $0xad
  jmp __alltraps
c0102529:	e9 d8 03 00 00       	jmp    c0102906 <__alltraps>

c010252e <vector174>:
.globl vector174
vector174:
  pushl $0
c010252e:	6a 00                	push   $0x0
  pushl $174
c0102530:	68 ae 00 00 00       	push   $0xae
  jmp __alltraps
c0102535:	e9 cc 03 00 00       	jmp    c0102906 <__alltraps>

c010253a <vector175>:
.globl vector175
vector175:
  pushl $0
c010253a:	6a 00                	push   $0x0
  pushl $175
c010253c:	68 af 00 00 00       	push   $0xaf
  jmp __alltraps
c0102541:	e9 c0 03 00 00       	jmp    c0102906 <__alltraps>

c0102546 <vector176>:
.globl vector176
vector176:
  pushl $0
c0102546:	6a 00                	push   $0x0
  pushl $176
c0102548:	68 b0 00 00 00       	push   $0xb0
  jmp __alltraps
c010254d:	e9 b4 03 00 00       	jmp    c0102906 <__alltraps>

c0102552 <vector177>:
.globl vector177
vector177:
  pushl $0
c0102552:	6a 00                	push   $0x0
  pushl $177
c0102554:	68 b1 00 00 00       	push   $0xb1
  jmp __alltraps
c0102559:	e9 a8 03 00 00       	jmp    c0102906 <__alltraps>

c010255e <vector178>:
.globl vector178
vector178:
  pushl $0
c010255e:	6a 00                	push   $0x0
  pushl $178
c0102560:	68 b2 00 00 00       	push   $0xb2
  jmp __alltraps
c0102565:	e9 9c 03 00 00       	jmp    c0102906 <__alltraps>

c010256a <vector179>:
.globl vector179
vector179:
  pushl $0
c010256a:	6a 00                	push   $0x0
  pushl $179
c010256c:	68 b3 00 00 00       	push   $0xb3
  jmp __alltraps
c0102571:	e9 90 03 00 00       	jmp    c0102906 <__alltraps>

c0102576 <vector180>:
.globl vector180
vector180:
  pushl $0
c0102576:	6a 00                	push   $0x0
  pushl $180
c0102578:	68 b4 00 00 00       	push   $0xb4
  jmp __alltraps
c010257d:	e9 84 03 00 00       	jmp    c0102906 <__alltraps>

c0102582 <vector181>:
.globl vector181
vector181:
  pushl $0
c0102582:	6a 00                	push   $0x0
  pushl $181
c0102584:	68 b5 00 00 00       	push   $0xb5
  jmp __alltraps
c0102589:	e9 78 03 00 00       	jmp    c0102906 <__alltraps>

c010258e <vector182>:
.globl vector182
vector182:
  pushl $0
c010258e:	6a 00                	push   $0x0
  pushl $182
c0102590:	68 b6 00 00 00       	push   $0xb6
  jmp __alltraps
c0102595:	e9 6c 03 00 00       	jmp    c0102906 <__alltraps>

c010259a <vector183>:
.globl vector183
vector183:
  pushl $0
c010259a:	6a 00                	push   $0x0
  pushl $183
c010259c:	68 b7 00 00 00       	push   $0xb7
  jmp __alltraps
c01025a1:	e9 60 03 00 00       	jmp    c0102906 <__alltraps>

c01025a6 <vector184>:
.globl vector184
vector184:
  pushl $0
c01025a6:	6a 00                	push   $0x0
  pushl $184
c01025a8:	68 b8 00 00 00       	push   $0xb8
  jmp __alltraps
c01025ad:	e9 54 03 00 00       	jmp    c0102906 <__alltraps>

c01025b2 <vector185>:
.globl vector185
vector185:
  pushl $0
c01025b2:	6a 00                	push   $0x0
  pushl $185
c01025b4:	68 b9 00 00 00       	push   $0xb9
  jmp __alltraps
c01025b9:	e9 48 03 00 00       	jmp    c0102906 <__alltraps>

c01025be <vector186>:
.globl vector186
vector186:
  pushl $0
c01025be:	6a 00                	push   $0x0
  pushl $186
c01025c0:	68 ba 00 00 00       	push   $0xba
  jmp __alltraps
c01025c5:	e9 3c 03 00 00       	jmp    c0102906 <__alltraps>

c01025ca <vector187>:
.globl vector187
vector187:
  pushl $0
c01025ca:	6a 00                	push   $0x0
  pushl $187
c01025cc:	68 bb 00 00 00       	push   $0xbb
  jmp __alltraps
c01025d1:	e9 30 03 00 00       	jmp    c0102906 <__alltraps>

c01025d6 <vector188>:
.globl vector188
vector188:
  pushl $0
c01025d6:	6a 00                	push   $0x0
  pushl $188
c01025d8:	68 bc 00 00 00       	push   $0xbc
  jmp __alltraps
c01025dd:	e9 24 03 00 00       	jmp    c0102906 <__alltraps>

c01025e2 <vector189>:
.globl vector189
vector189:
  pushl $0
c01025e2:	6a 00                	push   $0x0
  pushl $189
c01025e4:	68 bd 00 00 00       	push   $0xbd
  jmp __alltraps
c01025e9:	e9 18 03 00 00       	jmp    c0102906 <__alltraps>

c01025ee <vector190>:
.globl vector190
vector190:
  pushl $0
c01025ee:	6a 00                	push   $0x0
  pushl $190
c01025f0:	68 be 00 00 00       	push   $0xbe
  jmp __alltraps
c01025f5:	e9 0c 03 00 00       	jmp    c0102906 <__alltraps>

c01025fa <vector191>:
.globl vector191
vector191:
  pushl $0
c01025fa:	6a 00                	push   $0x0
  pushl $191
c01025fc:	68 bf 00 00 00       	push   $0xbf
  jmp __alltraps
c0102601:	e9 00 03 00 00       	jmp    c0102906 <__alltraps>

c0102606 <vector192>:
.globl vector192
vector192:
  pushl $0
c0102606:	6a 00                	push   $0x0
  pushl $192
c0102608:	68 c0 00 00 00       	push   $0xc0
  jmp __alltraps
c010260d:	e9 f4 02 00 00       	jmp    c0102906 <__alltraps>

c0102612 <vector193>:
.globl vector193
vector193:
  pushl $0
c0102612:	6a 00                	push   $0x0
  pushl $193
c0102614:	68 c1 00 00 00       	push   $0xc1
  jmp __alltraps
c0102619:	e9 e8 02 00 00       	jmp    c0102906 <__alltraps>

c010261e <vector194>:
.globl vector194
vector194:
  pushl $0
c010261e:	6a 00                	push   $0x0
  pushl $194
c0102620:	68 c2 00 00 00       	push   $0xc2
  jmp __alltraps
c0102625:	e9 dc 02 00 00       	jmp    c0102906 <__alltraps>

c010262a <vector195>:
.globl vector195
vector195:
  pushl $0
c010262a:	6a 00                	push   $0x0
  pushl $195
c010262c:	68 c3 00 00 00       	push   $0xc3
  jmp __alltraps
c0102631:	e9 d0 02 00 00       	jmp    c0102906 <__alltraps>

c0102636 <vector196>:
.globl vector196
vector196:
  pushl $0
c0102636:	6a 00                	push   $0x0
  pushl $196
c0102638:	68 c4 00 00 00       	push   $0xc4
  jmp __alltraps
c010263d:	e9 c4 02 00 00       	jmp    c0102906 <__alltraps>

c0102642 <vector197>:
.globl vector197
vector197:
  pushl $0
c0102642:	6a 00                	push   $0x0
  pushl $197
c0102644:	68 c5 00 00 00       	push   $0xc5
  jmp __alltraps
c0102649:	e9 b8 02 00 00       	jmp    c0102906 <__alltraps>

c010264e <vector198>:
.globl vector198
vector198:
  pushl $0
c010264e:	6a 00                	push   $0x0
  pushl $198
c0102650:	68 c6 00 00 00       	push   $0xc6
  jmp __alltraps
c0102655:	e9 ac 02 00 00       	jmp    c0102906 <__alltraps>

c010265a <vector199>:
.globl vector199
vector199:
  pushl $0
c010265a:	6a 00                	push   $0x0
  pushl $199
c010265c:	68 c7 00 00 00       	push   $0xc7
  jmp __alltraps
c0102661:	e9 a0 02 00 00       	jmp    c0102906 <__alltraps>

c0102666 <vector200>:
.globl vector200
vector200:
  pushl $0
c0102666:	6a 00                	push   $0x0
  pushl $200
c0102668:	68 c8 00 00 00       	push   $0xc8
  jmp __alltraps
c010266d:	e9 94 02 00 00       	jmp    c0102906 <__alltraps>

c0102672 <vector201>:
.globl vector201
vector201:
  pushl $0
c0102672:	6a 00                	push   $0x0
  pushl $201
c0102674:	68 c9 00 00 00       	push   $0xc9
  jmp __alltraps
c0102679:	e9 88 02 00 00       	jmp    c0102906 <__alltraps>

c010267e <vector202>:
.globl vector202
vector202:
  pushl $0
c010267e:	6a 00                	push   $0x0
  pushl $202
c0102680:	68 ca 00 00 00       	push   $0xca
  jmp __alltraps
c0102685:	e9 7c 02 00 00       	jmp    c0102906 <__alltraps>

c010268a <vector203>:
.globl vector203
vector203:
  pushl $0
c010268a:	6a 00                	push   $0x0
  pushl $203
c010268c:	68 cb 00 00 00       	push   $0xcb
  jmp __alltraps
c0102691:	e9 70 02 00 00       	jmp    c0102906 <__alltraps>

c0102696 <vector204>:
.globl vector204
vector204:
  pushl $0
c0102696:	6a 00                	push   $0x0
  pushl $204
c0102698:	68 cc 00 00 00       	push   $0xcc
  jmp __alltraps
c010269d:	e9 64 02 00 00       	jmp    c0102906 <__alltraps>

c01026a2 <vector205>:
.globl vector205
vector205:
  pushl $0
c01026a2:	6a 00                	push   $0x0
  pushl $205
c01026a4:	68 cd 00 00 00       	push   $0xcd
  jmp __alltraps
c01026a9:	e9 58 02 00 00       	jmp    c0102906 <__alltraps>

c01026ae <vector206>:
.globl vector206
vector206:
  pushl $0
c01026ae:	6a 00                	push   $0x0
  pushl $206
c01026b0:	68 ce 00 00 00       	push   $0xce
  jmp __alltraps
c01026b5:	e9 4c 02 00 00       	jmp    c0102906 <__alltraps>

c01026ba <vector207>:
.globl vector207
vector207:
  pushl $0
c01026ba:	6a 00                	push   $0x0
  pushl $207
c01026bc:	68 cf 00 00 00       	push   $0xcf
  jmp __alltraps
c01026c1:	e9 40 02 00 00       	jmp    c0102906 <__alltraps>

c01026c6 <vector208>:
.globl vector208
vector208:
  pushl $0
c01026c6:	6a 00                	push   $0x0
  pushl $208
c01026c8:	68 d0 00 00 00       	push   $0xd0
  jmp __alltraps
c01026cd:	e9 34 02 00 00       	jmp    c0102906 <__alltraps>

c01026d2 <vector209>:
.globl vector209
vector209:
  pushl $0
c01026d2:	6a 00                	push   $0x0
  pushl $209
c01026d4:	68 d1 00 00 00       	push   $0xd1
  jmp __alltraps
c01026d9:	e9 28 02 00 00       	jmp    c0102906 <__alltraps>

c01026de <vector210>:
.globl vector210
vector210:
  pushl $0
c01026de:	6a 00                	push   $0x0
  pushl $210
c01026e0:	68 d2 00 00 00       	push   $0xd2
  jmp __alltraps
c01026e5:	e9 1c 02 00 00       	jmp    c0102906 <__alltraps>

c01026ea <vector211>:
.globl vector211
vector211:
  pushl $0
c01026ea:	6a 00                	push   $0x0
  pushl $211
c01026ec:	68 d3 00 00 00       	push   $0xd3
  jmp __alltraps
c01026f1:	e9 10 02 00 00       	jmp    c0102906 <__alltraps>

c01026f6 <vector212>:
.globl vector212
vector212:
  pushl $0
c01026f6:	6a 00                	push   $0x0
  pushl $212
c01026f8:	68 d4 00 00 00       	push   $0xd4
  jmp __alltraps
c01026fd:	e9 04 02 00 00       	jmp    c0102906 <__alltraps>

c0102702 <vector213>:
.globl vector213
vector213:
  pushl $0
c0102702:	6a 00                	push   $0x0
  pushl $213
c0102704:	68 d5 00 00 00       	push   $0xd5
  jmp __alltraps
c0102709:	e9 f8 01 00 00       	jmp    c0102906 <__alltraps>

c010270e <vector214>:
.globl vector214
vector214:
  pushl $0
c010270e:	6a 00                	push   $0x0
  pushl $214
c0102710:	68 d6 00 00 00       	push   $0xd6
  jmp __alltraps
c0102715:	e9 ec 01 00 00       	jmp    c0102906 <__alltraps>

c010271a <vector215>:
.globl vector215
vector215:
  pushl $0
c010271a:	6a 00                	push   $0x0
  pushl $215
c010271c:	68 d7 00 00 00       	push   $0xd7
  jmp __alltraps
c0102721:	e9 e0 01 00 00       	jmp    c0102906 <__alltraps>

c0102726 <vector216>:
.globl vector216
vector216:
  pushl $0
c0102726:	6a 00                	push   $0x0
  pushl $216
c0102728:	68 d8 00 00 00       	push   $0xd8
  jmp __alltraps
c010272d:	e9 d4 01 00 00       	jmp    c0102906 <__alltraps>

c0102732 <vector217>:
.globl vector217
vector217:
  pushl $0
c0102732:	6a 00                	push   $0x0
  pushl $217
c0102734:	68 d9 00 00 00       	push   $0xd9
  jmp __alltraps
c0102739:	e9 c8 01 00 00       	jmp    c0102906 <__alltraps>

c010273e <vector218>:
.globl vector218
vector218:
  pushl $0
c010273e:	6a 00                	push   $0x0
  pushl $218
c0102740:	68 da 00 00 00       	push   $0xda
  jmp __alltraps
c0102745:	e9 bc 01 00 00       	jmp    c0102906 <__alltraps>

c010274a <vector219>:
.globl vector219
vector219:
  pushl $0
c010274a:	6a 00                	push   $0x0
  pushl $219
c010274c:	68 db 00 00 00       	push   $0xdb
  jmp __alltraps
c0102751:	e9 b0 01 00 00       	jmp    c0102906 <__alltraps>

c0102756 <vector220>:
.globl vector220
vector220:
  pushl $0
c0102756:	6a 00                	push   $0x0
  pushl $220
c0102758:	68 dc 00 00 00       	push   $0xdc
  jmp __alltraps
c010275d:	e9 a4 01 00 00       	jmp    c0102906 <__alltraps>

c0102762 <vector221>:
.globl vector221
vector221:
  pushl $0
c0102762:	6a 00                	push   $0x0
  pushl $221
c0102764:	68 dd 00 00 00       	push   $0xdd
  jmp __alltraps
c0102769:	e9 98 01 00 00       	jmp    c0102906 <__alltraps>

c010276e <vector222>:
.globl vector222
vector222:
  pushl $0
c010276e:	6a 00                	push   $0x0
  pushl $222
c0102770:	68 de 00 00 00       	push   $0xde
  jmp __alltraps
c0102775:	e9 8c 01 00 00       	jmp    c0102906 <__alltraps>

c010277a <vector223>:
.globl vector223
vector223:
  pushl $0
c010277a:	6a 00                	push   $0x0
  pushl $223
c010277c:	68 df 00 00 00       	push   $0xdf
  jmp __alltraps
c0102781:	e9 80 01 00 00       	jmp    c0102906 <__alltraps>

c0102786 <vector224>:
.globl vector224
vector224:
  pushl $0
c0102786:	6a 00                	push   $0x0
  pushl $224
c0102788:	68 e0 00 00 00       	push   $0xe0
  jmp __alltraps
c010278d:	e9 74 01 00 00       	jmp    c0102906 <__alltraps>

c0102792 <vector225>:
.globl vector225
vector225:
  pushl $0
c0102792:	6a 00                	push   $0x0
  pushl $225
c0102794:	68 e1 00 00 00       	push   $0xe1
  jmp __alltraps
c0102799:	e9 68 01 00 00       	jmp    c0102906 <__alltraps>

c010279e <vector226>:
.globl vector226
vector226:
  pushl $0
c010279e:	6a 00                	push   $0x0
  pushl $226
c01027a0:	68 e2 00 00 00       	push   $0xe2
  jmp __alltraps
c01027a5:	e9 5c 01 00 00       	jmp    c0102906 <__alltraps>

c01027aa <vector227>:
.globl vector227
vector227:
  pushl $0
c01027aa:	6a 00                	push   $0x0
  pushl $227
c01027ac:	68 e3 00 00 00       	push   $0xe3
  jmp __alltraps
c01027b1:	e9 50 01 00 00       	jmp    c0102906 <__alltraps>

c01027b6 <vector228>:
.globl vector228
vector228:
  pushl $0
c01027b6:	6a 00                	push   $0x0
  pushl $228
c01027b8:	68 e4 00 00 00       	push   $0xe4
  jmp __alltraps
c01027bd:	e9 44 01 00 00       	jmp    c0102906 <__alltraps>

c01027c2 <vector229>:
.globl vector229
vector229:
  pushl $0
c01027c2:	6a 00                	push   $0x0
  pushl $229
c01027c4:	68 e5 00 00 00       	push   $0xe5
  jmp __alltraps
c01027c9:	e9 38 01 00 00       	jmp    c0102906 <__alltraps>

c01027ce <vector230>:
.globl vector230
vector230:
  pushl $0
c01027ce:	6a 00                	push   $0x0
  pushl $230
c01027d0:	68 e6 00 00 00       	push   $0xe6
  jmp __alltraps
c01027d5:	e9 2c 01 00 00       	jmp    c0102906 <__alltraps>

c01027da <vector231>:
.globl vector231
vector231:
  pushl $0
c01027da:	6a 00                	push   $0x0
  pushl $231
c01027dc:	68 e7 00 00 00       	push   $0xe7
  jmp __alltraps
c01027e1:	e9 20 01 00 00       	jmp    c0102906 <__alltraps>

c01027e6 <vector232>:
.globl vector232
vector232:
  pushl $0
c01027e6:	6a 00                	push   $0x0
  pushl $232
c01027e8:	68 e8 00 00 00       	push   $0xe8
  jmp __alltraps
c01027ed:	e9 14 01 00 00       	jmp    c0102906 <__alltraps>

c01027f2 <vector233>:
.globl vector233
vector233:
  pushl $0
c01027f2:	6a 00                	push   $0x0
  pushl $233
c01027f4:	68 e9 00 00 00       	push   $0xe9
  jmp __alltraps
c01027f9:	e9 08 01 00 00       	jmp    c0102906 <__alltraps>

c01027fe <vector234>:
.globl vector234
vector234:
  pushl $0
c01027fe:	6a 00                	push   $0x0
  pushl $234
c0102800:	68 ea 00 00 00       	push   $0xea
  jmp __alltraps
c0102805:	e9 fc 00 00 00       	jmp    c0102906 <__alltraps>

c010280a <vector235>:
.globl vector235
vector235:
  pushl $0
c010280a:	6a 00                	push   $0x0
  pushl $235
c010280c:	68 eb 00 00 00       	push   $0xeb
  jmp __alltraps
c0102811:	e9 f0 00 00 00       	jmp    c0102906 <__alltraps>

c0102816 <vector236>:
.globl vector236
vector236:
  pushl $0
c0102816:	6a 00                	push   $0x0
  pushl $236
c0102818:	68 ec 00 00 00       	push   $0xec
  jmp __alltraps
c010281d:	e9 e4 00 00 00       	jmp    c0102906 <__alltraps>

c0102822 <vector237>:
.globl vector237
vector237:
  pushl $0
c0102822:	6a 00                	push   $0x0
  pushl $237
c0102824:	68 ed 00 00 00       	push   $0xed
  jmp __alltraps
c0102829:	e9 d8 00 00 00       	jmp    c0102906 <__alltraps>

c010282e <vector238>:
.globl vector238
vector238:
  pushl $0
c010282e:	6a 00                	push   $0x0
  pushl $238
c0102830:	68 ee 00 00 00       	push   $0xee
  jmp __alltraps
c0102835:	e9 cc 00 00 00       	jmp    c0102906 <__alltraps>

c010283a <vector239>:
.globl vector239
vector239:
  pushl $0
c010283a:	6a 00                	push   $0x0
  pushl $239
c010283c:	68 ef 00 00 00       	push   $0xef
  jmp __alltraps
c0102841:	e9 c0 00 00 00       	jmp    c0102906 <__alltraps>

c0102846 <vector240>:
.globl vector240
vector240:
  pushl $0
c0102846:	6a 00                	push   $0x0
  pushl $240
c0102848:	68 f0 00 00 00       	push   $0xf0
  jmp __alltraps
c010284d:	e9 b4 00 00 00       	jmp    c0102906 <__alltraps>

c0102852 <vector241>:
.globl vector241
vector241:
  pushl $0
c0102852:	6a 00                	push   $0x0
  pushl $241
c0102854:	68 f1 00 00 00       	push   $0xf1
  jmp __alltraps
c0102859:	e9 a8 00 00 00       	jmp    c0102906 <__alltraps>

c010285e <vector242>:
.globl vector242
vector242:
  pushl $0
c010285e:	6a 00                	push   $0x0
  pushl $242
c0102860:	68 f2 00 00 00       	push   $0xf2
  jmp __alltraps
c0102865:	e9 9c 00 00 00       	jmp    c0102906 <__alltraps>

c010286a <vector243>:
.globl vector243
vector243:
  pushl $0
c010286a:	6a 00                	push   $0x0
  pushl $243
c010286c:	68 f3 00 00 00       	push   $0xf3
  jmp __alltraps
c0102871:	e9 90 00 00 00       	jmp    c0102906 <__alltraps>

c0102876 <vector244>:
.globl vector244
vector244:
  pushl $0
c0102876:	6a 00                	push   $0x0
  pushl $244
c0102878:	68 f4 00 00 00       	push   $0xf4
  jmp __alltraps
c010287d:	e9 84 00 00 00       	jmp    c0102906 <__alltraps>

c0102882 <vector245>:
.globl vector245
vector245:
  pushl $0
c0102882:	6a 00                	push   $0x0
  pushl $245
c0102884:	68 f5 00 00 00       	push   $0xf5
  jmp __alltraps
c0102889:	e9 78 00 00 00       	jmp    c0102906 <__alltraps>

c010288e <vector246>:
.globl vector246
vector246:
  pushl $0
c010288e:	6a 00                	push   $0x0
  pushl $246
c0102890:	68 f6 00 00 00       	push   $0xf6
  jmp __alltraps
c0102895:	e9 6c 00 00 00       	jmp    c0102906 <__alltraps>

c010289a <vector247>:
.globl vector247
vector247:
  pushl $0
c010289a:	6a 00                	push   $0x0
  pushl $247
c010289c:	68 f7 00 00 00       	push   $0xf7
  jmp __alltraps
c01028a1:	e9 60 00 00 00       	jmp    c0102906 <__alltraps>

c01028a6 <vector248>:
.globl vector248
vector248:
  pushl $0
c01028a6:	6a 00                	push   $0x0
  pushl $248
c01028a8:	68 f8 00 00 00       	push   $0xf8
  jmp __alltraps
c01028ad:	e9 54 00 00 00       	jmp    c0102906 <__alltraps>

c01028b2 <vector249>:
.globl vector249
vector249:
  pushl $0
c01028b2:	6a 00                	push   $0x0
  pushl $249
c01028b4:	68 f9 00 00 00       	push   $0xf9
  jmp __alltraps
c01028b9:	e9 48 00 00 00       	jmp    c0102906 <__alltraps>

c01028be <vector250>:
.globl vector250
vector250:
  pushl $0
c01028be:	6a 00                	push   $0x0
  pushl $250
c01028c0:	68 fa 00 00 00       	push   $0xfa
  jmp __alltraps
c01028c5:	e9 3c 00 00 00       	jmp    c0102906 <__alltraps>

c01028ca <vector251>:
.globl vector251
vector251:
  pushl $0
c01028ca:	6a 00                	push   $0x0
  pushl $251
c01028cc:	68 fb 00 00 00       	push   $0xfb
  jmp __alltraps
c01028d1:	e9 30 00 00 00       	jmp    c0102906 <__alltraps>

c01028d6 <vector252>:
.globl vector252
vector252:
  pushl $0
c01028d6:	6a 00                	push   $0x0
  pushl $252
c01028d8:	68 fc 00 00 00       	push   $0xfc
  jmp __alltraps
c01028dd:	e9 24 00 00 00       	jmp    c0102906 <__alltraps>

c01028e2 <vector253>:
.globl vector253
vector253:
  pushl $0
c01028e2:	6a 00                	push   $0x0
  pushl $253
c01028e4:	68 fd 00 00 00       	push   $0xfd
  jmp __alltraps
c01028e9:	e9 18 00 00 00       	jmp    c0102906 <__alltraps>

c01028ee <vector254>:
.globl vector254
vector254:
  pushl $0
c01028ee:	6a 00                	push   $0x0
  pushl $254
c01028f0:	68 fe 00 00 00       	push   $0xfe
  jmp __alltraps
c01028f5:	e9 0c 00 00 00       	jmp    c0102906 <__alltraps>

c01028fa <vector255>:
.globl vector255
vector255:
  pushl $0
c01028fa:	6a 00                	push   $0x0
  pushl $255
c01028fc:	68 ff 00 00 00       	push   $0xff
  jmp __alltraps
c0102901:	e9 00 00 00 00       	jmp    c0102906 <__alltraps>

c0102906 <__alltraps>:
.text
.globl __alltraps
__alltraps:
    # push registers to build a trap frame
    # therefore make the stack look like a struct trapframe
    pushl %ds
c0102906:	1e                   	push   %ds
    pushl %es
c0102907:	06                   	push   %es
    pushl %fs
c0102908:	0f a0                	push   %fs
    pushl %gs
c010290a:	0f a8                	push   %gs
    pushal
c010290c:	60                   	pusha  

    # load GD_KDATA into %ds and %es to set up data segments for kernel
    movl $GD_KDATA, %eax
c010290d:	b8 10 00 00 00       	mov    $0x10,%eax
    movw %ax, %ds
c0102912:	8e d8                	mov    %eax,%ds
    movw %ax, %es
c0102914:	8e c0                	mov    %eax,%es

    # push %esp to pass a pointer to the trapframe as an argument to trap()
    pushl %esp
c0102916:	54                   	push   %esp

    # call trap(tf), where tf=%esp
    call trap
c0102917:	e8 61 f5 ff ff       	call   c0101e7d <trap>

    # pop the pushed stack pointer
    popl %esp
c010291c:	5c                   	pop    %esp

c010291d <__trapret>:

    # return falls through to trapret...
.globl __trapret
__trapret:
    # restore registers from stack
    popal
c010291d:	61                   	popa   

    # restore %ds, %es, %fs and %gs
    popl %gs
c010291e:	0f a9                	pop    %gs
    popl %fs
c0102920:	0f a1                	pop    %fs
    popl %es
c0102922:	07                   	pop    %es
    popl %ds
c0102923:	1f                   	pop    %ds

    # get rid of the trap number and error code
    addl $0x8, %esp
c0102924:	83 c4 08             	add    $0x8,%esp
    iret
c0102927:	cf                   	iret   

c0102928 <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
c0102928:	55                   	push   %ebp
c0102929:	89 e5                	mov    %esp,%ebp
    return page - pages;//返回在物理内存中第几页
c010292b:	8b 45 08             	mov    0x8(%ebp),%eax
c010292e:	8b 15 18 af 11 c0    	mov    0xc011af18,%edx
c0102934:	29 d0                	sub    %edx,%eax
c0102936:	c1 f8 02             	sar    $0x2,%eax
c0102939:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
c010293f:	5d                   	pop    %ebp
c0102940:	c3                   	ret    

c0102941 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
c0102941:	55                   	push   %ebp
c0102942:	89 e5                	mov    %esp,%ebp
    return page2ppn(page) << PGSHIFT;
c0102944:	ff 75 08             	pushl  0x8(%ebp)
c0102947:	e8 dc ff ff ff       	call   c0102928 <page2ppn>
c010294c:	83 c4 04             	add    $0x4,%esp
c010294f:	c1 e0 0c             	shl    $0xc,%eax
}
c0102952:	c9                   	leave  
c0102953:	c3                   	ret    

c0102954 <pa2page>:

static inline struct Page *
pa2page(uintptr_t pa) {
c0102954:	55                   	push   %ebp
c0102955:	89 e5                	mov    %esp,%ebp
c0102957:	83 ec 08             	sub    $0x8,%esp
    if (PPN(pa) >= npage) {
c010295a:	8b 45 08             	mov    0x8(%ebp),%eax
c010295d:	c1 e8 0c             	shr    $0xc,%eax
c0102960:	89 c2                	mov    %eax,%edx
c0102962:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0102967:	39 c2                	cmp    %eax,%edx
c0102969:	72 14                	jb     c010297f <pa2page+0x2b>
        panic("pa2page called with invalid pa");
c010296b:	83 ec 04             	sub    $0x4,%esp
c010296e:	68 f0 62 10 c0       	push   $0xc01062f0
c0102973:	6a 5a                	push   $0x5a
c0102975:	68 0f 63 10 c0       	push   $0xc010630f
c010297a:	e8 64 da ff ff       	call   c01003e3 <__panic>
    }
    return &pages[PPN(pa)];
c010297f:	8b 0d 18 af 11 c0    	mov    0xc011af18,%ecx
c0102985:	8b 45 08             	mov    0x8(%ebp),%eax
c0102988:	c1 e8 0c             	shr    $0xc,%eax
c010298b:	89 c2                	mov    %eax,%edx
c010298d:	89 d0                	mov    %edx,%eax
c010298f:	c1 e0 02             	shl    $0x2,%eax
c0102992:	01 d0                	add    %edx,%eax
c0102994:	c1 e0 02             	shl    $0x2,%eax
c0102997:	01 c8                	add    %ecx,%eax
}
c0102999:	c9                   	leave  
c010299a:	c3                   	ret    

c010299b <page2kva>:

static inline void *
page2kva(struct Page *page) {
c010299b:	55                   	push   %ebp
c010299c:	89 e5                	mov    %esp,%ebp
c010299e:	83 ec 18             	sub    $0x18,%esp
    return KADDR(page2pa(page));
c01029a1:	ff 75 08             	pushl  0x8(%ebp)
c01029a4:	e8 98 ff ff ff       	call   c0102941 <page2pa>
c01029a9:	83 c4 04             	add    $0x4,%esp
c01029ac:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01029af:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01029b2:	c1 e8 0c             	shr    $0xc,%eax
c01029b5:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01029b8:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01029bd:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c01029c0:	72 14                	jb     c01029d6 <page2kva+0x3b>
c01029c2:	ff 75 f4             	pushl  -0xc(%ebp)
c01029c5:	68 20 63 10 c0       	push   $0xc0106320
c01029ca:	6a 61                	push   $0x61
c01029cc:	68 0f 63 10 c0       	push   $0xc010630f
c01029d1:	e8 0d da ff ff       	call   c01003e3 <__panic>
c01029d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01029d9:	2d 00 00 00 40       	sub    $0x40000000,%eax
}
c01029de:	c9                   	leave  
c01029df:	c3                   	ret    

c01029e0 <pte2page>:
kva2page(void *kva) {
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte) {
c01029e0:	55                   	push   %ebp
c01029e1:	89 e5                	mov    %esp,%ebp
c01029e3:	83 ec 08             	sub    $0x8,%esp
    if (!(pte & PTE_P)) {
c01029e6:	8b 45 08             	mov    0x8(%ebp),%eax
c01029e9:	83 e0 01             	and    $0x1,%eax
c01029ec:	85 c0                	test   %eax,%eax
c01029ee:	75 14                	jne    c0102a04 <pte2page+0x24>
        panic("pte2page called with invalid pte");
c01029f0:	83 ec 04             	sub    $0x4,%esp
c01029f3:	68 44 63 10 c0       	push   $0xc0106344
c01029f8:	6a 6c                	push   $0x6c
c01029fa:	68 0f 63 10 c0       	push   $0xc010630f
c01029ff:	e8 df d9 ff ff       	call   c01003e3 <__panic>
    }
    return pa2page(PTE_ADDR(pte));
c0102a04:	8b 45 08             	mov    0x8(%ebp),%eax
c0102a07:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0102a0c:	83 ec 0c             	sub    $0xc,%esp
c0102a0f:	50                   	push   %eax
c0102a10:	e8 3f ff ff ff       	call   c0102954 <pa2page>
c0102a15:	83 c4 10             	add    $0x10,%esp
}
c0102a18:	c9                   	leave  
c0102a19:	c3                   	ret    

c0102a1a <pde2page>:

static inline struct Page *
pde2page(pde_t pde) {
c0102a1a:	55                   	push   %ebp
c0102a1b:	89 e5                	mov    %esp,%ebp
c0102a1d:	83 ec 08             	sub    $0x8,%esp
    return pa2page(PDE_ADDR(pde));
c0102a20:	8b 45 08             	mov    0x8(%ebp),%eax
c0102a23:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0102a28:	83 ec 0c             	sub    $0xc,%esp
c0102a2b:	50                   	push   %eax
c0102a2c:	e8 23 ff ff ff       	call   c0102954 <pa2page>
c0102a31:	83 c4 10             	add    $0x10,%esp
}
c0102a34:	c9                   	leave  
c0102a35:	c3                   	ret    

c0102a36 <page_ref>:

static inline int
page_ref(struct Page *page) {
c0102a36:	55                   	push   %ebp
c0102a37:	89 e5                	mov    %esp,%ebp
    return page->ref;
c0102a39:	8b 45 08             	mov    0x8(%ebp),%eax
c0102a3c:	8b 00                	mov    (%eax),%eax
}
c0102a3e:	5d                   	pop    %ebp
c0102a3f:	c3                   	ret    

c0102a40 <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
c0102a40:	55                   	push   %ebp
c0102a41:	89 e5                	mov    %esp,%ebp
    page->ref = val;
c0102a43:	8b 45 08             	mov    0x8(%ebp),%eax
c0102a46:	8b 55 0c             	mov    0xc(%ebp),%edx
c0102a49:	89 10                	mov    %edx,(%eax)
}
c0102a4b:	90                   	nop
c0102a4c:	5d                   	pop    %ebp
c0102a4d:	c3                   	ret    

c0102a4e <page_ref_inc>:

static inline int
page_ref_inc(struct Page *page) {
c0102a4e:	55                   	push   %ebp
c0102a4f:	89 e5                	mov    %esp,%ebp
    page->ref += 1;
c0102a51:	8b 45 08             	mov    0x8(%ebp),%eax
c0102a54:	8b 00                	mov    (%eax),%eax
c0102a56:	8d 50 01             	lea    0x1(%eax),%edx
c0102a59:	8b 45 08             	mov    0x8(%ebp),%eax
c0102a5c:	89 10                	mov    %edx,(%eax)
    return page->ref;
c0102a5e:	8b 45 08             	mov    0x8(%ebp),%eax
c0102a61:	8b 00                	mov    (%eax),%eax
}
c0102a63:	5d                   	pop    %ebp
c0102a64:	c3                   	ret    

c0102a65 <page_ref_dec>:

static inline int
page_ref_dec(struct Page *page) {
c0102a65:	55                   	push   %ebp
c0102a66:	89 e5                	mov    %esp,%ebp
    page->ref -= 1;
c0102a68:	8b 45 08             	mov    0x8(%ebp),%eax
c0102a6b:	8b 00                	mov    (%eax),%eax
c0102a6d:	8d 50 ff             	lea    -0x1(%eax),%edx
c0102a70:	8b 45 08             	mov    0x8(%ebp),%eax
c0102a73:	89 10                	mov    %edx,(%eax)
    return page->ref;
c0102a75:	8b 45 08             	mov    0x8(%ebp),%eax
c0102a78:	8b 00                	mov    (%eax),%eax
}
c0102a7a:	5d                   	pop    %ebp
c0102a7b:	c3                   	ret    

c0102a7c <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
c0102a7c:	55                   	push   %ebp
c0102a7d:	89 e5                	mov    %esp,%ebp
c0102a7f:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
c0102a82:	9c                   	pushf  
c0102a83:	58                   	pop    %eax
c0102a84:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
c0102a87:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {
c0102a8a:	25 00 02 00 00       	and    $0x200,%eax
c0102a8f:	85 c0                	test   %eax,%eax
c0102a91:	74 0c                	je     c0102a9f <__intr_save+0x23>
        intr_disable();
c0102a93:	e8 e7 ed ff ff       	call   c010187f <intr_disable>
        return 1;
c0102a98:	b8 01 00 00 00       	mov    $0x1,%eax
c0102a9d:	eb 05                	jmp    c0102aa4 <__intr_save+0x28>
    }
    return 0;
c0102a9f:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0102aa4:	c9                   	leave  
c0102aa5:	c3                   	ret    

c0102aa6 <__intr_restore>:

static inline void
__intr_restore(bool flag) {
c0102aa6:	55                   	push   %ebp
c0102aa7:	89 e5                	mov    %esp,%ebp
c0102aa9:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
c0102aac:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0102ab0:	74 05                	je     c0102ab7 <__intr_restore+0x11>
        intr_enable();
c0102ab2:	e8 c1 ed ff ff       	call   c0101878 <intr_enable>
    }
}
c0102ab7:	90                   	nop
c0102ab8:	c9                   	leave  
c0102ab9:	c3                   	ret    

c0102aba <lgdt>:
/* *
 * lgdt - load the global descriptor table register and reset the
 * data/code segement registers for kernel.
 * */
static inline void
lgdt(struct pseudodesc *pd) {                                         //加载gdt地址到gdtr
c0102aba:	55                   	push   %ebp
c0102abb:	89 e5                	mov    %esp,%ebp
    asm volatile ("lgdt (%0)" :: "r" (pd));
c0102abd:	8b 45 08             	mov    0x8(%ebp),%eax
c0102ac0:	0f 01 10             	lgdtl  (%eax)
    asm volatile ("movw %%ax, %%gs" :: "a" (USER_DS));
c0102ac3:	b8 23 00 00 00       	mov    $0x23,%eax
c0102ac8:	8e e8                	mov    %eax,%gs
    asm volatile ("movw %%ax, %%fs" :: "a" (USER_DS));
c0102aca:	b8 23 00 00 00       	mov    $0x23,%eax
c0102acf:	8e e0                	mov    %eax,%fs
    asm volatile ("movw %%ax, %%es" :: "a" (KERNEL_DS));
c0102ad1:	b8 10 00 00 00       	mov    $0x10,%eax
c0102ad6:	8e c0                	mov    %eax,%es
    asm volatile ("movw %%ax, %%ds" :: "a" (KERNEL_DS));
c0102ad8:	b8 10 00 00 00       	mov    $0x10,%eax
c0102add:	8e d8                	mov    %eax,%ds
    asm volatile ("movw %%ax, %%ss" :: "a" (KERNEL_DS));
c0102adf:	b8 10 00 00 00       	mov    $0x10,%eax
c0102ae4:	8e d0                	mov    %eax,%ss
    // reload cs
    asm volatile ("ljmp %0, $1f\n 1:\n" :: "i" (KERNEL_CS));
c0102ae6:	ea ed 2a 10 c0 08 00 	ljmp   $0x8,$0xc0102aed
}
c0102aed:	90                   	nop
c0102aee:	5d                   	pop    %ebp
c0102aef:	c3                   	ret    

c0102af0 <load_esp0>:
 * load_esp0 - change the ESP0 in default task state segment,
 * so that we can use different kernel stack when we trap frame
 * user to kernel.
 * */
void
load_esp0(uintptr_t esp0) {
c0102af0:	55                   	push   %ebp
c0102af1:	89 e5                	mov    %esp,%ebp
    ts.ts_esp0 = esp0;
c0102af3:	8b 45 08             	mov    0x8(%ebp),%eax
c0102af6:	a3 a4 ae 11 c0       	mov    %eax,0xc011aea4
}
c0102afb:	90                   	nop
c0102afc:	5d                   	pop    %ebp
c0102afd:	c3                   	ret    

c0102afe <gdt_init>:

/* gdt_init - initialize the default GDT and TSS */
static void
gdt_init(void) {
c0102afe:	55                   	push   %ebp
c0102aff:	89 e5                	mov    %esp,%ebp
c0102b01:	83 ec 10             	sub    $0x10,%esp
    // set boot kernel stack and default SS0
    load_esp0((uintptr_t)bootstacktop);
c0102b04:	b8 00 70 11 c0       	mov    $0xc0117000,%eax
c0102b09:	50                   	push   %eax
c0102b0a:	e8 e1 ff ff ff       	call   c0102af0 <load_esp0>
c0102b0f:	83 c4 04             	add    $0x4,%esp
    ts.ts_ss0 = KERNEL_DS;
c0102b12:	66 c7 05 a8 ae 11 c0 	movw   $0x10,0xc011aea8
c0102b19:	10 00 

    // initialize the TSS filed of the gdt
    gdt[SEG_TSS] = SEGTSS(STS_T32A, (uintptr_t)&ts, sizeof(ts), DPL_KERNEL);
c0102b1b:	66 c7 05 28 7a 11 c0 	movw   $0x68,0xc0117a28
c0102b22:	68 00 
c0102b24:	b8 a0 ae 11 c0       	mov    $0xc011aea0,%eax
c0102b29:	66 a3 2a 7a 11 c0    	mov    %ax,0xc0117a2a
c0102b2f:	b8 a0 ae 11 c0       	mov    $0xc011aea0,%eax
c0102b34:	c1 e8 10             	shr    $0x10,%eax
c0102b37:	a2 2c 7a 11 c0       	mov    %al,0xc0117a2c
c0102b3c:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c0102b43:	83 e0 f0             	and    $0xfffffff0,%eax
c0102b46:	83 c8 09             	or     $0x9,%eax
c0102b49:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c0102b4e:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c0102b55:	83 e0 ef             	and    $0xffffffef,%eax
c0102b58:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c0102b5d:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c0102b64:	83 e0 9f             	and    $0xffffff9f,%eax
c0102b67:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c0102b6c:	0f b6 05 2d 7a 11 c0 	movzbl 0xc0117a2d,%eax
c0102b73:	83 c8 80             	or     $0xffffff80,%eax
c0102b76:	a2 2d 7a 11 c0       	mov    %al,0xc0117a2d
c0102b7b:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102b82:	83 e0 f0             	and    $0xfffffff0,%eax
c0102b85:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102b8a:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102b91:	83 e0 ef             	and    $0xffffffef,%eax
c0102b94:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102b99:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102ba0:	83 e0 df             	and    $0xffffffdf,%eax
c0102ba3:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102ba8:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102baf:	83 c8 40             	or     $0x40,%eax
c0102bb2:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102bb7:	0f b6 05 2e 7a 11 c0 	movzbl 0xc0117a2e,%eax
c0102bbe:	83 e0 7f             	and    $0x7f,%eax
c0102bc1:	a2 2e 7a 11 c0       	mov    %al,0xc0117a2e
c0102bc6:	b8 a0 ae 11 c0       	mov    $0xc011aea0,%eax
c0102bcb:	c1 e8 18             	shr    $0x18,%eax
c0102bce:	a2 2f 7a 11 c0       	mov    %al,0xc0117a2f

    // reload all segment registers
    lgdt(&gdt_pd);
c0102bd3:	68 30 7a 11 c0       	push   $0xc0117a30
c0102bd8:	e8 dd fe ff ff       	call   c0102aba <lgdt>
c0102bdd:	83 c4 04             	add    $0x4,%esp
c0102be0:	66 c7 45 fe 28 00    	movw   $0x28,-0x2(%ebp)
    asm volatile ("cli" ::: "memory");
}

static inline void
ltr(uint16_t sel) {
    asm volatile ("ltr %0" :: "r" (sel) : "memory");
c0102be6:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
c0102bea:	0f 00 d8             	ltr    %ax

    // load the TSS
    ltr(GD_TSS);
}
c0102bed:	90                   	nop
c0102bee:	c9                   	leave  
c0102bef:	c3                   	ret    

c0102bf0 <init_pmm_manager>:

//init_pmm_manager - initialize a pmm_manager instance
static void
init_pmm_manager(void) {
c0102bf0:	55                   	push   %ebp
c0102bf1:	89 e5                	mov    %esp,%ebp
c0102bf3:	83 ec 08             	sub    $0x8,%esp
    pmm_manager = &default_pmm_manager;
c0102bf6:	c7 05 10 af 11 c0 14 	movl   $0xc0106d14,0xc011af10
c0102bfd:	6d 10 c0 
    cprintf("memory management: %s\n", pmm_manager->name);
c0102c00:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102c05:	8b 00                	mov    (%eax),%eax
c0102c07:	83 ec 08             	sub    $0x8,%esp
c0102c0a:	50                   	push   %eax
c0102c0b:	68 70 63 10 c0       	push   $0xc0106370
c0102c10:	e8 68 d6 ff ff       	call   c010027d <cprintf>
c0102c15:	83 c4 10             	add    $0x10,%esp
    pmm_manager->init();
c0102c18:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102c1d:	8b 40 04             	mov    0x4(%eax),%eax
c0102c20:	ff d0                	call   *%eax
}
c0102c22:	90                   	nop
c0102c23:	c9                   	leave  
c0102c24:	c3                   	ret    

c0102c25 <init_memmap>:

//init_memmap - call pmm->init_memmap to build Page struct for free memory  
static void
init_memmap(struct Page *base, size_t n) {
c0102c25:	55                   	push   %ebp
c0102c26:	89 e5                	mov    %esp,%ebp
c0102c28:	83 ec 08             	sub    $0x8,%esp
    pmm_manager->init_memmap(base, n);
c0102c2b:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102c30:	8b 40 08             	mov    0x8(%eax),%eax
c0102c33:	83 ec 08             	sub    $0x8,%esp
c0102c36:	ff 75 0c             	pushl  0xc(%ebp)
c0102c39:	ff 75 08             	pushl  0x8(%ebp)
c0102c3c:	ff d0                	call   *%eax
c0102c3e:	83 c4 10             	add    $0x10,%esp
}
c0102c41:	90                   	nop
c0102c42:	c9                   	leave  
c0102c43:	c3                   	ret    

c0102c44 <alloc_pages>:

//alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE memory 
struct Page *
alloc_pages(size_t n) {
c0102c44:	55                   	push   %ebp
c0102c45:	89 e5                	mov    %esp,%ebp
c0102c47:	83 ec 18             	sub    $0x18,%esp
    struct Page *page=NULL;
c0102c4a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
c0102c51:	e8 26 fe ff ff       	call   c0102a7c <__intr_save>
c0102c56:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        page = pmm_manager->alloc_pages(n);
c0102c59:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102c5e:	8b 40 0c             	mov    0xc(%eax),%eax
c0102c61:	83 ec 0c             	sub    $0xc,%esp
c0102c64:	ff 75 08             	pushl  0x8(%ebp)
c0102c67:	ff d0                	call   *%eax
c0102c69:	83 c4 10             	add    $0x10,%esp
c0102c6c:	89 45 f4             	mov    %eax,-0xc(%ebp)
    }
    local_intr_restore(intr_flag);
c0102c6f:	83 ec 0c             	sub    $0xc,%esp
c0102c72:	ff 75 f0             	pushl  -0x10(%ebp)
c0102c75:	e8 2c fe ff ff       	call   c0102aa6 <__intr_restore>
c0102c7a:	83 c4 10             	add    $0x10,%esp
    return page;
c0102c7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0102c80:	c9                   	leave  
c0102c81:	c3                   	ret    

c0102c82 <free_pages>:

//free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory 
void
free_pages(struct Page *base, size_t n) {
c0102c82:	55                   	push   %ebp
c0102c83:	89 e5                	mov    %esp,%ebp
c0102c85:	83 ec 18             	sub    $0x18,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
c0102c88:	e8 ef fd ff ff       	call   c0102a7c <__intr_save>
c0102c8d:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        pmm_manager->free_pages(base, n);
c0102c90:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102c95:	8b 40 10             	mov    0x10(%eax),%eax
c0102c98:	83 ec 08             	sub    $0x8,%esp
c0102c9b:	ff 75 0c             	pushl  0xc(%ebp)
c0102c9e:	ff 75 08             	pushl  0x8(%ebp)
c0102ca1:	ff d0                	call   *%eax
c0102ca3:	83 c4 10             	add    $0x10,%esp
    }
    local_intr_restore(intr_flag);
c0102ca6:	83 ec 0c             	sub    $0xc,%esp
c0102ca9:	ff 75 f4             	pushl  -0xc(%ebp)
c0102cac:	e8 f5 fd ff ff       	call   c0102aa6 <__intr_restore>
c0102cb1:	83 c4 10             	add    $0x10,%esp
}
c0102cb4:	90                   	nop
c0102cb5:	c9                   	leave  
c0102cb6:	c3                   	ret    

c0102cb7 <nr_free_pages>:

//nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE) 
//of current free memory
size_t
nr_free_pages(void) {
c0102cb7:	55                   	push   %ebp
c0102cb8:	89 e5                	mov    %esp,%ebp
c0102cba:	83 ec 18             	sub    $0x18,%esp
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
c0102cbd:	e8 ba fd ff ff       	call   c0102a7c <__intr_save>
c0102cc2:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        ret = pmm_manager->nr_free_pages();
c0102cc5:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c0102cca:	8b 40 14             	mov    0x14(%eax),%eax
c0102ccd:	ff d0                	call   *%eax
c0102ccf:	89 45 f0             	mov    %eax,-0x10(%ebp)
    }
    local_intr_restore(intr_flag);
c0102cd2:	83 ec 0c             	sub    $0xc,%esp
c0102cd5:	ff 75 f4             	pushl  -0xc(%ebp)
c0102cd8:	e8 c9 fd ff ff       	call   c0102aa6 <__intr_restore>
c0102cdd:	83 c4 10             	add    $0x10,%esp
    return ret;
c0102ce0:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
c0102ce3:	c9                   	leave  
c0102ce4:	c3                   	ret    

c0102ce5 <page_init>:

/* pmm_init - initialize the physical memory management */
static void
page_init(void) {
c0102ce5:	55                   	push   %ebp
c0102ce6:	89 e5                	mov    %esp,%ebp
c0102ce8:	57                   	push   %edi
c0102ce9:	56                   	push   %esi
c0102cea:	53                   	push   %ebx
c0102ceb:	83 ec 7c             	sub    $0x7c,%esp
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
c0102cee:	c7 45 c4 00 80 00 c0 	movl   $0xc0008000,-0x3c(%ebp)
    uint64_t maxpa = 0;
c0102cf5:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
c0102cfc:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

    cprintf("e820map:\n");
c0102d03:	83 ec 0c             	sub    $0xc,%esp
c0102d06:	68 87 63 10 c0       	push   $0xc0106387
c0102d0b:	e8 6d d5 ff ff       	call   c010027d <cprintf>
c0102d10:	83 c4 10             	add    $0x10,%esp
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
c0102d13:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0102d1a:	e9 fc 00 00 00       	jmp    c0102e1b <page_init+0x136>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
c0102d1f:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102d22:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102d25:	89 d0                	mov    %edx,%eax
c0102d27:	c1 e0 02             	shl    $0x2,%eax
c0102d2a:	01 d0                	add    %edx,%eax
c0102d2c:	c1 e0 02             	shl    $0x2,%eax
c0102d2f:	01 c8                	add    %ecx,%eax
c0102d31:	8b 50 08             	mov    0x8(%eax),%edx
c0102d34:	8b 40 04             	mov    0x4(%eax),%eax
c0102d37:	89 45 b8             	mov    %eax,-0x48(%ebp)
c0102d3a:	89 55 bc             	mov    %edx,-0x44(%ebp)
c0102d3d:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102d40:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102d43:	89 d0                	mov    %edx,%eax
c0102d45:	c1 e0 02             	shl    $0x2,%eax
c0102d48:	01 d0                	add    %edx,%eax
c0102d4a:	c1 e0 02             	shl    $0x2,%eax
c0102d4d:	01 c8                	add    %ecx,%eax
c0102d4f:	8b 48 0c             	mov    0xc(%eax),%ecx
c0102d52:	8b 58 10             	mov    0x10(%eax),%ebx
c0102d55:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0102d58:	8b 55 bc             	mov    -0x44(%ebp),%edx
c0102d5b:	01 c8                	add    %ecx,%eax
c0102d5d:	11 da                	adc    %ebx,%edx
c0102d5f:	89 45 b0             	mov    %eax,-0x50(%ebp)
c0102d62:	89 55 b4             	mov    %edx,-0x4c(%ebp)
        cprintf("  memory: %08llx, [%08llx, %08llx], type = %d.\n",
c0102d65:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102d68:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102d6b:	89 d0                	mov    %edx,%eax
c0102d6d:	c1 e0 02             	shl    $0x2,%eax
c0102d70:	01 d0                	add    %edx,%eax
c0102d72:	c1 e0 02             	shl    $0x2,%eax
c0102d75:	01 c8                	add    %ecx,%eax
c0102d77:	83 c0 14             	add    $0x14,%eax
c0102d7a:	8b 00                	mov    (%eax),%eax
c0102d7c:	89 45 84             	mov    %eax,-0x7c(%ebp)
c0102d7f:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0102d82:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0102d85:	83 c0 ff             	add    $0xffffffff,%eax
c0102d88:	83 d2 ff             	adc    $0xffffffff,%edx
c0102d8b:	89 c1                	mov    %eax,%ecx
c0102d8d:	89 d3                	mov    %edx,%ebx
c0102d8f:	8b 55 c4             	mov    -0x3c(%ebp),%edx
c0102d92:	89 55 80             	mov    %edx,-0x80(%ebp)
c0102d95:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102d98:	89 d0                	mov    %edx,%eax
c0102d9a:	c1 e0 02             	shl    $0x2,%eax
c0102d9d:	01 d0                	add    %edx,%eax
c0102d9f:	c1 e0 02             	shl    $0x2,%eax
c0102da2:	03 45 80             	add    -0x80(%ebp),%eax
c0102da5:	8b 50 10             	mov    0x10(%eax),%edx
c0102da8:	8b 40 0c             	mov    0xc(%eax),%eax
c0102dab:	ff 75 84             	pushl  -0x7c(%ebp)
c0102dae:	53                   	push   %ebx
c0102daf:	51                   	push   %ecx
c0102db0:	ff 75 bc             	pushl  -0x44(%ebp)
c0102db3:	ff 75 b8             	pushl  -0x48(%ebp)
c0102db6:	52                   	push   %edx
c0102db7:	50                   	push   %eax
c0102db8:	68 94 63 10 c0       	push   $0xc0106394
c0102dbd:	e8 bb d4 ff ff       	call   c010027d <cprintf>
c0102dc2:	83 c4 20             	add    $0x20,%esp
                memmap->map[i].size, begin, end - 1, memmap->map[i].type);
        if (memmap->map[i].type == E820_ARM) {
c0102dc5:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102dc8:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102dcb:	89 d0                	mov    %edx,%eax
c0102dcd:	c1 e0 02             	shl    $0x2,%eax
c0102dd0:	01 d0                	add    %edx,%eax
c0102dd2:	c1 e0 02             	shl    $0x2,%eax
c0102dd5:	01 c8                	add    %ecx,%eax
c0102dd7:	83 c0 14             	add    $0x14,%eax
c0102dda:	8b 00                	mov    (%eax),%eax
c0102ddc:	83 f8 01             	cmp    $0x1,%eax
c0102ddf:	75 36                	jne    c0102e17 <page_init+0x132>
            if (maxpa < end && begin < KMEMSIZE) {
c0102de1:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0102de4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0102de7:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
c0102dea:	77 2b                	ja     c0102e17 <page_init+0x132>
c0102dec:	3b 55 b4             	cmp    -0x4c(%ebp),%edx
c0102def:	72 05                	jb     c0102df6 <page_init+0x111>
c0102df1:	3b 45 b0             	cmp    -0x50(%ebp),%eax
c0102df4:	73 21                	jae    c0102e17 <page_init+0x132>
c0102df6:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
c0102dfa:	77 1b                	ja     c0102e17 <page_init+0x132>
c0102dfc:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
c0102e00:	72 09                	jb     c0102e0b <page_init+0x126>
c0102e02:	81 7d b8 ff ff ff 37 	cmpl   $0x37ffffff,-0x48(%ebp)
c0102e09:	77 0c                	ja     c0102e17 <page_init+0x132>
                maxpa = end;
c0102e0b:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0102e0e:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0102e11:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0102e14:	89 55 e4             	mov    %edx,-0x1c(%ebp)
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);
    uint64_t maxpa = 0;

    cprintf("e820map:\n");
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
c0102e17:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
c0102e1b:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0102e1e:	8b 00                	mov    (%eax),%eax
c0102e20:	3b 45 dc             	cmp    -0x24(%ebp),%eax
c0102e23:	0f 8f f6 fe ff ff    	jg     c0102d1f <page_init+0x3a>
            if (maxpa < end && begin < KMEMSIZE) {
                maxpa = end;
            }//探测最大内存空间
        }
    }
    if (maxpa > KMEMSIZE) {
c0102e29:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0102e2d:	72 1d                	jb     c0102e4c <page_init+0x167>
c0102e2f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0102e33:	77 09                	ja     c0102e3e <page_init+0x159>
c0102e35:	81 7d e0 00 00 00 38 	cmpl   $0x38000000,-0x20(%ebp)
c0102e3c:	76 0e                	jbe    c0102e4c <page_init+0x167>
        maxpa = KMEMSIZE;
c0102e3e:	c7 45 e0 00 00 00 38 	movl   $0x38000000,-0x20(%ebp)
c0102e45:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    }  //不超过最大可用内存空间

    extern char end[]; //bootloader加载kernel的结束地址，用来存放page

    npage = maxpa / PGSIZE; //最大页表数目
c0102e4c:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0102e4f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0102e52:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
c0102e56:	c1 ea 0c             	shr    $0xc,%edx
c0102e59:	a3 80 ae 11 c0       	mov    %eax,0xc011ae80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);//指向end所在页表后的第一个页表 虚拟地址  存放页表
c0102e5e:	c7 45 ac 00 10 00 00 	movl   $0x1000,-0x54(%ebp)
c0102e65:	b8 28 af 11 c0       	mov    $0xc011af28,%eax
c0102e6a:	8d 50 ff             	lea    -0x1(%eax),%edx
c0102e6d:	8b 45 ac             	mov    -0x54(%ebp),%eax
c0102e70:	01 d0                	add    %edx,%eax
c0102e72:	89 45 a8             	mov    %eax,-0x58(%ebp)
c0102e75:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0102e78:	ba 00 00 00 00       	mov    $0x0,%edx
c0102e7d:	f7 75 ac             	divl   -0x54(%ebp)
c0102e80:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0102e83:	29 d0                	sub    %edx,%eax
c0102e85:	a3 18 af 11 c0       	mov    %eax,0xc011af18

    for (i = 0; i < npage; i ++) {
c0102e8a:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0102e91:	eb 2f                	jmp    c0102ec2 <page_init+0x1dd>
        SetPageReserved(pages + i);
c0102e93:	8b 0d 18 af 11 c0    	mov    0xc011af18,%ecx
c0102e99:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102e9c:	89 d0                	mov    %edx,%eax
c0102e9e:	c1 e0 02             	shl    $0x2,%eax
c0102ea1:	01 d0                	add    %edx,%eax
c0102ea3:	c1 e0 02             	shl    $0x2,%eax
c0102ea6:	01 c8                	add    %ecx,%eax
c0102ea8:	83 c0 04             	add    $0x4,%eax
c0102eab:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
c0102eb2:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0102eb5:	8b 45 8c             	mov    -0x74(%ebp),%eax
c0102eb8:	8b 55 90             	mov    -0x70(%ebp),%edx
c0102ebb:	0f ab 10             	bts    %edx,(%eax)
    extern char end[]; //bootloader加载kernel的结束地址，用来存放page

    npage = maxpa / PGSIZE; //最大页表数目
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);//指向end所在页表后的第一个页表 虚拟地址  存放页表

    for (i = 0; i < npage; i ++) {
c0102ebe:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
c0102ec2:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102ec5:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0102eca:	39 c2                	cmp    %eax,%edx
c0102ecc:	72 c5                	jb     c0102e93 <page_init+0x1ae>
        SetPageReserved(pages + i);
    }//暂时都设置为保留

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);//实地址，空闲表
c0102ece:	8b 15 80 ae 11 c0    	mov    0xc011ae80,%edx
c0102ed4:	89 d0                	mov    %edx,%eax
c0102ed6:	c1 e0 02             	shl    $0x2,%eax
c0102ed9:	01 d0                	add    %edx,%eax
c0102edb:	c1 e0 02             	shl    $0x2,%eax
c0102ede:	89 c2                	mov    %eax,%edx
c0102ee0:	a1 18 af 11 c0       	mov    0xc011af18,%eax
c0102ee5:	01 d0                	add    %edx,%eax
c0102ee7:	89 45 a4             	mov    %eax,-0x5c(%ebp)
c0102eea:	81 7d a4 ff ff ff bf 	cmpl   $0xbfffffff,-0x5c(%ebp)
c0102ef1:	77 17                	ja     c0102f0a <page_init+0x225>
c0102ef3:	ff 75 a4             	pushl  -0x5c(%ebp)
c0102ef6:	68 c4 63 10 c0       	push   $0xc01063c4
c0102efb:	68 dc 00 00 00       	push   $0xdc
c0102f00:	68 e8 63 10 c0       	push   $0xc01063e8
c0102f05:	e8 d9 d4 ff ff       	call   c01003e3 <__panic>
c0102f0a:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0102f0d:	05 00 00 00 40       	add    $0x40000000,%eax
c0102f12:	89 45 a0             	mov    %eax,-0x60(%ebp)

    for (i = 0; i < memmap->nr_map; i ++) {
c0102f15:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0102f1c:	e9 69 01 00 00       	jmp    c010308a <page_init+0x3a5>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
c0102f21:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102f24:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102f27:	89 d0                	mov    %edx,%eax
c0102f29:	c1 e0 02             	shl    $0x2,%eax
c0102f2c:	01 d0                	add    %edx,%eax
c0102f2e:	c1 e0 02             	shl    $0x2,%eax
c0102f31:	01 c8                	add    %ecx,%eax
c0102f33:	8b 50 08             	mov    0x8(%eax),%edx
c0102f36:	8b 40 04             	mov    0x4(%eax),%eax
c0102f39:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0102f3c:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c0102f3f:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102f42:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102f45:	89 d0                	mov    %edx,%eax
c0102f47:	c1 e0 02             	shl    $0x2,%eax
c0102f4a:	01 d0                	add    %edx,%eax
c0102f4c:	c1 e0 02             	shl    $0x2,%eax
c0102f4f:	01 c8                	add    %ecx,%eax
c0102f51:	8b 48 0c             	mov    0xc(%eax),%ecx
c0102f54:	8b 58 10             	mov    0x10(%eax),%ebx
c0102f57:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0102f5a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0102f5d:	01 c8                	add    %ecx,%eax
c0102f5f:	11 da                	adc    %ebx,%edx
c0102f61:	89 45 c8             	mov    %eax,-0x38(%ebp)
c0102f64:	89 55 cc             	mov    %edx,-0x34(%ebp)
        if (memmap->map[i].type == E820_ARM) {
c0102f67:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0102f6a:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0102f6d:	89 d0                	mov    %edx,%eax
c0102f6f:	c1 e0 02             	shl    $0x2,%eax
c0102f72:	01 d0                	add    %edx,%eax
c0102f74:	c1 e0 02             	shl    $0x2,%eax
c0102f77:	01 c8                	add    %ecx,%eax
c0102f79:	83 c0 14             	add    $0x14,%eax
c0102f7c:	8b 00                	mov    (%eax),%eax
c0102f7e:	83 f8 01             	cmp    $0x1,%eax
c0102f81:	0f 85 ff 00 00 00    	jne    c0103086 <page_init+0x3a1>
            if (begin < freemem) {
c0102f87:	8b 45 a0             	mov    -0x60(%ebp),%eax
c0102f8a:	ba 00 00 00 00       	mov    $0x0,%edx
c0102f8f:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0102f92:	72 17                	jb     c0102fab <page_init+0x2c6>
c0102f94:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0102f97:	77 05                	ja     c0102f9e <page_init+0x2b9>
c0102f99:	3b 45 d0             	cmp    -0x30(%ebp),%eax
c0102f9c:	76 0d                	jbe    c0102fab <page_init+0x2c6>
                begin = freemem;
c0102f9e:	8b 45 a0             	mov    -0x60(%ebp),%eax
c0102fa1:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0102fa4:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
            }
            if (end > KMEMSIZE) {
c0102fab:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
c0102faf:	72 1d                	jb     c0102fce <page_init+0x2e9>
c0102fb1:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
c0102fb5:	77 09                	ja     c0102fc0 <page_init+0x2db>
c0102fb7:	81 7d c8 00 00 00 38 	cmpl   $0x38000000,-0x38(%ebp)
c0102fbe:	76 0e                	jbe    c0102fce <page_init+0x2e9>
                end = KMEMSIZE;
c0102fc0:	c7 45 c8 00 00 00 38 	movl   $0x38000000,-0x38(%ebp)
c0102fc7:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
            }
            if (begin < end) {
c0102fce:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0102fd1:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0102fd4:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0102fd7:	0f 87 a9 00 00 00    	ja     c0103086 <page_init+0x3a1>
c0102fdd:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0102fe0:	72 09                	jb     c0102feb <page_init+0x306>
c0102fe2:	3b 45 c8             	cmp    -0x38(%ebp),%eax
c0102fe5:	0f 83 9b 00 00 00    	jae    c0103086 <page_init+0x3a1>
                begin = ROUNDUP(begin, PGSIZE);
c0102feb:	c7 45 9c 00 10 00 00 	movl   $0x1000,-0x64(%ebp)
c0102ff2:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0102ff5:	8b 45 9c             	mov    -0x64(%ebp),%eax
c0102ff8:	01 d0                	add    %edx,%eax
c0102ffa:	83 e8 01             	sub    $0x1,%eax
c0102ffd:	89 45 98             	mov    %eax,-0x68(%ebp)
c0103000:	8b 45 98             	mov    -0x68(%ebp),%eax
c0103003:	ba 00 00 00 00       	mov    $0x0,%edx
c0103008:	f7 75 9c             	divl   -0x64(%ebp)
c010300b:	8b 45 98             	mov    -0x68(%ebp),%eax
c010300e:	29 d0                	sub    %edx,%eax
c0103010:	ba 00 00 00 00       	mov    $0x0,%edx
c0103015:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0103018:	89 55 d4             	mov    %edx,-0x2c(%ebp)
                end = ROUNDDOWN(end, PGSIZE);
c010301b:	8b 45 c8             	mov    -0x38(%ebp),%eax
c010301e:	89 45 94             	mov    %eax,-0x6c(%ebp)
c0103021:	8b 45 94             	mov    -0x6c(%ebp),%eax
c0103024:	ba 00 00 00 00       	mov    $0x0,%edx
c0103029:	89 c3                	mov    %eax,%ebx
c010302b:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
c0103031:	89 de                	mov    %ebx,%esi
c0103033:	89 d0                	mov    %edx,%eax
c0103035:	83 e0 00             	and    $0x0,%eax
c0103038:	89 c7                	mov    %eax,%edi
c010303a:	89 75 c8             	mov    %esi,-0x38(%ebp)
c010303d:	89 7d cc             	mov    %edi,-0x34(%ebp)
                if (begin < end) {
c0103040:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0103043:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0103046:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0103049:	77 3b                	ja     c0103086 <page_init+0x3a1>
c010304b:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c010304e:	72 05                	jb     c0103055 <page_init+0x370>
c0103050:	3b 45 c8             	cmp    -0x38(%ebp),%eax
c0103053:	73 31                	jae    c0103086 <page_init+0x3a1>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);//空闲页表初始化
c0103055:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0103058:	8b 55 cc             	mov    -0x34(%ebp),%edx
c010305b:	2b 45 d0             	sub    -0x30(%ebp),%eax
c010305e:	1b 55 d4             	sbb    -0x2c(%ebp),%edx
c0103061:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
c0103065:	c1 ea 0c             	shr    $0xc,%edx
c0103068:	89 c3                	mov    %eax,%ebx
c010306a:	8b 45 d0             	mov    -0x30(%ebp),%eax
c010306d:	83 ec 0c             	sub    $0xc,%esp
c0103070:	50                   	push   %eax
c0103071:	e8 de f8 ff ff       	call   c0102954 <pa2page>
c0103076:	83 c4 10             	add    $0x10,%esp
c0103079:	83 ec 08             	sub    $0x8,%esp
c010307c:	53                   	push   %ebx
c010307d:	50                   	push   %eax
c010307e:	e8 a2 fb ff ff       	call   c0102c25 <init_memmap>
c0103083:	83 c4 10             	add    $0x10,%esp
        SetPageReserved(pages + i);
    }//暂时都设置为保留

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);//实地址，空闲表

    for (i = 0; i < memmap->nr_map; i ++) {
c0103086:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
c010308a:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c010308d:	8b 00                	mov    (%eax),%eax
c010308f:	3b 45 dc             	cmp    -0x24(%ebp),%eax
c0103092:	0f 8f 89 fe ff ff    	jg     c0102f21 <page_init+0x23c>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);//空闲页表初始化
                }
            }
        }
    }
}
c0103098:	90                   	nop
c0103099:	8d 65 f4             	lea    -0xc(%ebp),%esp
c010309c:	5b                   	pop    %ebx
c010309d:	5e                   	pop    %esi
c010309e:	5f                   	pop    %edi
c010309f:	5d                   	pop    %ebp
c01030a0:	c3                   	ret    

c01030a1 <boot_map_segment>:
//  la:   linear address of this memory need to map (after x86 segment map)
//  size: memory size
//  pa:   physical address of this memory
//  perm: permission of this memory  
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
c01030a1:	55                   	push   %ebp
c01030a2:	89 e5                	mov    %esp,%ebp
c01030a4:	83 ec 28             	sub    $0x28,%esp
    assert(PGOFF(la) == PGOFF(pa));
c01030a7:	8b 45 0c             	mov    0xc(%ebp),%eax
c01030aa:	33 45 14             	xor    0x14(%ebp),%eax
c01030ad:	25 ff 0f 00 00       	and    $0xfff,%eax
c01030b2:	85 c0                	test   %eax,%eax
c01030b4:	74 19                	je     c01030cf <boot_map_segment+0x2e>
c01030b6:	68 f6 63 10 c0       	push   $0xc01063f6
c01030bb:	68 0d 64 10 c0       	push   $0xc010640d
c01030c0:	68 fa 00 00 00       	push   $0xfa
c01030c5:	68 e8 63 10 c0       	push   $0xc01063e8
c01030ca:	e8 14 d3 ff ff       	call   c01003e3 <__panic>
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
c01030cf:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
c01030d6:	8b 45 0c             	mov    0xc(%ebp),%eax
c01030d9:	25 ff 0f 00 00       	and    $0xfff,%eax
c01030de:	89 c2                	mov    %eax,%edx
c01030e0:	8b 45 10             	mov    0x10(%ebp),%eax
c01030e3:	01 c2                	add    %eax,%edx
c01030e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01030e8:	01 d0                	add    %edx,%eax
c01030ea:	83 e8 01             	sub    $0x1,%eax
c01030ed:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01030f0:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01030f3:	ba 00 00 00 00       	mov    $0x0,%edx
c01030f8:	f7 75 f0             	divl   -0x10(%ebp)
c01030fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01030fe:	29 d0                	sub    %edx,%eax
c0103100:	c1 e8 0c             	shr    $0xc,%eax
c0103103:	89 45 f4             	mov    %eax,-0xc(%ebp)
    la = ROUNDDOWN(la, PGSIZE);
c0103106:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103109:	89 45 e8             	mov    %eax,-0x18(%ebp)
c010310c:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010310f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103114:	89 45 0c             	mov    %eax,0xc(%ebp)
    pa = ROUNDDOWN(pa, PGSIZE);
c0103117:	8b 45 14             	mov    0x14(%ebp),%eax
c010311a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c010311d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103120:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103125:	89 45 14             	mov    %eax,0x14(%ebp)
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
c0103128:	eb 57                	jmp    c0103181 <boot_map_segment+0xe0>
        pte_t *ptep = get_pte(pgdir, la, 1);
c010312a:	83 ec 04             	sub    $0x4,%esp
c010312d:	6a 01                	push   $0x1
c010312f:	ff 75 0c             	pushl  0xc(%ebp)
c0103132:	ff 75 08             	pushl  0x8(%ebp)
c0103135:	e8 53 01 00 00       	call   c010328d <get_pte>
c010313a:	83 c4 10             	add    $0x10,%esp
c010313d:	89 45 e0             	mov    %eax,-0x20(%ebp)
        assert(ptep != NULL);
c0103140:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
c0103144:	75 19                	jne    c010315f <boot_map_segment+0xbe>
c0103146:	68 22 64 10 c0       	push   $0xc0106422
c010314b:	68 0d 64 10 c0       	push   $0xc010640d
c0103150:	68 00 01 00 00       	push   $0x100
c0103155:	68 e8 63 10 c0       	push   $0xc01063e8
c010315a:	e8 84 d2 ff ff       	call   c01003e3 <__panic>
        *ptep = pa | PTE_P | perm;
c010315f:	8b 45 14             	mov    0x14(%ebp),%eax
c0103162:	0b 45 18             	or     0x18(%ebp),%eax
c0103165:	83 c8 01             	or     $0x1,%eax
c0103168:	89 c2                	mov    %eax,%edx
c010316a:	8b 45 e0             	mov    -0x20(%ebp),%eax
c010316d:	89 10                	mov    %edx,(%eax)
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {
    assert(PGOFF(la) == PGOFF(pa));
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
c010316f:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
c0103173:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
c010317a:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
c0103181:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0103185:	75 a3                	jne    c010312a <boot_map_segment+0x89>
        pte_t *ptep = get_pte(pgdir, la, 1);
        assert(ptep != NULL);
        *ptep = pa | PTE_P | perm;
    }
}
c0103187:	90                   	nop
c0103188:	c9                   	leave  
c0103189:	c3                   	ret    

c010318a <boot_alloc_page>:

//boot_alloc_page - allocate one page using pmm->alloc_pages(1) 
// return value: the kernel virtual address of this allocated page
//note: this function is used to get the memory for PDT(Page Directory Table)&PT(Page Table)
static void *
boot_alloc_page(void) {
c010318a:	55                   	push   %ebp
c010318b:	89 e5                	mov    %esp,%ebp
c010318d:	83 ec 18             	sub    $0x18,%esp
    struct Page *p = alloc_page();
c0103190:	83 ec 0c             	sub    $0xc,%esp
c0103193:	6a 01                	push   $0x1
c0103195:	e8 aa fa ff ff       	call   c0102c44 <alloc_pages>
c010319a:	83 c4 10             	add    $0x10,%esp
c010319d:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (p == NULL) {
c01031a0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01031a4:	75 17                	jne    c01031bd <boot_alloc_page+0x33>
        panic("boot_alloc_page failed.\n");
c01031a6:	83 ec 04             	sub    $0x4,%esp
c01031a9:	68 2f 64 10 c0       	push   $0xc010642f
c01031ae:	68 0c 01 00 00       	push   $0x10c
c01031b3:	68 e8 63 10 c0       	push   $0xc01063e8
c01031b8:	e8 26 d2 ff ff       	call   c01003e3 <__panic>
    }
    return page2kva(p);
c01031bd:	83 ec 0c             	sub    $0xc,%esp
c01031c0:	ff 75 f4             	pushl  -0xc(%ebp)
c01031c3:	e8 d3 f7 ff ff       	call   c010299b <page2kva>
c01031c8:	83 c4 10             	add    $0x10,%esp
}
c01031cb:	c9                   	leave  
c01031cc:	c3                   	ret    

c01031cd <pmm_init>:

//pmm_init - setup a pmm to manage physical memory, build PDT&PT to setup paging mechanism 
//         - check the correctness of pmm & paging mechanism, print PDT&PT
void
pmm_init(void) {
c01031cd:	55                   	push   %ebp
c01031ce:	89 e5                	mov    %esp,%ebp
c01031d0:	83 ec 18             	sub    $0x18,%esp
    // We've already enabled paging
    boot_cr3 = PADDR(boot_pgdir);
c01031d3:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01031d8:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01031db:	81 7d f4 ff ff ff bf 	cmpl   $0xbfffffff,-0xc(%ebp)
c01031e2:	77 17                	ja     c01031fb <pmm_init+0x2e>
c01031e4:	ff 75 f4             	pushl  -0xc(%ebp)
c01031e7:	68 c4 63 10 c0       	push   $0xc01063c4
c01031ec:	68 16 01 00 00       	push   $0x116
c01031f1:	68 e8 63 10 c0       	push   $0xc01063e8
c01031f6:	e8 e8 d1 ff ff       	call   c01003e3 <__panic>
c01031fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01031fe:	05 00 00 00 40       	add    $0x40000000,%eax
c0103203:	a3 14 af 11 c0       	mov    %eax,0xc011af14
    //We need to alloc/free the physical memory (granularity is 4KB or other size). 
    //So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    //First we should init a physical memory manager(pmm) based on the framework.
    //Then pmm can alloc/free the physical memory. 
    //Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();
c0103208:	e8 e3 f9 ff ff       	call   c0102bf0 <init_pmm_manager>

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();
c010320d:	e8 d3 fa ff ff       	call   c0102ce5 <page_init>

    //use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();
c0103212:	e8 90 03 00 00       	call   c01035a7 <check_alloc_page>

    check_pgdir();
c0103217:	e8 ae 03 00 00       	call   c01035ca <check_pgdir>

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // recursively insert boot_pgdir in itself
    // to form a virtual page table at virtual address VPT
    boot_pgdir[PDX(VPT)] = PADDR(boot_pgdir) | PTE_P | PTE_W;
c010321c:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103221:	8d 90 ac 0f 00 00    	lea    0xfac(%eax),%edx
c0103227:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010322c:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010322f:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
c0103236:	77 17                	ja     c010324f <pmm_init+0x82>
c0103238:	ff 75 f0             	pushl  -0x10(%ebp)
c010323b:	68 c4 63 10 c0       	push   $0xc01063c4
c0103240:	68 2c 01 00 00       	push   $0x12c
c0103245:	68 e8 63 10 c0       	push   $0xc01063e8
c010324a:	e8 94 d1 ff ff       	call   c01003e3 <__panic>
c010324f:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103252:	05 00 00 00 40       	add    $0x40000000,%eax
c0103257:	83 c8 03             	or     $0x3,%eax
c010325a:	89 02                	mov    %eax,(%edx)

    // map all physical memory to linear memory with base linear addr KERNBASE
    // linear_addr KERNBASE ~ KERNBASE + KMEMSIZE = phy_addr 0 ~ KMEMSIZE
    boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, 0, PTE_W);
c010325c:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103261:	83 ec 0c             	sub    $0xc,%esp
c0103264:	6a 02                	push   $0x2
c0103266:	6a 00                	push   $0x0
c0103268:	68 00 00 00 38       	push   $0x38000000
c010326d:	68 00 00 00 c0       	push   $0xc0000000
c0103272:	50                   	push   %eax
c0103273:	e8 29 fe ff ff       	call   c01030a1 <boot_map_segment>
c0103278:	83 c4 20             	add    $0x20,%esp

    // Since we are using bootloader's GDT,
    // we should reload gdt (second time, the last time) to get user segments and the TSS
    // map virtual_addr 0 ~ 4G = linear_addr 0 ~ 4G
    // then set kernel stack (ss:esp) in TSS, setup TSS in gdt, load TSS
    gdt_init();
c010327b:	e8 7e f8 ff ff       	call   c0102afe <gdt_init>

    //now the basic virtual memory map(see memalyout.h) is established.
    //check the correctness of the basic virtual memory map.
    check_boot_pgdir();
c0103280:	e8 ab 08 00 00       	call   c0103b30 <check_boot_pgdir>

    print_pgdir();
c0103285:	e8 a1 0c 00 00       	call   c0103f2b <print_pgdir>

}
c010328a:	90                   	nop
c010328b:	c9                   	leave  
c010328c:	c3                   	ret    

c010328d <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *
get_pte(pde_t *pgdir, uintptr_t la, bool create) {
c010328d:	55                   	push   %ebp
c010328e:	89 e5                	mov    %esp,%ebp
c0103290:	83 ec 28             	sub    $0x28,%esp
    return NULL;          // (8) return page table entry
#endif

	 // PDX(la) 根据la的高10位获得对应的页目录项(一级页表中的某一项)索引(页目录项)
    // &pgdir[PDX(la)] 根据一级页表项索引从一级页表中找到对应的页目录项指针
    pde_t *pdep = &pgdir[PDX(la)];
c0103293:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103296:	c1 e8 16             	shr    $0x16,%eax
c0103299:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c01032a0:	8b 45 08             	mov    0x8(%ebp),%eax
c01032a3:	01 d0                	add    %edx,%eax
c01032a5:	89 45 f4             	mov    %eax,-0xc(%ebp)
    // 判断当前页目录项的Present存在位是否为1(对应的二级页表是否存在)
    if (!(*pdep & PTE_P)) {
c01032a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01032ab:	8b 00                	mov    (%eax),%eax
c01032ad:	83 e0 01             	and    $0x1,%eax
c01032b0:	85 c0                	test   %eax,%eax
c01032b2:	0f 85 9f 00 00 00    	jne    c0103357 <get_pte+0xca>
        // 对应的二级页表不存在
        // *page指向的是这个新创建的二级页表基地址
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
c01032b8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01032bc:	74 16                	je     c01032d4 <get_pte+0x47>
c01032be:	83 ec 0c             	sub    $0xc,%esp
c01032c1:	6a 01                	push   $0x1
c01032c3:	e8 7c f9 ff ff       	call   c0102c44 <alloc_pages>
c01032c8:	83 c4 10             	add    $0x10,%esp
c01032cb:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01032ce:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c01032d2:	75 0a                	jne    c01032de <get_pte+0x51>
             // 如果create参数为false或是alloc_page分配物理内存失败
            return NULL;
c01032d4:	b8 00 00 00 00       	mov    $0x0,%eax
c01032d9:	e9 ca 00 00 00       	jmp    c01033a8 <get_pte+0x11b>
        }
        // 二级页表所对应的物理页 引用数为1
        set_page_ref(page, 1);
c01032de:	83 ec 08             	sub    $0x8,%esp
c01032e1:	6a 01                	push   $0x1
c01032e3:	ff 75 f0             	pushl  -0x10(%ebp)
c01032e6:	e8 55 f7 ff ff       	call   c0102a40 <set_page_ref>
c01032eb:	83 c4 10             	add    $0x10,%esp
        // 获得page变量的物理地址
        uintptr_t pa = page2pa(page);
c01032ee:	83 ec 0c             	sub    $0xc,%esp
c01032f1:	ff 75 f0             	pushl  -0x10(%ebp)
c01032f4:	e8 48 f6 ff ff       	call   c0102941 <page2pa>
c01032f9:	83 c4 10             	add    $0x10,%esp
c01032fc:	89 45 ec             	mov    %eax,-0x14(%ebp)
        // 将整个page所在的物理页格式胡，全部填满0
        memset(KADDR(pa), 0, PGSIZE);
c01032ff:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103302:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0103305:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103308:	c1 e8 0c             	shr    $0xc,%eax
c010330b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c010330e:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0103313:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
c0103316:	72 17                	jb     c010332f <get_pte+0xa2>
c0103318:	ff 75 e8             	pushl  -0x18(%ebp)
c010331b:	68 20 63 10 c0       	push   $0xc0106320
c0103320:	68 7c 01 00 00       	push   $0x17c
c0103325:	68 e8 63 10 c0       	push   $0xc01063e8
c010332a:	e8 b4 d0 ff ff       	call   c01003e3 <__panic>
c010332f:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103332:	2d 00 00 00 40       	sub    $0x40000000,%eax
c0103337:	83 ec 04             	sub    $0x4,%esp
c010333a:	68 00 10 00 00       	push   $0x1000
c010333f:	6a 00                	push   $0x0
c0103341:	50                   	push   %eax
c0103342:	e8 b7 20 00 00       	call   c01053fe <memset>
c0103347:	83 c4 10             	add    $0x10,%esp
        // la对应的一级页目录项进行赋值，使其指向新创建的二级页表(页表中的数据被MMU直接处理，为了映射效率存放的都是物理地址)
        // 或PTE_U/PTE_W/PET_P 标识当前页目录项是用户级别的、可写的、已存在的
        *pdep = pa | PTE_U | PTE_W | PTE_P;
c010334a:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010334d:	83 c8 07             	or     $0x7,%eax
c0103350:	89 c2                	mov    %eax,%edx
c0103352:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103355:	89 10                	mov    %edx,(%eax)
    }

    // 要想通过C语言中的数组来访问对应数据，需要的是数组基址(虚拟地址),而*pdep中页目录表项中存放了对应二级页表的一个物理地址
    // PDE_ADDR将*pdep的低12位抹零对齐(指向二级页表的起始基地址)，再通过KADDR转为内核虚拟地址，进行数组访问
    // PTX(la)获得la线性地址的中间10位部分，即二级页表中对应页表项的索引下标。这样便能得到la对应的二级页表项了
    return &((pte_t *)KADDR(PDE_ADDR(*pdep)))[PTX(la)];
c0103357:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010335a:	8b 00                	mov    (%eax),%eax
c010335c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103361:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0103364:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103367:	c1 e8 0c             	shr    $0xc,%eax
c010336a:	89 45 dc             	mov    %eax,-0x24(%ebp)
c010336d:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0103372:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c0103375:	72 17                	jb     c010338e <get_pte+0x101>
c0103377:	ff 75 e0             	pushl  -0x20(%ebp)
c010337a:	68 20 63 10 c0       	push   $0xc0106320
c010337f:	68 85 01 00 00       	push   $0x185
c0103384:	68 e8 63 10 c0       	push   $0xc01063e8
c0103389:	e8 55 d0 ff ff       	call   c01003e3 <__panic>
c010338e:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103391:	2d 00 00 00 40       	sub    $0x40000000,%eax
c0103396:	89 c2                	mov    %eax,%edx
c0103398:	8b 45 0c             	mov    0xc(%ebp),%eax
c010339b:	c1 e8 0c             	shr    $0xc,%eax
c010339e:	25 ff 03 00 00       	and    $0x3ff,%eax
c01033a3:	c1 e0 02             	shl    $0x2,%eax
c01033a6:	01 d0                	add    %edx,%eax
}
c01033a8:	c9                   	leave  
c01033a9:	c3                   	ret    

c01033aa <get_page>:

//get_page - get related Page struct for linear address la using PDT pgdir
struct Page *
get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
c01033aa:	55                   	push   %ebp
c01033ab:	89 e5                	mov    %esp,%ebp
c01033ad:	83 ec 18             	sub    $0x18,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
c01033b0:	83 ec 04             	sub    $0x4,%esp
c01033b3:	6a 00                	push   $0x0
c01033b5:	ff 75 0c             	pushl  0xc(%ebp)
c01033b8:	ff 75 08             	pushl  0x8(%ebp)
c01033bb:	e8 cd fe ff ff       	call   c010328d <get_pte>
c01033c0:	83 c4 10             	add    $0x10,%esp
c01033c3:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep_store != NULL) {
c01033c6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01033ca:	74 08                	je     c01033d4 <get_page+0x2a>
        *ptep_store = ptep;
c01033cc:	8b 45 10             	mov    0x10(%ebp),%eax
c01033cf:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01033d2:	89 10                	mov    %edx,(%eax)
    }
    if (ptep != NULL && *ptep & PTE_P) {
c01033d4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01033d8:	74 1f                	je     c01033f9 <get_page+0x4f>
c01033da:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01033dd:	8b 00                	mov    (%eax),%eax
c01033df:	83 e0 01             	and    $0x1,%eax
c01033e2:	85 c0                	test   %eax,%eax
c01033e4:	74 13                	je     c01033f9 <get_page+0x4f>
        return pte2page(*ptep);
c01033e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01033e9:	8b 00                	mov    (%eax),%eax
c01033eb:	83 ec 0c             	sub    $0xc,%esp
c01033ee:	50                   	push   %eax
c01033ef:	e8 ec f5 ff ff       	call   c01029e0 <pte2page>
c01033f4:	83 c4 10             	add    $0x10,%esp
c01033f7:	eb 05                	jmp    c01033fe <get_page+0x54>
    }
    return NULL;
c01033f9:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01033fe:	c9                   	leave  
c01033ff:	c3                   	ret    

c0103400 <page_remove_pte>:

//page_remove_pte - free an Page sturct which is related linear address la
//                - and clean(invalidate) pte which is related linear address la
//note: PT is changed, so the TLB need to be invalidate 
static inline void
page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
c0103400:	55                   	push   %ebp
c0103401:	89 e5                	mov    %esp,%ebp
c0103403:	83 ec 18             	sub    $0x18,%esp
                                  //(5) clear second page table entry
                                  //(6) flush tlb
    }
	
#endif
	if (*ptep & PTE_P) {
c0103406:	8b 45 10             	mov    0x10(%ebp),%eax
c0103409:	8b 00                	mov    (%eax),%eax
c010340b:	83 e0 01             	and    $0x1,%eax
c010340e:	85 c0                	test   %eax,%eax
c0103410:	74 50                	je     c0103462 <page_remove_pte+0x62>
        // 如果对应的二级页表项存在
        // 获得*ptep对应的Page结构
        struct Page *page = pte2page(*ptep);
c0103412:	8b 45 10             	mov    0x10(%ebp),%eax
c0103415:	8b 00                	mov    (%eax),%eax
c0103417:	83 ec 0c             	sub    $0xc,%esp
c010341a:	50                   	push   %eax
c010341b:	e8 c0 f5 ff ff       	call   c01029e0 <pte2page>
c0103420:	83 c4 10             	add    $0x10,%esp
c0103423:	89 45 f4             	mov    %eax,-0xc(%ebp)
        // 关联的page引用数自减1
        if (page_ref_dec(page) == 0) {
c0103426:	83 ec 0c             	sub    $0xc,%esp
c0103429:	ff 75 f4             	pushl  -0xc(%ebp)
c010342c:	e8 34 f6 ff ff       	call   c0102a65 <page_ref_dec>
c0103431:	83 c4 10             	add    $0x10,%esp
c0103434:	85 c0                	test   %eax,%eax
c0103436:	75 10                	jne    c0103448 <page_remove_pte+0x48>
            // 如果自减1后，引用数为0，需要free释放掉该物理页
            free_page(page);
c0103438:	83 ec 08             	sub    $0x8,%esp
c010343b:	6a 01                	push   $0x1
c010343d:	ff 75 f4             	pushl  -0xc(%ebp)
c0103440:	e8 3d f8 ff ff       	call   c0102c82 <free_pages>
c0103445:	83 c4 10             	add    $0x10,%esp
        }
        // 清空当前二级页表项(整体设置为0)
        *ptep = 0;
c0103448:	8b 45 10             	mov    0x10(%ebp),%eax
c010344b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        // 由于页表项发生了改变，需要TLB快表
        tlb_invalidate(pgdir, la);
c0103451:	83 ec 08             	sub    $0x8,%esp
c0103454:	ff 75 0c             	pushl  0xc(%ebp)
c0103457:	ff 75 08             	pushl  0x8(%ebp)
c010345a:	e8 f8 00 00 00       	call   c0103557 <tlb_invalidate>
c010345f:	83 c4 10             	add    $0x10,%esp
    }
}
c0103462:	90                   	nop
c0103463:	c9                   	leave  
c0103464:	c3                   	ret    

c0103465 <page_remove>:

//page_remove - free an Page which is related linear address la and has an validated pte
void
page_remove(pde_t *pgdir, uintptr_t la) {
c0103465:	55                   	push   %ebp
c0103466:	89 e5                	mov    %esp,%ebp
c0103468:	83 ec 18             	sub    $0x18,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);
c010346b:	83 ec 04             	sub    $0x4,%esp
c010346e:	6a 00                	push   $0x0
c0103470:	ff 75 0c             	pushl  0xc(%ebp)
c0103473:	ff 75 08             	pushl  0x8(%ebp)
c0103476:	e8 12 fe ff ff       	call   c010328d <get_pte>
c010347b:	83 c4 10             	add    $0x10,%esp
c010347e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep != NULL) {
c0103481:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0103485:	74 14                	je     c010349b <page_remove+0x36>
        page_remove_pte(pgdir, la, ptep);//刷新指定页的TLB
c0103487:	83 ec 04             	sub    $0x4,%esp
c010348a:	ff 75 f4             	pushl  -0xc(%ebp)
c010348d:	ff 75 0c             	pushl  0xc(%ebp)
c0103490:	ff 75 08             	pushl  0x8(%ebp)
c0103493:	e8 68 ff ff ff       	call   c0103400 <page_remove_pte>
c0103498:	83 c4 10             	add    $0x10,%esp
    }
}
c010349b:	90                   	nop
c010349c:	c9                   	leave  
c010349d:	c3                   	ret    

c010349e <page_insert>:
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
//note: PT is changed, so the TLB need to be invalidate 
int
page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
c010349e:	55                   	push   %ebp
c010349f:	89 e5                	mov    %esp,%ebp
c01034a1:	83 ec 18             	sub    $0x18,%esp
    pte_t *ptep = get_pte(pgdir, la, 1);
c01034a4:	83 ec 04             	sub    $0x4,%esp
c01034a7:	6a 01                	push   $0x1
c01034a9:	ff 75 10             	pushl  0x10(%ebp)
c01034ac:	ff 75 08             	pushl  0x8(%ebp)
c01034af:	e8 d9 fd ff ff       	call   c010328d <get_pte>
c01034b4:	83 c4 10             	add    $0x10,%esp
c01034b7:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep == NULL) {
c01034ba:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01034be:	75 0a                	jne    c01034ca <page_insert+0x2c>
        return -E_NO_MEM;
c01034c0:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
c01034c5:	e9 8b 00 00 00       	jmp    c0103555 <page_insert+0xb7>
    }
    page_ref_inc(page);
c01034ca:	83 ec 0c             	sub    $0xc,%esp
c01034cd:	ff 75 0c             	pushl  0xc(%ebp)
c01034d0:	e8 79 f5 ff ff       	call   c0102a4e <page_ref_inc>
c01034d5:	83 c4 10             	add    $0x10,%esp
    if (*ptep & PTE_P) {
c01034d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01034db:	8b 00                	mov    (%eax),%eax
c01034dd:	83 e0 01             	and    $0x1,%eax
c01034e0:	85 c0                	test   %eax,%eax
c01034e2:	74 40                	je     c0103524 <page_insert+0x86>
        struct Page *p = pte2page(*ptep);
c01034e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01034e7:	8b 00                	mov    (%eax),%eax
c01034e9:	83 ec 0c             	sub    $0xc,%esp
c01034ec:	50                   	push   %eax
c01034ed:	e8 ee f4 ff ff       	call   c01029e0 <pte2page>
c01034f2:	83 c4 10             	add    $0x10,%esp
c01034f5:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (p == page) {
c01034f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01034fb:	3b 45 0c             	cmp    0xc(%ebp),%eax
c01034fe:	75 10                	jne    c0103510 <page_insert+0x72>
            page_ref_dec(page);
c0103500:	83 ec 0c             	sub    $0xc,%esp
c0103503:	ff 75 0c             	pushl  0xc(%ebp)
c0103506:	e8 5a f5 ff ff       	call   c0102a65 <page_ref_dec>
c010350b:	83 c4 10             	add    $0x10,%esp
c010350e:	eb 14                	jmp    c0103524 <page_insert+0x86>
        }
        else {
            page_remove_pte(pgdir, la, ptep);
c0103510:	83 ec 04             	sub    $0x4,%esp
c0103513:	ff 75 f4             	pushl  -0xc(%ebp)
c0103516:	ff 75 10             	pushl  0x10(%ebp)
c0103519:	ff 75 08             	pushl  0x8(%ebp)
c010351c:	e8 df fe ff ff       	call   c0103400 <page_remove_pte>
c0103521:	83 c4 10             	add    $0x10,%esp
        }
    }
    *ptep = page2pa(page) | PTE_P | perm;
c0103524:	83 ec 0c             	sub    $0xc,%esp
c0103527:	ff 75 0c             	pushl  0xc(%ebp)
c010352a:	e8 12 f4 ff ff       	call   c0102941 <page2pa>
c010352f:	83 c4 10             	add    $0x10,%esp
c0103532:	0b 45 14             	or     0x14(%ebp),%eax
c0103535:	83 c8 01             	or     $0x1,%eax
c0103538:	89 c2                	mov    %eax,%edx
c010353a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010353d:	89 10                	mov    %edx,(%eax)
    tlb_invalidate(pgdir, la);
c010353f:	83 ec 08             	sub    $0x8,%esp
c0103542:	ff 75 10             	pushl  0x10(%ebp)
c0103545:	ff 75 08             	pushl  0x8(%ebp)
c0103548:	e8 0a 00 00 00       	call   c0103557 <tlb_invalidate>
c010354d:	83 c4 10             	add    $0x10,%esp
    return 0;
c0103550:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0103555:	c9                   	leave  
c0103556:	c3                   	ret    

c0103557 <tlb_invalidate>:

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void
tlb_invalidate(pde_t *pgdir, uintptr_t la) {
c0103557:	55                   	push   %ebp
c0103558:	89 e5                	mov    %esp,%ebp
c010355a:	83 ec 18             	sub    $0x18,%esp
}

static inline uintptr_t
rcr3(void) {
    uintptr_t cr3;
    asm volatile ("mov %%cr3, %0" : "=r" (cr3) :: "memory");
c010355d:	0f 20 d8             	mov    %cr3,%eax
c0103560:	89 45 ec             	mov    %eax,-0x14(%ebp)
    return cr3;
c0103563:	8b 55 ec             	mov    -0x14(%ebp),%edx
    if (rcr3() == PADDR(pgdir)) {
c0103566:	8b 45 08             	mov    0x8(%ebp),%eax
c0103569:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010356c:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
c0103573:	77 17                	ja     c010358c <tlb_invalidate+0x35>
c0103575:	ff 75 f0             	pushl  -0x10(%ebp)
c0103578:	68 c4 63 10 c0       	push   $0xc01063c4
c010357d:	68 ee 01 00 00       	push   $0x1ee
c0103582:	68 e8 63 10 c0       	push   $0xc01063e8
c0103587:	e8 57 ce ff ff       	call   c01003e3 <__panic>
c010358c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010358f:	05 00 00 00 40       	add    $0x40000000,%eax
c0103594:	39 c2                	cmp    %eax,%edx
c0103596:	75 0c                	jne    c01035a4 <tlb_invalidate+0x4d>
        invlpg((void *)la);
c0103598:	8b 45 0c             	mov    0xc(%ebp),%eax
c010359b:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static inline void
invlpg(void *addr) {
    asm volatile ("invlpg (%0)" :: "r" (addr) : "memory");
c010359e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01035a1:	0f 01 38             	invlpg (%eax)
    }
}
c01035a4:	90                   	nop
c01035a5:	c9                   	leave  
c01035a6:	c3                   	ret    

c01035a7 <check_alloc_page>:

static void
check_alloc_page(void) {
c01035a7:	55                   	push   %ebp
c01035a8:	89 e5                	mov    %esp,%ebp
c01035aa:	83 ec 08             	sub    $0x8,%esp
    pmm_manager->check();
c01035ad:	a1 10 af 11 c0       	mov    0xc011af10,%eax
c01035b2:	8b 40 18             	mov    0x18(%eax),%eax
c01035b5:	ff d0                	call   *%eax
    cprintf("check_alloc_page() succeeded!\n");
c01035b7:	83 ec 0c             	sub    $0xc,%esp
c01035ba:	68 48 64 10 c0       	push   $0xc0106448
c01035bf:	e8 b9 cc ff ff       	call   c010027d <cprintf>
c01035c4:	83 c4 10             	add    $0x10,%esp
}
c01035c7:	90                   	nop
c01035c8:	c9                   	leave  
c01035c9:	c3                   	ret    

c01035ca <check_pgdir>:

static void
check_pgdir(void) {
c01035ca:	55                   	push   %ebp
c01035cb:	89 e5                	mov    %esp,%ebp
c01035cd:	83 ec 28             	sub    $0x28,%esp
    assert(npage <= KMEMSIZE / PGSIZE);//总页数检查
c01035d0:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01035d5:	3d 00 80 03 00       	cmp    $0x38000,%eax
c01035da:	76 19                	jbe    c01035f5 <check_pgdir+0x2b>
c01035dc:	68 67 64 10 c0       	push   $0xc0106467
c01035e1:	68 0d 64 10 c0       	push   $0xc010640d
c01035e6:	68 fb 01 00 00       	push   $0x1fb
c01035eb:	68 e8 63 10 c0       	push   $0xc01063e8
c01035f0:	e8 ee cd ff ff       	call   c01003e3 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);//页目录的地址应该就是页首
c01035f5:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01035fa:	85 c0                	test   %eax,%eax
c01035fc:	74 0e                	je     c010360c <check_pgdir+0x42>
c01035fe:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103603:	25 ff 0f 00 00       	and    $0xfff,%eax
c0103608:	85 c0                	test   %eax,%eax
c010360a:	74 19                	je     c0103625 <check_pgdir+0x5b>
c010360c:	68 84 64 10 c0       	push   $0xc0106484
c0103611:	68 0d 64 10 c0       	push   $0xc010640d
c0103616:	68 fc 01 00 00       	push   $0x1fc
c010361b:	68 e8 63 10 c0       	push   $0xc01063e8
c0103620:	e8 be cd ff ff       	call   c01003e3 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
c0103625:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010362a:	83 ec 04             	sub    $0x4,%esp
c010362d:	6a 00                	push   $0x0
c010362f:	6a 00                	push   $0x0
c0103631:	50                   	push   %eax
c0103632:	e8 73 fd ff ff       	call   c01033aa <get_page>
c0103637:	83 c4 10             	add    $0x10,%esp
c010363a:	85 c0                	test   %eax,%eax
c010363c:	74 19                	je     c0103657 <check_pgdir+0x8d>
c010363e:	68 bc 64 10 c0       	push   $0xc01064bc
c0103643:	68 0d 64 10 c0       	push   $0xc010640d
c0103648:	68 fd 01 00 00       	push   $0x1fd
c010364d:	68 e8 63 10 c0       	push   $0xc01063e8
c0103652:	e8 8c cd ff ff       	call   c01003e3 <__panic>

    struct Page *p1, *p2;
    p1 = alloc_page();
c0103657:	83 ec 0c             	sub    $0xc,%esp
c010365a:	6a 01                	push   $0x1
c010365c:	e8 e3 f5 ff ff       	call   c0102c44 <alloc_pages>
c0103661:	83 c4 10             	add    $0x10,%esp
c0103664:	89 45 f4             	mov    %eax,-0xc(%ebp)
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
c0103667:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010366c:	6a 00                	push   $0x0
c010366e:	6a 00                	push   $0x0
c0103670:	ff 75 f4             	pushl  -0xc(%ebp)
c0103673:	50                   	push   %eax
c0103674:	e8 25 fe ff ff       	call   c010349e <page_insert>
c0103679:	83 c4 10             	add    $0x10,%esp
c010367c:	85 c0                	test   %eax,%eax
c010367e:	74 19                	je     c0103699 <check_pgdir+0xcf>
c0103680:	68 e4 64 10 c0       	push   $0xc01064e4
c0103685:	68 0d 64 10 c0       	push   $0xc010640d
c010368a:	68 01 02 00 00       	push   $0x201
c010368f:	68 e8 63 10 c0       	push   $0xc01063e8
c0103694:	e8 4a cd ff ff       	call   c01003e3 <__panic>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
c0103699:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c010369e:	83 ec 04             	sub    $0x4,%esp
c01036a1:	6a 00                	push   $0x0
c01036a3:	6a 00                	push   $0x0
c01036a5:	50                   	push   %eax
c01036a6:	e8 e2 fb ff ff       	call   c010328d <get_pte>
c01036ab:	83 c4 10             	add    $0x10,%esp
c01036ae:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01036b1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c01036b5:	75 19                	jne    c01036d0 <check_pgdir+0x106>
c01036b7:	68 10 65 10 c0       	push   $0xc0106510
c01036bc:	68 0d 64 10 c0       	push   $0xc010640d
c01036c1:	68 04 02 00 00       	push   $0x204
c01036c6:	68 e8 63 10 c0       	push   $0xc01063e8
c01036cb:	e8 13 cd ff ff       	call   c01003e3 <__panic>
    assert(pte2page(*ptep) == p1);
c01036d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01036d3:	8b 00                	mov    (%eax),%eax
c01036d5:	83 ec 0c             	sub    $0xc,%esp
c01036d8:	50                   	push   %eax
c01036d9:	e8 02 f3 ff ff       	call   c01029e0 <pte2page>
c01036de:	83 c4 10             	add    $0x10,%esp
c01036e1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01036e4:	74 19                	je     c01036ff <check_pgdir+0x135>
c01036e6:	68 3d 65 10 c0       	push   $0xc010653d
c01036eb:	68 0d 64 10 c0       	push   $0xc010640d
c01036f0:	68 05 02 00 00       	push   $0x205
c01036f5:	68 e8 63 10 c0       	push   $0xc01063e8
c01036fa:	e8 e4 cc ff ff       	call   c01003e3 <__panic>
    assert(page_ref(p1) == 1);
c01036ff:	83 ec 0c             	sub    $0xc,%esp
c0103702:	ff 75 f4             	pushl  -0xc(%ebp)
c0103705:	e8 2c f3 ff ff       	call   c0102a36 <page_ref>
c010370a:	83 c4 10             	add    $0x10,%esp
c010370d:	83 f8 01             	cmp    $0x1,%eax
c0103710:	74 19                	je     c010372b <check_pgdir+0x161>
c0103712:	68 53 65 10 c0       	push   $0xc0106553
c0103717:	68 0d 64 10 c0       	push   $0xc010640d
c010371c:	68 06 02 00 00       	push   $0x206
c0103721:	68 e8 63 10 c0       	push   $0xc01063e8
c0103726:	e8 b8 cc ff ff       	call   c01003e3 <__panic>

    ptep = &((pte_t *)KADDR(PDE_ADDR(boot_pgdir[0])))[1];
c010372b:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103730:	8b 00                	mov    (%eax),%eax
c0103732:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103737:	89 45 ec             	mov    %eax,-0x14(%ebp)
c010373a:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010373d:	c1 e8 0c             	shr    $0xc,%eax
c0103740:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0103743:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0103748:	39 45 e8             	cmp    %eax,-0x18(%ebp)
c010374b:	72 17                	jb     c0103764 <check_pgdir+0x19a>
c010374d:	ff 75 ec             	pushl  -0x14(%ebp)
c0103750:	68 20 63 10 c0       	push   $0xc0106320
c0103755:	68 08 02 00 00       	push   $0x208
c010375a:	68 e8 63 10 c0       	push   $0xc01063e8
c010375f:	e8 7f cc ff ff       	call   c01003e3 <__panic>
c0103764:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103767:	2d 00 00 00 40       	sub    $0x40000000,%eax
c010376c:	83 c0 04             	add    $0x4,%eax
c010376f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
c0103772:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103777:	83 ec 04             	sub    $0x4,%esp
c010377a:	6a 00                	push   $0x0
c010377c:	68 00 10 00 00       	push   $0x1000
c0103781:	50                   	push   %eax
c0103782:	e8 06 fb ff ff       	call   c010328d <get_pte>
c0103787:	83 c4 10             	add    $0x10,%esp
c010378a:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c010378d:	74 19                	je     c01037a8 <check_pgdir+0x1de>
c010378f:	68 68 65 10 c0       	push   $0xc0106568
c0103794:	68 0d 64 10 c0       	push   $0xc010640d
c0103799:	68 09 02 00 00       	push   $0x209
c010379e:	68 e8 63 10 c0       	push   $0xc01063e8
c01037a3:	e8 3b cc ff ff       	call   c01003e3 <__panic>

    p2 = alloc_page();
c01037a8:	83 ec 0c             	sub    $0xc,%esp
c01037ab:	6a 01                	push   $0x1
c01037ad:	e8 92 f4 ff ff       	call   c0102c44 <alloc_pages>
c01037b2:	83 c4 10             	add    $0x10,%esp
c01037b5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
c01037b8:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01037bd:	6a 06                	push   $0x6
c01037bf:	68 00 10 00 00       	push   $0x1000
c01037c4:	ff 75 e4             	pushl  -0x1c(%ebp)
c01037c7:	50                   	push   %eax
c01037c8:	e8 d1 fc ff ff       	call   c010349e <page_insert>
c01037cd:	83 c4 10             	add    $0x10,%esp
c01037d0:	85 c0                	test   %eax,%eax
c01037d2:	74 19                	je     c01037ed <check_pgdir+0x223>
c01037d4:	68 90 65 10 c0       	push   $0xc0106590
c01037d9:	68 0d 64 10 c0       	push   $0xc010640d
c01037de:	68 0c 02 00 00       	push   $0x20c
c01037e3:	68 e8 63 10 c0       	push   $0xc01063e8
c01037e8:	e8 f6 cb ff ff       	call   c01003e3 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
c01037ed:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01037f2:	83 ec 04             	sub    $0x4,%esp
c01037f5:	6a 00                	push   $0x0
c01037f7:	68 00 10 00 00       	push   $0x1000
c01037fc:	50                   	push   %eax
c01037fd:	e8 8b fa ff ff       	call   c010328d <get_pte>
c0103802:	83 c4 10             	add    $0x10,%esp
c0103805:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103808:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c010380c:	75 19                	jne    c0103827 <check_pgdir+0x25d>
c010380e:	68 c8 65 10 c0       	push   $0xc01065c8
c0103813:	68 0d 64 10 c0       	push   $0xc010640d
c0103818:	68 0d 02 00 00       	push   $0x20d
c010381d:	68 e8 63 10 c0       	push   $0xc01063e8
c0103822:	e8 bc cb ff ff       	call   c01003e3 <__panic>
    assert(*ptep & PTE_U);
c0103827:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010382a:	8b 00                	mov    (%eax),%eax
c010382c:	83 e0 04             	and    $0x4,%eax
c010382f:	85 c0                	test   %eax,%eax
c0103831:	75 19                	jne    c010384c <check_pgdir+0x282>
c0103833:	68 f8 65 10 c0       	push   $0xc01065f8
c0103838:	68 0d 64 10 c0       	push   $0xc010640d
c010383d:	68 0e 02 00 00       	push   $0x20e
c0103842:	68 e8 63 10 c0       	push   $0xc01063e8
c0103847:	e8 97 cb ff ff       	call   c01003e3 <__panic>
    assert(*ptep & PTE_W);
c010384c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010384f:	8b 00                	mov    (%eax),%eax
c0103851:	83 e0 02             	and    $0x2,%eax
c0103854:	85 c0                	test   %eax,%eax
c0103856:	75 19                	jne    c0103871 <check_pgdir+0x2a7>
c0103858:	68 06 66 10 c0       	push   $0xc0106606
c010385d:	68 0d 64 10 c0       	push   $0xc010640d
c0103862:	68 0f 02 00 00       	push   $0x20f
c0103867:	68 e8 63 10 c0       	push   $0xc01063e8
c010386c:	e8 72 cb ff ff       	call   c01003e3 <__panic>
    assert(boot_pgdir[0] & PTE_U);
c0103871:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103876:	8b 00                	mov    (%eax),%eax
c0103878:	83 e0 04             	and    $0x4,%eax
c010387b:	85 c0                	test   %eax,%eax
c010387d:	75 19                	jne    c0103898 <check_pgdir+0x2ce>
c010387f:	68 14 66 10 c0       	push   $0xc0106614
c0103884:	68 0d 64 10 c0       	push   $0xc010640d
c0103889:	68 10 02 00 00       	push   $0x210
c010388e:	68 e8 63 10 c0       	push   $0xc01063e8
c0103893:	e8 4b cb ff ff       	call   c01003e3 <__panic>
    assert(page_ref(p2) == 1);
c0103898:	83 ec 0c             	sub    $0xc,%esp
c010389b:	ff 75 e4             	pushl  -0x1c(%ebp)
c010389e:	e8 93 f1 ff ff       	call   c0102a36 <page_ref>
c01038a3:	83 c4 10             	add    $0x10,%esp
c01038a6:	83 f8 01             	cmp    $0x1,%eax
c01038a9:	74 19                	je     c01038c4 <check_pgdir+0x2fa>
c01038ab:	68 2a 66 10 c0       	push   $0xc010662a
c01038b0:	68 0d 64 10 c0       	push   $0xc010640d
c01038b5:	68 11 02 00 00       	push   $0x211
c01038ba:	68 e8 63 10 c0       	push   $0xc01063e8
c01038bf:	e8 1f cb ff ff       	call   c01003e3 <__panic>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
c01038c4:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01038c9:	6a 00                	push   $0x0
c01038cb:	68 00 10 00 00       	push   $0x1000
c01038d0:	ff 75 f4             	pushl  -0xc(%ebp)
c01038d3:	50                   	push   %eax
c01038d4:	e8 c5 fb ff ff       	call   c010349e <page_insert>
c01038d9:	83 c4 10             	add    $0x10,%esp
c01038dc:	85 c0                	test   %eax,%eax
c01038de:	74 19                	je     c01038f9 <check_pgdir+0x32f>
c01038e0:	68 3c 66 10 c0       	push   $0xc010663c
c01038e5:	68 0d 64 10 c0       	push   $0xc010640d
c01038ea:	68 13 02 00 00       	push   $0x213
c01038ef:	68 e8 63 10 c0       	push   $0xc01063e8
c01038f4:	e8 ea ca ff ff       	call   c01003e3 <__panic>
    assert(page_ref(p1) == 2);
c01038f9:	83 ec 0c             	sub    $0xc,%esp
c01038fc:	ff 75 f4             	pushl  -0xc(%ebp)
c01038ff:	e8 32 f1 ff ff       	call   c0102a36 <page_ref>
c0103904:	83 c4 10             	add    $0x10,%esp
c0103907:	83 f8 02             	cmp    $0x2,%eax
c010390a:	74 19                	je     c0103925 <check_pgdir+0x35b>
c010390c:	68 68 66 10 c0       	push   $0xc0106668
c0103911:	68 0d 64 10 c0       	push   $0xc010640d
c0103916:	68 14 02 00 00       	push   $0x214
c010391b:	68 e8 63 10 c0       	push   $0xc01063e8
c0103920:	e8 be ca ff ff       	call   c01003e3 <__panic>
    assert(page_ref(p2) == 0);
c0103925:	83 ec 0c             	sub    $0xc,%esp
c0103928:	ff 75 e4             	pushl  -0x1c(%ebp)
c010392b:	e8 06 f1 ff ff       	call   c0102a36 <page_ref>
c0103930:	83 c4 10             	add    $0x10,%esp
c0103933:	85 c0                	test   %eax,%eax
c0103935:	74 19                	je     c0103950 <check_pgdir+0x386>
c0103937:	68 7a 66 10 c0       	push   $0xc010667a
c010393c:	68 0d 64 10 c0       	push   $0xc010640d
c0103941:	68 15 02 00 00       	push   $0x215
c0103946:	68 e8 63 10 c0       	push   $0xc01063e8
c010394b:	e8 93 ca ff ff       	call   c01003e3 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
c0103950:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103955:	83 ec 04             	sub    $0x4,%esp
c0103958:	6a 00                	push   $0x0
c010395a:	68 00 10 00 00       	push   $0x1000
c010395f:	50                   	push   %eax
c0103960:	e8 28 f9 ff ff       	call   c010328d <get_pte>
c0103965:	83 c4 10             	add    $0x10,%esp
c0103968:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010396b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c010396f:	75 19                	jne    c010398a <check_pgdir+0x3c0>
c0103971:	68 c8 65 10 c0       	push   $0xc01065c8
c0103976:	68 0d 64 10 c0       	push   $0xc010640d
c010397b:	68 16 02 00 00       	push   $0x216
c0103980:	68 e8 63 10 c0       	push   $0xc01063e8
c0103985:	e8 59 ca ff ff       	call   c01003e3 <__panic>
    assert(pte2page(*ptep) == p1);
c010398a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010398d:	8b 00                	mov    (%eax),%eax
c010398f:	83 ec 0c             	sub    $0xc,%esp
c0103992:	50                   	push   %eax
c0103993:	e8 48 f0 ff ff       	call   c01029e0 <pte2page>
c0103998:	83 c4 10             	add    $0x10,%esp
c010399b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c010399e:	74 19                	je     c01039b9 <check_pgdir+0x3ef>
c01039a0:	68 3d 65 10 c0       	push   $0xc010653d
c01039a5:	68 0d 64 10 c0       	push   $0xc010640d
c01039aa:	68 17 02 00 00       	push   $0x217
c01039af:	68 e8 63 10 c0       	push   $0xc01063e8
c01039b4:	e8 2a ca ff ff       	call   c01003e3 <__panic>
    assert((*ptep & PTE_U) == 0);
c01039b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01039bc:	8b 00                	mov    (%eax),%eax
c01039be:	83 e0 04             	and    $0x4,%eax
c01039c1:	85 c0                	test   %eax,%eax
c01039c3:	74 19                	je     c01039de <check_pgdir+0x414>
c01039c5:	68 8c 66 10 c0       	push   $0xc010668c
c01039ca:	68 0d 64 10 c0       	push   $0xc010640d
c01039cf:	68 18 02 00 00       	push   $0x218
c01039d4:	68 e8 63 10 c0       	push   $0xc01063e8
c01039d9:	e8 05 ca ff ff       	call   c01003e3 <__panic>

    page_remove(boot_pgdir, 0x0);
c01039de:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c01039e3:	83 ec 08             	sub    $0x8,%esp
c01039e6:	6a 00                	push   $0x0
c01039e8:	50                   	push   %eax
c01039e9:	e8 77 fa ff ff       	call   c0103465 <page_remove>
c01039ee:	83 c4 10             	add    $0x10,%esp
    assert(page_ref(p1) == 1);
c01039f1:	83 ec 0c             	sub    $0xc,%esp
c01039f4:	ff 75 f4             	pushl  -0xc(%ebp)
c01039f7:	e8 3a f0 ff ff       	call   c0102a36 <page_ref>
c01039fc:	83 c4 10             	add    $0x10,%esp
c01039ff:	83 f8 01             	cmp    $0x1,%eax
c0103a02:	74 19                	je     c0103a1d <check_pgdir+0x453>
c0103a04:	68 53 65 10 c0       	push   $0xc0106553
c0103a09:	68 0d 64 10 c0       	push   $0xc010640d
c0103a0e:	68 1b 02 00 00       	push   $0x21b
c0103a13:	68 e8 63 10 c0       	push   $0xc01063e8
c0103a18:	e8 c6 c9 ff ff       	call   c01003e3 <__panic>
    assert(page_ref(p2) == 0);
c0103a1d:	83 ec 0c             	sub    $0xc,%esp
c0103a20:	ff 75 e4             	pushl  -0x1c(%ebp)
c0103a23:	e8 0e f0 ff ff       	call   c0102a36 <page_ref>
c0103a28:	83 c4 10             	add    $0x10,%esp
c0103a2b:	85 c0                	test   %eax,%eax
c0103a2d:	74 19                	je     c0103a48 <check_pgdir+0x47e>
c0103a2f:	68 7a 66 10 c0       	push   $0xc010667a
c0103a34:	68 0d 64 10 c0       	push   $0xc010640d
c0103a39:	68 1c 02 00 00       	push   $0x21c
c0103a3e:	68 e8 63 10 c0       	push   $0xc01063e8
c0103a43:	e8 9b c9 ff ff       	call   c01003e3 <__panic>

    page_remove(boot_pgdir, PGSIZE);
c0103a48:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103a4d:	83 ec 08             	sub    $0x8,%esp
c0103a50:	68 00 10 00 00       	push   $0x1000
c0103a55:	50                   	push   %eax
c0103a56:	e8 0a fa ff ff       	call   c0103465 <page_remove>
c0103a5b:	83 c4 10             	add    $0x10,%esp
    assert(page_ref(p1) == 0);
c0103a5e:	83 ec 0c             	sub    $0xc,%esp
c0103a61:	ff 75 f4             	pushl  -0xc(%ebp)
c0103a64:	e8 cd ef ff ff       	call   c0102a36 <page_ref>
c0103a69:	83 c4 10             	add    $0x10,%esp
c0103a6c:	85 c0                	test   %eax,%eax
c0103a6e:	74 19                	je     c0103a89 <check_pgdir+0x4bf>
c0103a70:	68 a1 66 10 c0       	push   $0xc01066a1
c0103a75:	68 0d 64 10 c0       	push   $0xc010640d
c0103a7a:	68 1f 02 00 00       	push   $0x21f
c0103a7f:	68 e8 63 10 c0       	push   $0xc01063e8
c0103a84:	e8 5a c9 ff ff       	call   c01003e3 <__panic>
    assert(page_ref(p2) == 0);
c0103a89:	83 ec 0c             	sub    $0xc,%esp
c0103a8c:	ff 75 e4             	pushl  -0x1c(%ebp)
c0103a8f:	e8 a2 ef ff ff       	call   c0102a36 <page_ref>
c0103a94:	83 c4 10             	add    $0x10,%esp
c0103a97:	85 c0                	test   %eax,%eax
c0103a99:	74 19                	je     c0103ab4 <check_pgdir+0x4ea>
c0103a9b:	68 7a 66 10 c0       	push   $0xc010667a
c0103aa0:	68 0d 64 10 c0       	push   $0xc010640d
c0103aa5:	68 20 02 00 00       	push   $0x220
c0103aaa:	68 e8 63 10 c0       	push   $0xc01063e8
c0103aaf:	e8 2f c9 ff ff       	call   c01003e3 <__panic>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
c0103ab4:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103ab9:	8b 00                	mov    (%eax),%eax
c0103abb:	83 ec 0c             	sub    $0xc,%esp
c0103abe:	50                   	push   %eax
c0103abf:	e8 56 ef ff ff       	call   c0102a1a <pde2page>
c0103ac4:	83 c4 10             	add    $0x10,%esp
c0103ac7:	83 ec 0c             	sub    $0xc,%esp
c0103aca:	50                   	push   %eax
c0103acb:	e8 66 ef ff ff       	call   c0102a36 <page_ref>
c0103ad0:	83 c4 10             	add    $0x10,%esp
c0103ad3:	83 f8 01             	cmp    $0x1,%eax
c0103ad6:	74 19                	je     c0103af1 <check_pgdir+0x527>
c0103ad8:	68 b4 66 10 c0       	push   $0xc01066b4
c0103add:	68 0d 64 10 c0       	push   $0xc010640d
c0103ae2:	68 22 02 00 00       	push   $0x222
c0103ae7:	68 e8 63 10 c0       	push   $0xc01063e8
c0103aec:	e8 f2 c8 ff ff       	call   c01003e3 <__panic>
    free_page(pde2page(boot_pgdir[0]));
c0103af1:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103af6:	8b 00                	mov    (%eax),%eax
c0103af8:	83 ec 0c             	sub    $0xc,%esp
c0103afb:	50                   	push   %eax
c0103afc:	e8 19 ef ff ff       	call   c0102a1a <pde2page>
c0103b01:	83 c4 10             	add    $0x10,%esp
c0103b04:	83 ec 08             	sub    $0x8,%esp
c0103b07:	6a 01                	push   $0x1
c0103b09:	50                   	push   %eax
c0103b0a:	e8 73 f1 ff ff       	call   c0102c82 <free_pages>
c0103b0f:	83 c4 10             	add    $0x10,%esp
    boot_pgdir[0] = 0;
c0103b12:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103b17:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_pgdir() succeeded!\n");
c0103b1d:	83 ec 0c             	sub    $0xc,%esp
c0103b20:	68 db 66 10 c0       	push   $0xc01066db
c0103b25:	e8 53 c7 ff ff       	call   c010027d <cprintf>
c0103b2a:	83 c4 10             	add    $0x10,%esp
}
c0103b2d:	90                   	nop
c0103b2e:	c9                   	leave  
c0103b2f:	c3                   	ret    

c0103b30 <check_boot_pgdir>:

static void
check_boot_pgdir(void) {
c0103b30:	55                   	push   %ebp
c0103b31:	89 e5                	mov    %esp,%ebp
c0103b33:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
c0103b36:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0103b3d:	e9 a3 00 00 00       	jmp    c0103be5 <check_boot_pgdir+0xb5>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
c0103b42:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103b45:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103b48:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103b4b:	c1 e8 0c             	shr    $0xc,%eax
c0103b4e:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0103b51:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0103b56:	39 45 ec             	cmp    %eax,-0x14(%ebp)
c0103b59:	72 17                	jb     c0103b72 <check_boot_pgdir+0x42>
c0103b5b:	ff 75 f0             	pushl  -0x10(%ebp)
c0103b5e:	68 20 63 10 c0       	push   $0xc0106320
c0103b63:	68 2e 02 00 00       	push   $0x22e
c0103b68:	68 e8 63 10 c0       	push   $0xc01063e8
c0103b6d:	e8 71 c8 ff ff       	call   c01003e3 <__panic>
c0103b72:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103b75:	2d 00 00 00 40       	sub    $0x40000000,%eax
c0103b7a:	89 c2                	mov    %eax,%edx
c0103b7c:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103b81:	83 ec 04             	sub    $0x4,%esp
c0103b84:	6a 00                	push   $0x0
c0103b86:	52                   	push   %edx
c0103b87:	50                   	push   %eax
c0103b88:	e8 00 f7 ff ff       	call   c010328d <get_pte>
c0103b8d:	83 c4 10             	add    $0x10,%esp
c0103b90:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0103b93:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0103b97:	75 19                	jne    c0103bb2 <check_boot_pgdir+0x82>
c0103b99:	68 f8 66 10 c0       	push   $0xc01066f8
c0103b9e:	68 0d 64 10 c0       	push   $0xc010640d
c0103ba3:	68 2e 02 00 00       	push   $0x22e
c0103ba8:	68 e8 63 10 c0       	push   $0xc01063e8
c0103bad:	e8 31 c8 ff ff       	call   c01003e3 <__panic>
        assert(PTE_ADDR(*ptep) == i);
c0103bb2:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103bb5:	8b 00                	mov    (%eax),%eax
c0103bb7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103bbc:	89 c2                	mov    %eax,%edx
c0103bbe:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103bc1:	39 c2                	cmp    %eax,%edx
c0103bc3:	74 19                	je     c0103bde <check_boot_pgdir+0xae>
c0103bc5:	68 35 67 10 c0       	push   $0xc0106735
c0103bca:	68 0d 64 10 c0       	push   $0xc010640d
c0103bcf:	68 2f 02 00 00       	push   $0x22f
c0103bd4:	68 e8 63 10 c0       	push   $0xc01063e8
c0103bd9:	e8 05 c8 ff ff       	call   c01003e3 <__panic>

static void
check_boot_pgdir(void) {
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
c0103bde:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
c0103be5:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0103be8:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0103bed:	39 c2                	cmp    %eax,%edx
c0103bef:	0f 82 4d ff ff ff    	jb     c0103b42 <check_boot_pgdir+0x12>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
    }

    assert(PDE_ADDR(boot_pgdir[PDX(VPT)]) == PADDR(boot_pgdir));
c0103bf5:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103bfa:	05 ac 0f 00 00       	add    $0xfac,%eax
c0103bff:	8b 00                	mov    (%eax),%eax
c0103c01:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103c06:	89 c2                	mov    %eax,%edx
c0103c08:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103c0d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0103c10:	81 7d e4 ff ff ff bf 	cmpl   $0xbfffffff,-0x1c(%ebp)
c0103c17:	77 17                	ja     c0103c30 <check_boot_pgdir+0x100>
c0103c19:	ff 75 e4             	pushl  -0x1c(%ebp)
c0103c1c:	68 c4 63 10 c0       	push   $0xc01063c4
c0103c21:	68 32 02 00 00       	push   $0x232
c0103c26:	68 e8 63 10 c0       	push   $0xc01063e8
c0103c2b:	e8 b3 c7 ff ff       	call   c01003e3 <__panic>
c0103c30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103c33:	05 00 00 00 40       	add    $0x40000000,%eax
c0103c38:	39 c2                	cmp    %eax,%edx
c0103c3a:	74 19                	je     c0103c55 <check_boot_pgdir+0x125>
c0103c3c:	68 4c 67 10 c0       	push   $0xc010674c
c0103c41:	68 0d 64 10 c0       	push   $0xc010640d
c0103c46:	68 32 02 00 00       	push   $0x232
c0103c4b:	68 e8 63 10 c0       	push   $0xc01063e8
c0103c50:	e8 8e c7 ff ff       	call   c01003e3 <__panic>

    assert(boot_pgdir[0] == 0);
c0103c55:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103c5a:	8b 00                	mov    (%eax),%eax
c0103c5c:	85 c0                	test   %eax,%eax
c0103c5e:	74 19                	je     c0103c79 <check_boot_pgdir+0x149>
c0103c60:	68 80 67 10 c0       	push   $0xc0106780
c0103c65:	68 0d 64 10 c0       	push   $0xc010640d
c0103c6a:	68 34 02 00 00       	push   $0x234
c0103c6f:	68 e8 63 10 c0       	push   $0xc01063e8
c0103c74:	e8 6a c7 ff ff       	call   c01003e3 <__panic>

    struct Page *p;
    p = alloc_page();
c0103c79:	83 ec 0c             	sub    $0xc,%esp
c0103c7c:	6a 01                	push   $0x1
c0103c7e:	e8 c1 ef ff ff       	call   c0102c44 <alloc_pages>
c0103c83:	83 c4 10             	add    $0x10,%esp
c0103c86:	89 45 e0             	mov    %eax,-0x20(%ebp)
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W) == 0);
c0103c89:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103c8e:	6a 02                	push   $0x2
c0103c90:	68 00 01 00 00       	push   $0x100
c0103c95:	ff 75 e0             	pushl  -0x20(%ebp)
c0103c98:	50                   	push   %eax
c0103c99:	e8 00 f8 ff ff       	call   c010349e <page_insert>
c0103c9e:	83 c4 10             	add    $0x10,%esp
c0103ca1:	85 c0                	test   %eax,%eax
c0103ca3:	74 19                	je     c0103cbe <check_boot_pgdir+0x18e>
c0103ca5:	68 94 67 10 c0       	push   $0xc0106794
c0103caa:	68 0d 64 10 c0       	push   $0xc010640d
c0103caf:	68 38 02 00 00       	push   $0x238
c0103cb4:	68 e8 63 10 c0       	push   $0xc01063e8
c0103cb9:	e8 25 c7 ff ff       	call   c01003e3 <__panic>
    assert(page_ref(p) == 1);
c0103cbe:	83 ec 0c             	sub    $0xc,%esp
c0103cc1:	ff 75 e0             	pushl  -0x20(%ebp)
c0103cc4:	e8 6d ed ff ff       	call   c0102a36 <page_ref>
c0103cc9:	83 c4 10             	add    $0x10,%esp
c0103ccc:	83 f8 01             	cmp    $0x1,%eax
c0103ccf:	74 19                	je     c0103cea <check_boot_pgdir+0x1ba>
c0103cd1:	68 c2 67 10 c0       	push   $0xc01067c2
c0103cd6:	68 0d 64 10 c0       	push   $0xc010640d
c0103cdb:	68 39 02 00 00       	push   $0x239
c0103ce0:	68 e8 63 10 c0       	push   $0xc01063e8
c0103ce5:	e8 f9 c6 ff ff       	call   c01003e3 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W) == 0);
c0103cea:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103cef:	6a 02                	push   $0x2
c0103cf1:	68 00 11 00 00       	push   $0x1100
c0103cf6:	ff 75 e0             	pushl  -0x20(%ebp)
c0103cf9:	50                   	push   %eax
c0103cfa:	e8 9f f7 ff ff       	call   c010349e <page_insert>
c0103cff:	83 c4 10             	add    $0x10,%esp
c0103d02:	85 c0                	test   %eax,%eax
c0103d04:	74 19                	je     c0103d1f <check_boot_pgdir+0x1ef>
c0103d06:	68 d4 67 10 c0       	push   $0xc01067d4
c0103d0b:	68 0d 64 10 c0       	push   $0xc010640d
c0103d10:	68 3a 02 00 00       	push   $0x23a
c0103d15:	68 e8 63 10 c0       	push   $0xc01063e8
c0103d1a:	e8 c4 c6 ff ff       	call   c01003e3 <__panic>
    assert(page_ref(p) == 2);
c0103d1f:	83 ec 0c             	sub    $0xc,%esp
c0103d22:	ff 75 e0             	pushl  -0x20(%ebp)
c0103d25:	e8 0c ed ff ff       	call   c0102a36 <page_ref>
c0103d2a:	83 c4 10             	add    $0x10,%esp
c0103d2d:	83 f8 02             	cmp    $0x2,%eax
c0103d30:	74 19                	je     c0103d4b <check_boot_pgdir+0x21b>
c0103d32:	68 0b 68 10 c0       	push   $0xc010680b
c0103d37:	68 0d 64 10 c0       	push   $0xc010640d
c0103d3c:	68 3b 02 00 00       	push   $0x23b
c0103d41:	68 e8 63 10 c0       	push   $0xc01063e8
c0103d46:	e8 98 c6 ff ff       	call   c01003e3 <__panic>

    const char *str = "ucore: Hello world!!";
c0103d4b:	c7 45 dc 1c 68 10 c0 	movl   $0xc010681c,-0x24(%ebp)
    strcpy((void *)0x100, str);
c0103d52:	83 ec 08             	sub    $0x8,%esp
c0103d55:	ff 75 dc             	pushl  -0x24(%ebp)
c0103d58:	68 00 01 00 00       	push   $0x100
c0103d5d:	e8 c3 13 00 00       	call   c0105125 <strcpy>
c0103d62:	83 c4 10             	add    $0x10,%esp
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
c0103d65:	83 ec 08             	sub    $0x8,%esp
c0103d68:	68 00 11 00 00       	push   $0x1100
c0103d6d:	68 00 01 00 00       	push   $0x100
c0103d72:	e8 28 14 00 00       	call   c010519f <strcmp>
c0103d77:	83 c4 10             	add    $0x10,%esp
c0103d7a:	85 c0                	test   %eax,%eax
c0103d7c:	74 19                	je     c0103d97 <check_boot_pgdir+0x267>
c0103d7e:	68 34 68 10 c0       	push   $0xc0106834
c0103d83:	68 0d 64 10 c0       	push   $0xc010640d
c0103d88:	68 3f 02 00 00       	push   $0x23f
c0103d8d:	68 e8 63 10 c0       	push   $0xc01063e8
c0103d92:	e8 4c c6 ff ff       	call   c01003e3 <__panic>

    *(char *)(page2kva(p) + 0x100) = '\0';
c0103d97:	83 ec 0c             	sub    $0xc,%esp
c0103d9a:	ff 75 e0             	pushl  -0x20(%ebp)
c0103d9d:	e8 f9 eb ff ff       	call   c010299b <page2kva>
c0103da2:	83 c4 10             	add    $0x10,%esp
c0103da5:	05 00 01 00 00       	add    $0x100,%eax
c0103daa:	c6 00 00             	movb   $0x0,(%eax)
    assert(strlen((const char *)0x100) == 0);
c0103dad:	83 ec 0c             	sub    $0xc,%esp
c0103db0:	68 00 01 00 00       	push   $0x100
c0103db5:	e8 13 13 00 00       	call   c01050cd <strlen>
c0103dba:	83 c4 10             	add    $0x10,%esp
c0103dbd:	85 c0                	test   %eax,%eax
c0103dbf:	74 19                	je     c0103dda <check_boot_pgdir+0x2aa>
c0103dc1:	68 6c 68 10 c0       	push   $0xc010686c
c0103dc6:	68 0d 64 10 c0       	push   $0xc010640d
c0103dcb:	68 42 02 00 00       	push   $0x242
c0103dd0:	68 e8 63 10 c0       	push   $0xc01063e8
c0103dd5:	e8 09 c6 ff ff       	call   c01003e3 <__panic>

    free_page(p);
c0103dda:	83 ec 08             	sub    $0x8,%esp
c0103ddd:	6a 01                	push   $0x1
c0103ddf:	ff 75 e0             	pushl  -0x20(%ebp)
c0103de2:	e8 9b ee ff ff       	call   c0102c82 <free_pages>
c0103de7:	83 c4 10             	add    $0x10,%esp
    free_page(pde2page(boot_pgdir[0]));
c0103dea:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103def:	8b 00                	mov    (%eax),%eax
c0103df1:	83 ec 0c             	sub    $0xc,%esp
c0103df4:	50                   	push   %eax
c0103df5:	e8 20 ec ff ff       	call   c0102a1a <pde2page>
c0103dfa:	83 c4 10             	add    $0x10,%esp
c0103dfd:	83 ec 08             	sub    $0x8,%esp
c0103e00:	6a 01                	push   $0x1
c0103e02:	50                   	push   %eax
c0103e03:	e8 7a ee ff ff       	call   c0102c82 <free_pages>
c0103e08:	83 c4 10             	add    $0x10,%esp
    boot_pgdir[0] = 0;
c0103e0b:	a1 e0 79 11 c0       	mov    0xc01179e0,%eax
c0103e10:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_boot_pgdir() succeeded!\n");
c0103e16:	83 ec 0c             	sub    $0xc,%esp
c0103e19:	68 90 68 10 c0       	push   $0xc0106890
c0103e1e:	e8 5a c4 ff ff       	call   c010027d <cprintf>
c0103e23:	83 c4 10             	add    $0x10,%esp
}
c0103e26:	90                   	nop
c0103e27:	c9                   	leave  
c0103e28:	c3                   	ret    

c0103e29 <perm2str>:

//perm2str - use string 'u,r,w,-' to present the permission
static const char *
perm2str(int perm) {
c0103e29:	55                   	push   %ebp
c0103e2a:	89 e5                	mov    %esp,%ebp
    static char str[4];
    str[0] = (perm & PTE_U) ? 'u' : '-';
c0103e2c:	8b 45 08             	mov    0x8(%ebp),%eax
c0103e2f:	83 e0 04             	and    $0x4,%eax
c0103e32:	85 c0                	test   %eax,%eax
c0103e34:	74 07                	je     c0103e3d <perm2str+0x14>
c0103e36:	b8 75 00 00 00       	mov    $0x75,%eax
c0103e3b:	eb 05                	jmp    c0103e42 <perm2str+0x19>
c0103e3d:	b8 2d 00 00 00       	mov    $0x2d,%eax
c0103e42:	a2 08 af 11 c0       	mov    %al,0xc011af08
    str[1] = 'r';
c0103e47:	c6 05 09 af 11 c0 72 	movb   $0x72,0xc011af09
    str[2] = (perm & PTE_W) ? 'w' : '-';
c0103e4e:	8b 45 08             	mov    0x8(%ebp),%eax
c0103e51:	83 e0 02             	and    $0x2,%eax
c0103e54:	85 c0                	test   %eax,%eax
c0103e56:	74 07                	je     c0103e5f <perm2str+0x36>
c0103e58:	b8 77 00 00 00       	mov    $0x77,%eax
c0103e5d:	eb 05                	jmp    c0103e64 <perm2str+0x3b>
c0103e5f:	b8 2d 00 00 00       	mov    $0x2d,%eax
c0103e64:	a2 0a af 11 c0       	mov    %al,0xc011af0a
    str[3] = '\0';
c0103e69:	c6 05 0b af 11 c0 00 	movb   $0x0,0xc011af0b
    return str;
c0103e70:	b8 08 af 11 c0       	mov    $0xc011af08,%eax
}
c0103e75:	5d                   	pop    %ebp
c0103e76:	c3                   	ret    

c0103e77 <get_pgtable_items>:
//  table:       the beginning addr of table
//  left_store:  the pointer of the high side of table's next range
//  right_store: the pointer of the low side of table's next range
// return value: 0 - not a invalid item range, perm - a valid item range with perm permission 
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
c0103e77:	55                   	push   %ebp
c0103e78:	89 e5                	mov    %esp,%ebp
c0103e7a:	83 ec 10             	sub    $0x10,%esp
    if (start >= right) {
c0103e7d:	8b 45 10             	mov    0x10(%ebp),%eax
c0103e80:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103e83:	72 0e                	jb     c0103e93 <get_pgtable_items+0x1c>
        return 0;
c0103e85:	b8 00 00 00 00       	mov    $0x0,%eax
c0103e8a:	e9 9a 00 00 00       	jmp    c0103f29 <get_pgtable_items+0xb2>
    }
    while (start < right && !(table[start] & PTE_P)) {
        start ++;
c0103e8f:	83 45 10 01          	addl   $0x1,0x10(%ebp)
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
    if (start >= right) {
        return 0;
    }
    while (start < right && !(table[start] & PTE_P)) {
c0103e93:	8b 45 10             	mov    0x10(%ebp),%eax
c0103e96:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103e99:	73 18                	jae    c0103eb3 <get_pgtable_items+0x3c>
c0103e9b:	8b 45 10             	mov    0x10(%ebp),%eax
c0103e9e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0103ea5:	8b 45 14             	mov    0x14(%ebp),%eax
c0103ea8:	01 d0                	add    %edx,%eax
c0103eaa:	8b 00                	mov    (%eax),%eax
c0103eac:	83 e0 01             	and    $0x1,%eax
c0103eaf:	85 c0                	test   %eax,%eax
c0103eb1:	74 dc                	je     c0103e8f <get_pgtable_items+0x18>
        start ++;
    }
    if (start < right) {
c0103eb3:	8b 45 10             	mov    0x10(%ebp),%eax
c0103eb6:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103eb9:	73 69                	jae    c0103f24 <get_pgtable_items+0xad>
        if (left_store != NULL) {
c0103ebb:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
c0103ebf:	74 08                	je     c0103ec9 <get_pgtable_items+0x52>
            *left_store = start;
c0103ec1:	8b 45 18             	mov    0x18(%ebp),%eax
c0103ec4:	8b 55 10             	mov    0x10(%ebp),%edx
c0103ec7:	89 10                	mov    %edx,(%eax)
        }
        int perm = (table[start ++] & PTE_USER);
c0103ec9:	8b 45 10             	mov    0x10(%ebp),%eax
c0103ecc:	8d 50 01             	lea    0x1(%eax),%edx
c0103ecf:	89 55 10             	mov    %edx,0x10(%ebp)
c0103ed2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0103ed9:	8b 45 14             	mov    0x14(%ebp),%eax
c0103edc:	01 d0                	add    %edx,%eax
c0103ede:	8b 00                	mov    (%eax),%eax
c0103ee0:	83 e0 07             	and    $0x7,%eax
c0103ee3:	89 45 fc             	mov    %eax,-0x4(%ebp)
        while (start < right && (table[start] & PTE_USER) == perm) {
c0103ee6:	eb 04                	jmp    c0103eec <get_pgtable_items+0x75>
            start ++;
c0103ee8:	83 45 10 01          	addl   $0x1,0x10(%ebp)
    if (start < right) {
        if (left_store != NULL) {
            *left_store = start;
        }
        int perm = (table[start ++] & PTE_USER);
        while (start < right && (table[start] & PTE_USER) == perm) {
c0103eec:	8b 45 10             	mov    0x10(%ebp),%eax
c0103eef:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103ef2:	73 1d                	jae    c0103f11 <get_pgtable_items+0x9a>
c0103ef4:	8b 45 10             	mov    0x10(%ebp),%eax
c0103ef7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0103efe:	8b 45 14             	mov    0x14(%ebp),%eax
c0103f01:	01 d0                	add    %edx,%eax
c0103f03:	8b 00                	mov    (%eax),%eax
c0103f05:	83 e0 07             	and    $0x7,%eax
c0103f08:	89 c2                	mov    %eax,%edx
c0103f0a:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0103f0d:	39 c2                	cmp    %eax,%edx
c0103f0f:	74 d7                	je     c0103ee8 <get_pgtable_items+0x71>
            start ++;
        }
        if (right_store != NULL) {
c0103f11:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
c0103f15:	74 08                	je     c0103f1f <get_pgtable_items+0xa8>
            *right_store = start;
c0103f17:	8b 45 1c             	mov    0x1c(%ebp),%eax
c0103f1a:	8b 55 10             	mov    0x10(%ebp),%edx
c0103f1d:	89 10                	mov    %edx,(%eax)
        }
        return perm;
c0103f1f:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0103f22:	eb 05                	jmp    c0103f29 <get_pgtable_items+0xb2>
    }
    return 0;
c0103f24:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0103f29:	c9                   	leave  
c0103f2a:	c3                   	ret    

c0103f2b <print_pgdir>:

//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
c0103f2b:	55                   	push   %ebp
c0103f2c:	89 e5                	mov    %esp,%ebp
c0103f2e:	57                   	push   %edi
c0103f2f:	56                   	push   %esi
c0103f30:	53                   	push   %ebx
c0103f31:	83 ec 2c             	sub    $0x2c,%esp
    cprintf("-------------------- BEGIN --------------------\n");
c0103f34:	83 ec 0c             	sub    $0xc,%esp
c0103f37:	68 b0 68 10 c0       	push   $0xc01068b0
c0103f3c:	e8 3c c3 ff ff       	call   c010027d <cprintf>
c0103f41:	83 c4 10             	add    $0x10,%esp
    size_t left, right = 0, perm;
c0103f44:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
c0103f4b:	e9 e5 00 00 00       	jmp    c0104035 <print_pgdir+0x10a>
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
c0103f50:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103f53:	83 ec 0c             	sub    $0xc,%esp
c0103f56:	50                   	push   %eax
c0103f57:	e8 cd fe ff ff       	call   c0103e29 <perm2str>
c0103f5c:	83 c4 10             	add    $0x10,%esp
c0103f5f:	89 c7                	mov    %eax,%edi
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
c0103f61:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0103f64:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103f67:	29 c2                	sub    %eax,%edx
c0103f69:	89 d0                	mov    %edx,%eax
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
c0103f6b:	c1 e0 16             	shl    $0x16,%eax
c0103f6e:	89 c3                	mov    %eax,%ebx
c0103f70:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0103f73:	c1 e0 16             	shl    $0x16,%eax
c0103f76:	89 c1                	mov    %eax,%ecx
c0103f78:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103f7b:	c1 e0 16             	shl    $0x16,%eax
c0103f7e:	89 c2                	mov    %eax,%edx
c0103f80:	8b 75 dc             	mov    -0x24(%ebp),%esi
c0103f83:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103f86:	29 c6                	sub    %eax,%esi
c0103f88:	89 f0                	mov    %esi,%eax
c0103f8a:	83 ec 08             	sub    $0x8,%esp
c0103f8d:	57                   	push   %edi
c0103f8e:	53                   	push   %ebx
c0103f8f:	51                   	push   %ecx
c0103f90:	52                   	push   %edx
c0103f91:	50                   	push   %eax
c0103f92:	68 e1 68 10 c0       	push   $0xc01068e1
c0103f97:	e8 e1 c2 ff ff       	call   c010027d <cprintf>
c0103f9c:	83 c4 20             	add    $0x20,%esp
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
c0103f9f:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103fa2:	c1 e0 0a             	shl    $0xa,%eax
c0103fa5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
c0103fa8:	eb 4f                	jmp    c0103ff9 <print_pgdir+0xce>
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
c0103faa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103fad:	83 ec 0c             	sub    $0xc,%esp
c0103fb0:	50                   	push   %eax
c0103fb1:	e8 73 fe ff ff       	call   c0103e29 <perm2str>
c0103fb6:	83 c4 10             	add    $0x10,%esp
c0103fb9:	89 c7                	mov    %eax,%edi
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
c0103fbb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0103fbe:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0103fc1:	29 c2                	sub    %eax,%edx
c0103fc3:	89 d0                	mov    %edx,%eax
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
c0103fc5:	c1 e0 0c             	shl    $0xc,%eax
c0103fc8:	89 c3                	mov    %eax,%ebx
c0103fca:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0103fcd:	c1 e0 0c             	shl    $0xc,%eax
c0103fd0:	89 c1                	mov    %eax,%ecx
c0103fd2:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0103fd5:	c1 e0 0c             	shl    $0xc,%eax
c0103fd8:	89 c2                	mov    %eax,%edx
c0103fda:	8b 75 d4             	mov    -0x2c(%ebp),%esi
c0103fdd:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0103fe0:	29 c6                	sub    %eax,%esi
c0103fe2:	89 f0                	mov    %esi,%eax
c0103fe4:	83 ec 08             	sub    $0x8,%esp
c0103fe7:	57                   	push   %edi
c0103fe8:	53                   	push   %ebx
c0103fe9:	51                   	push   %ecx
c0103fea:	52                   	push   %edx
c0103feb:	50                   	push   %eax
c0103fec:	68 00 69 10 c0       	push   $0xc0106900
c0103ff1:	e8 87 c2 ff ff       	call   c010027d <cprintf>
c0103ff6:	83 c4 20             	add    $0x20,%esp
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
        size_t l, r = left * NPTEENTRY;
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
c0103ff9:	be 00 00 c0 fa       	mov    $0xfac00000,%esi
c0103ffe:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0104001:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0104004:	89 d3                	mov    %edx,%ebx
c0104006:	c1 e3 0a             	shl    $0xa,%ebx
c0104009:	8b 55 e0             	mov    -0x20(%ebp),%edx
c010400c:	89 d1                	mov    %edx,%ecx
c010400e:	c1 e1 0a             	shl    $0xa,%ecx
c0104011:	83 ec 08             	sub    $0x8,%esp
c0104014:	8d 55 d4             	lea    -0x2c(%ebp),%edx
c0104017:	52                   	push   %edx
c0104018:	8d 55 d8             	lea    -0x28(%ebp),%edx
c010401b:	52                   	push   %edx
c010401c:	56                   	push   %esi
c010401d:	50                   	push   %eax
c010401e:	53                   	push   %ebx
c010401f:	51                   	push   %ecx
c0104020:	e8 52 fe ff ff       	call   c0103e77 <get_pgtable_items>
c0104025:	83 c4 20             	add    $0x20,%esp
c0104028:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c010402b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c010402f:	0f 85 75 ff ff ff    	jne    c0103faa <print_pgdir+0x7f>
//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
    cprintf("-------------------- BEGIN --------------------\n");
    size_t left, right = 0, perm;
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
c0104035:	b9 00 b0 fe fa       	mov    $0xfafeb000,%ecx
c010403a:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010403d:	83 ec 08             	sub    $0x8,%esp
c0104040:	8d 55 dc             	lea    -0x24(%ebp),%edx
c0104043:	52                   	push   %edx
c0104044:	8d 55 e0             	lea    -0x20(%ebp),%edx
c0104047:	52                   	push   %edx
c0104048:	51                   	push   %ecx
c0104049:	50                   	push   %eax
c010404a:	68 00 04 00 00       	push   $0x400
c010404f:	6a 00                	push   $0x0
c0104051:	e8 21 fe ff ff       	call   c0103e77 <get_pgtable_items>
c0104056:	83 c4 20             	add    $0x20,%esp
c0104059:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c010405c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0104060:	0f 85 ea fe ff ff    	jne    c0103f50 <print_pgdir+0x25>
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
        }
    }
    cprintf("--------------------- END ---------------------\n");
c0104066:	83 ec 0c             	sub    $0xc,%esp
c0104069:	68 24 69 10 c0       	push   $0xc0106924
c010406e:	e8 0a c2 ff ff       	call   c010027d <cprintf>
c0104073:	83 c4 10             	add    $0x10,%esp
}
c0104076:	90                   	nop
c0104077:	8d 65 f4             	lea    -0xc(%ebp),%esp
c010407a:	5b                   	pop    %ebx
c010407b:	5e                   	pop    %esi
c010407c:	5f                   	pop    %edi
c010407d:	5d                   	pop    %ebp
c010407e:	c3                   	ret    

c010407f <page2ppn>:

extern struct Page *pages;
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
c010407f:	55                   	push   %ebp
c0104080:	89 e5                	mov    %esp,%ebp
    return page - pages;//返回在物理内存中第几页
c0104082:	8b 45 08             	mov    0x8(%ebp),%eax
c0104085:	8b 15 18 af 11 c0    	mov    0xc011af18,%edx
c010408b:	29 d0                	sub    %edx,%eax
c010408d:	c1 f8 02             	sar    $0x2,%eax
c0104090:	69 c0 cd cc cc cc    	imul   $0xcccccccd,%eax,%eax
}
c0104096:	5d                   	pop    %ebp
c0104097:	c3                   	ret    

c0104098 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
c0104098:	55                   	push   %ebp
c0104099:	89 e5                	mov    %esp,%ebp
    return page2ppn(page) << PGSHIFT;
c010409b:	ff 75 08             	pushl  0x8(%ebp)
c010409e:	e8 dc ff ff ff       	call   c010407f <page2ppn>
c01040a3:	83 c4 04             	add    $0x4,%esp
c01040a6:	c1 e0 0c             	shl    $0xc,%eax
}
c01040a9:	c9                   	leave  
c01040aa:	c3                   	ret    

c01040ab <page_ref>:
pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde));
}

static inline int
page_ref(struct Page *page) {
c01040ab:	55                   	push   %ebp
c01040ac:	89 e5                	mov    %esp,%ebp
    return page->ref;
c01040ae:	8b 45 08             	mov    0x8(%ebp),%eax
c01040b1:	8b 00                	mov    (%eax),%eax
}
c01040b3:	5d                   	pop    %ebp
c01040b4:	c3                   	ret    

c01040b5 <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
c01040b5:	55                   	push   %ebp
c01040b6:	89 e5                	mov    %esp,%ebp
    page->ref = val;
c01040b8:	8b 45 08             	mov    0x8(%ebp),%eax
c01040bb:	8b 55 0c             	mov    0xc(%ebp),%edx
c01040be:	89 10                	mov    %edx,(%eax)
}
c01040c0:	90                   	nop
c01040c1:	5d                   	pop    %ebp
c01040c2:	c3                   	ret    

c01040c3 <default_init>:

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
c01040c3:	55                   	push   %ebp
c01040c4:	89 e5                	mov    %esp,%ebp
c01040c6:	83 ec 10             	sub    $0x10,%esp
c01040c9:	c7 45 fc 1c af 11 c0 	movl   $0xc011af1c,-0x4(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c01040d0:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01040d3:	8b 55 fc             	mov    -0x4(%ebp),%edx
c01040d6:	89 50 04             	mov    %edx,0x4(%eax)
c01040d9:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01040dc:	8b 50 04             	mov    0x4(%eax),%edx
c01040df:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01040e2:	89 10                	mov    %edx,(%eax)
    list_init(&free_list);
    nr_free = 0;
c01040e4:	c7 05 24 af 11 c0 00 	movl   $0x0,0xc011af24
c01040eb:	00 00 00 
	
}
c01040ee:	90                   	nop
c01040ef:	c9                   	leave  
c01040f0:	c3                   	ret    

c01040f1 <default_init_memmap>:

static void
default_init_memmap(struct Page *base, size_t n) { //实际物理地址
c01040f1:	55                   	push   %ebp
c01040f2:	89 e5                	mov    %esp,%ebp
c01040f4:	83 ec 48             	sub    $0x48,%esp
    assert(n > 0); //强制要求n>0
c01040f7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c01040fb:	75 16                	jne    c0104113 <default_init_memmap+0x22>
c01040fd:	68 58 69 10 c0       	push   $0xc0106958
c0104102:	68 5e 69 10 c0       	push   $0xc010695e
c0104107:	6a 74                	push   $0x74
c0104109:	68 73 69 10 c0       	push   $0xc0106973
c010410e:	e8 d0 c2 ff ff       	call   c01003e3 <__panic>
    struct Page *p = base;  
c0104113:	8b 45 08             	mov    0x8(%ebp),%eax
c0104116:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
c0104119:	eb 6c                	jmp    c0104187 <default_init_memmap+0x96>
        assert(PageReserved(p));//要求不是保留页
c010411b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010411e:	83 c0 04             	add    $0x4,%eax
c0104121:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
c0104128:	89 45 e4             	mov    %eax,-0x1c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c010412b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010412e:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0104131:	0f a3 10             	bt     %edx,(%eax)
c0104134:	19 c0                	sbb    %eax,%eax
c0104136:	89 45 e0             	mov    %eax,-0x20(%ebp)
    return oldbit != 0;
c0104139:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
c010413d:	0f 95 c0             	setne  %al
c0104140:	0f b6 c0             	movzbl %al,%eax
c0104143:	85 c0                	test   %eax,%eax
c0104145:	75 16                	jne    c010415d <default_init_memmap+0x6c>
c0104147:	68 89 69 10 c0       	push   $0xc0106989
c010414c:	68 5e 69 10 c0       	push   $0xc010695e
c0104151:	6a 77                	push   $0x77
c0104153:	68 73 69 10 c0       	push   $0xc0106973
c0104158:	e8 86 c2 ff ff       	call   c01003e3 <__panic>
        p->flags = p->property = 0;//将每个page的flag与property置0 在ffma中每个空闲块的第一个页表结构使用，表示该块空闲页表个数
c010415d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104160:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
c0104167:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010416a:	8b 50 08             	mov    0x8(%eax),%edx
c010416d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104170:	89 50 04             	mov    %edx,0x4(%eax)
        set_page_ref(p, 0);//被映射次数 0
c0104173:	83 ec 08             	sub    $0x8,%esp
c0104176:	6a 00                	push   $0x0
c0104178:	ff 75 f4             	pushl  -0xc(%ebp)
c010417b:	e8 35 ff ff ff       	call   c01040b5 <set_page_ref>
c0104180:	83 c4 10             	add    $0x10,%esp

static void
default_init_memmap(struct Page *base, size_t n) { //实际物理地址
    assert(n > 0); //强制要求n>0
    struct Page *p = base;  
    for (; p != base + n; p ++) {
c0104183:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
c0104187:	8b 55 0c             	mov    0xc(%ebp),%edx
c010418a:	89 d0                	mov    %edx,%eax
c010418c:	c1 e0 02             	shl    $0x2,%eax
c010418f:	01 d0                	add    %edx,%eax
c0104191:	c1 e0 02             	shl    $0x2,%eax
c0104194:	89 c2                	mov    %eax,%edx
c0104196:	8b 45 08             	mov    0x8(%ebp),%eax
c0104199:	01 d0                	add    %edx,%eax
c010419b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c010419e:	0f 85 77 ff ff ff    	jne    c010411b <default_init_memmap+0x2a>
        assert(PageReserved(p));//要求不是保留页
        p->flags = p->property = 0;//将每个page的flag与property置0 在ffma中每个空闲块的第一个页表结构使用，表示该块空闲页表个数
        set_page_ref(p, 0);//被映射次数 0
    }
    base->property = n; //空闲页表数目
c01041a4:	8b 45 08             	mov    0x8(%ebp),%eax
c01041a7:	8b 55 0c             	mov    0xc(%ebp),%edx
c01041aa:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base); //空闲块首页
c01041ad:	8b 45 08             	mov    0x8(%ebp),%eax
c01041b0:	83 c0 04             	add    $0x4,%eax
c01041b3:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
c01041ba:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c01041bd:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c01041c0:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01041c3:	0f ab 10             	bts    %edx,(%eax)
    nr_free += n; //空闲页数目
c01041c6:	8b 15 24 af 11 c0    	mov    0xc011af24,%edx
c01041cc:	8b 45 0c             	mov    0xc(%ebp),%eax
c01041cf:	01 d0                	add    %edx,%eax
c01041d1:	a3 24 af 11 c0       	mov    %eax,0xc011af24
    list_add(&free_list, &(base->page_link));
c01041d6:	8b 45 08             	mov    0x8(%ebp),%eax
c01041d9:	83 c0 0c             	add    $0xc,%eax
c01041dc:	c7 45 f0 1c af 11 c0 	movl   $0xc011af1c,-0x10(%ebp)
c01041e3:	89 45 dc             	mov    %eax,-0x24(%ebp)
c01041e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01041e9:	89 45 d8             	mov    %eax,-0x28(%ebp)
c01041ec:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01041ef:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
c01041f2:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01041f5:	8b 40 04             	mov    0x4(%eax),%eax
c01041f8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01041fb:	89 55 d0             	mov    %edx,-0x30(%ebp)
c01041fe:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0104201:	89 55 cc             	mov    %edx,-0x34(%ebp)
c0104204:	89 45 c8             	mov    %eax,-0x38(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c0104207:	8b 45 c8             	mov    -0x38(%ebp),%eax
c010420a:	8b 55 d0             	mov    -0x30(%ebp),%edx
c010420d:	89 10                	mov    %edx,(%eax)
c010420f:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0104212:	8b 10                	mov    (%eax),%edx
c0104214:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0104217:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c010421a:	8b 45 d0             	mov    -0x30(%ebp),%eax
c010421d:	8b 55 c8             	mov    -0x38(%ebp),%edx
c0104220:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0104223:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104226:	8b 55 cc             	mov    -0x34(%ebp),%edx
c0104229:	89 10                	mov    %edx,(%eax)
}
c010422b:	90                   	nop
c010422c:	c9                   	leave  
c010422d:	c3                   	ret    

c010422e <default_alloc_pages>:

static struct Page *
default_alloc_pages(size_t n) {
c010422e:	55                   	push   %ebp
c010422f:	89 e5                	mov    %esp,%ebp
c0104231:	83 ec 58             	sub    $0x58,%esp
    assert(n > 0);
c0104234:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0104238:	75 19                	jne    c0104253 <default_alloc_pages+0x25>
c010423a:	68 58 69 10 c0       	push   $0xc0106958
c010423f:	68 5e 69 10 c0       	push   $0xc010695e
c0104244:	68 83 00 00 00       	push   $0x83
c0104249:	68 73 69 10 c0       	push   $0xc0106973
c010424e:	e8 90 c1 ff ff       	call   c01003e3 <__panic>
    if (n > nr_free) {
c0104253:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104258:	3b 45 08             	cmp    0x8(%ebp),%eax
c010425b:	73 0a                	jae    c0104267 <default_alloc_pages+0x39>
        return NULL;
c010425d:	b8 00 00 00 00       	mov    $0x0,%eax
c0104262:	e9 3d 01 00 00       	jmp    c01043a4 <default_alloc_pages+0x176>
    }
    struct Page *page = NULL;
c0104267:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    list_entry_t *le = &free_list;
c010426e:	c7 45 f0 1c af 11 c0 	movl   $0xc011af1c,-0x10(%ebp)
    while ((le = list_next(le)) != &free_list) {
c0104275:	eb 1c                	jmp    c0104293 <default_alloc_pages+0x65>
        struct Page *p =  le2page(le, page_link); //将链表节点转换成page
c0104277:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010427a:	83 e8 0c             	sub    $0xc,%eax
c010427d:	89 45 e8             	mov    %eax,-0x18(%ebp)
        if (p->property >= n) {
c0104280:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0104283:	8b 40 08             	mov    0x8(%eax),%eax
c0104286:	3b 45 08             	cmp    0x8(%ebp),%eax
c0104289:	72 08                	jb     c0104293 <default_alloc_pages+0x65>
            page = p;
c010428b:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010428e:	89 45 f4             	mov    %eax,-0xc(%ebp)
            break;
c0104291:	eb 18                	jmp    c01042ab <default_alloc_pages+0x7d>
c0104293:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104296:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0104299:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010429c:	8b 40 04             	mov    0x4(%eax),%eax
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
c010429f:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01042a2:	81 7d f0 1c af 11 c0 	cmpl   $0xc011af1c,-0x10(%ebp)
c01042a9:	75 cc                	jne    c0104277 <default_alloc_pages+0x49>
        if (p->property >= n) {
            page = p;
            break;
        }
    }
    if (page != NULL) {
c01042ab:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01042af:	0f 84 ec 00 00 00    	je     c01043a1 <default_alloc_pages+0x173>
        
        if (page->property > n) {
c01042b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01042b8:	8b 40 08             	mov    0x8(%eax),%eax
c01042bb:	3b 45 08             	cmp    0x8(%ebp),%eax
c01042be:	0f 86 8c 00 00 00    	jbe    c0104350 <default_alloc_pages+0x122>
            struct Page *p = page + n;  //第n个
c01042c4:	8b 55 08             	mov    0x8(%ebp),%edx
c01042c7:	89 d0                	mov    %edx,%eax
c01042c9:	c1 e0 02             	shl    $0x2,%eax
c01042cc:	01 d0                	add    %edx,%eax
c01042ce:	c1 e0 02             	shl    $0x2,%eax
c01042d1:	89 c2                	mov    %eax,%edx
c01042d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01042d6:	01 d0                	add    %edx,%eax
c01042d8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            p->property = page->property - n; //设置空闲页数量
c01042db:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01042de:	8b 40 08             	mov    0x8(%eax),%eax
c01042e1:	2b 45 08             	sub    0x8(%ebp),%eax
c01042e4:	89 c2                	mov    %eax,%edx
c01042e6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01042e9:	89 50 08             	mov    %edx,0x8(%eax)
		    SetPageProperty(p); //设置未头部
c01042ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01042ef:	83 c0 04             	add    $0x4,%eax
c01042f2:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
c01042f9:	89 45 c0             	mov    %eax,-0x40(%ebp)
c01042fc:	8b 45 c0             	mov    -0x40(%ebp),%eax
c01042ff:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0104302:	0f ab 10             	bts    %edx,(%eax)
            list_add_after(&(page->page_link), &(p->page_link));
c0104305:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104308:	83 c0 0c             	add    $0xc,%eax
c010430b:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010430e:	83 c2 0c             	add    $0xc,%edx
c0104311:	89 55 ec             	mov    %edx,-0x14(%ebp)
c0104314:	89 45 d0             	mov    %eax,-0x30(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
c0104317:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010431a:	8b 40 04             	mov    0x4(%eax),%eax
c010431d:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0104320:	89 55 cc             	mov    %edx,-0x34(%ebp)
c0104323:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0104326:	89 55 c8             	mov    %edx,-0x38(%ebp)
c0104329:	89 45 c4             	mov    %eax,-0x3c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c010432c:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c010432f:	8b 55 cc             	mov    -0x34(%ebp),%edx
c0104332:	89 10                	mov    %edx,(%eax)
c0104334:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104337:	8b 10                	mov    (%eax),%edx
c0104339:	8b 45 c8             	mov    -0x38(%ebp),%eax
c010433c:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c010433f:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0104342:	8b 55 c4             	mov    -0x3c(%ebp),%edx
c0104345:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0104348:	8b 45 cc             	mov    -0x34(%ebp),%eax
c010434b:	8b 55 c8             	mov    -0x38(%ebp),%edx
c010434e:	89 10                	mov    %edx,(%eax)
    }
        list_del(&(page->page_link));
c0104350:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104353:	83 c0 0c             	add    $0xc,%eax
c0104356:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c0104359:	8b 45 d8             	mov    -0x28(%ebp),%eax
c010435c:	8b 40 04             	mov    0x4(%eax),%eax
c010435f:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0104362:	8b 12                	mov    (%edx),%edx
c0104364:	89 55 b8             	mov    %edx,-0x48(%ebp)
c0104367:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c010436a:	8b 45 b8             	mov    -0x48(%ebp),%eax
c010436d:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0104370:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c0104373:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c0104376:	8b 55 b8             	mov    -0x48(%ebp),%edx
c0104379:	89 10                	mov    %edx,(%eax)
	    nr_free -= n;
c010437b:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104380:	2b 45 08             	sub    0x8(%ebp),%eax
c0104383:	a3 24 af 11 c0       	mov    %eax,0xc011af24
        ClearPageProperty(page);
c0104388:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010438b:	83 c0 04             	add    $0x4,%eax
c010438e:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
c0104395:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0104398:	8b 45 bc             	mov    -0x44(%ebp),%eax
c010439b:	8b 55 e0             	mov    -0x20(%ebp),%edx
c010439e:	0f b3 10             	btr    %edx,(%eax)
    }
    return page;
c01043a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01043a4:	c9                   	leave  
c01043a5:	c3                   	ret    

c01043a6 <default_free_pages>:

static void
default_free_pages(struct Page *base, size_t n) {
c01043a6:	55                   	push   %ebp
c01043a7:	89 e5                	mov    %esp,%ebp
c01043a9:	81 ec 88 00 00 00    	sub    $0x88,%esp
    assert(n > 0);
c01043af:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c01043b3:	75 19                	jne    c01043ce <default_free_pages+0x28>
c01043b5:	68 58 69 10 c0       	push   $0xc0106958
c01043ba:	68 5e 69 10 c0       	push   $0xc010695e
c01043bf:	68 a1 00 00 00       	push   $0xa1
c01043c4:	68 73 69 10 c0       	push   $0xc0106973
c01043c9:	e8 15 c0 ff ff       	call   c01003e3 <__panic>
    struct Page *p = base;
c01043ce:	8b 45 08             	mov    0x8(%ebp),%eax
c01043d1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	//将这n个连续页flag与ref清零
    for (; p != base + n; p ++) {
c01043d4:	e9 8f 00 00 00       	jmp    c0104468 <default_free_pages+0xc2>
        assert(!PageReserved(p) && !PageProperty(p));//检查
c01043d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01043dc:	83 c0 04             	add    $0x4,%eax
c01043df:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
c01043e6:	89 45 bc             	mov    %eax,-0x44(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c01043e9:	8b 45 bc             	mov    -0x44(%ebp),%eax
c01043ec:	8b 55 c0             	mov    -0x40(%ebp),%edx
c01043ef:	0f a3 10             	bt     %edx,(%eax)
c01043f2:	19 c0                	sbb    %eax,%eax
c01043f4:	89 45 b8             	mov    %eax,-0x48(%ebp)
    return oldbit != 0;
c01043f7:	83 7d b8 00          	cmpl   $0x0,-0x48(%ebp)
c01043fb:	0f 95 c0             	setne  %al
c01043fe:	0f b6 c0             	movzbl %al,%eax
c0104401:	85 c0                	test   %eax,%eax
c0104403:	75 2c                	jne    c0104431 <default_free_pages+0x8b>
c0104405:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104408:	83 c0 04             	add    $0x4,%eax
c010440b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
c0104412:	89 45 b4             	mov    %eax,-0x4c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104415:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c0104418:	8b 55 ec             	mov    -0x14(%ebp),%edx
c010441b:	0f a3 10             	bt     %edx,(%eax)
c010441e:	19 c0                	sbb    %eax,%eax
c0104420:	89 45 b0             	mov    %eax,-0x50(%ebp)
    return oldbit != 0;
c0104423:	83 7d b0 00          	cmpl   $0x0,-0x50(%ebp)
c0104427:	0f 95 c0             	setne  %al
c010442a:	0f b6 c0             	movzbl %al,%eax
c010442d:	85 c0                	test   %eax,%eax
c010442f:	74 19                	je     c010444a <default_free_pages+0xa4>
c0104431:	68 9c 69 10 c0       	push   $0xc010699c
c0104436:	68 5e 69 10 c0       	push   $0xc010695e
c010443b:	68 a5 00 00 00       	push   $0xa5
c0104440:	68 73 69 10 c0       	push   $0xc0106973
c0104445:	e8 99 bf ff ff       	call   c01003e3 <__panic>
        p->flags = 0;
c010444a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010444d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
        set_page_ref(p, 0);
c0104454:	83 ec 08             	sub    $0x8,%esp
c0104457:	6a 00                	push   $0x0
c0104459:	ff 75 f4             	pushl  -0xc(%ebp)
c010445c:	e8 54 fc ff ff       	call   c01040b5 <set_page_ref>
c0104461:	83 c4 10             	add    $0x10,%esp
static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
	//将这n个连续页flag与ref清零
    for (; p != base + n; p ++) {
c0104464:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
c0104468:	8b 55 0c             	mov    0xc(%ebp),%edx
c010446b:	89 d0                	mov    %edx,%eax
c010446d:	c1 e0 02             	shl    $0x2,%eax
c0104470:	01 d0                	add    %edx,%eax
c0104472:	c1 e0 02             	shl    $0x2,%eax
c0104475:	89 c2                	mov    %eax,%edx
c0104477:	8b 45 08             	mov    0x8(%ebp),%eax
c010447a:	01 d0                	add    %edx,%eax
c010447c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c010447f:	0f 85 54 ff ff ff    	jne    c01043d9 <default_free_pages+0x33>
        assert(!PageReserved(p) && !PageProperty(p));//检查
        p->flags = 0;
        set_page_ref(p, 0);
    }
	//设置头页
    base->property = n;
c0104485:	8b 45 08             	mov    0x8(%ebp),%eax
c0104488:	8b 55 0c             	mov    0xc(%ebp),%edx
c010448b:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
c010448e:	8b 45 08             	mov    0x8(%ebp),%eax
c0104491:	83 c0 04             	add    $0x4,%eax
c0104494:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
c010449b:	89 45 ac             	mov    %eax,-0x54(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c010449e:	8b 45 ac             	mov    -0x54(%ebp),%eax
c01044a1:	8b 55 e0             	mov    -0x20(%ebp),%edx
c01044a4:	0f ab 10             	bts    %edx,(%eax)
c01044a7:	c7 45 e8 1c af 11 c0 	movl   $0xc011af1c,-0x18(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c01044ae:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01044b1:	8b 40 04             	mov    0x4(%eax),%eax
    list_entry_t *le = list_next(&free_list);
c01044b4:	89 45 f0             	mov    %eax,-0x10(%ebp)
	//空闲块的合并
    while (le != &free_list) {
c01044b7:	e9 08 01 00 00       	jmp    c01045c4 <default_free_pages+0x21e>
        p = le2page(le, page_link);
c01044bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01044bf:	83 e8 0c             	sub    $0xc,%eax
c01044c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01044c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01044c8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c01044cb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01044ce:	8b 40 04             	mov    0x4(%eax),%eax
        le = list_next(le);
c01044d1:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (base + base->property == p) {
c01044d4:	8b 45 08             	mov    0x8(%ebp),%eax
c01044d7:	8b 50 08             	mov    0x8(%eax),%edx
c01044da:	89 d0                	mov    %edx,%eax
c01044dc:	c1 e0 02             	shl    $0x2,%eax
c01044df:	01 d0                	add    %edx,%eax
c01044e1:	c1 e0 02             	shl    $0x2,%eax
c01044e4:	89 c2                	mov    %eax,%edx
c01044e6:	8b 45 08             	mov    0x8(%ebp),%eax
c01044e9:	01 d0                	add    %edx,%eax
c01044eb:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01044ee:	75 5a                	jne    c010454a <default_free_pages+0x1a4>
            base->property += p->property;
c01044f0:	8b 45 08             	mov    0x8(%ebp),%eax
c01044f3:	8b 50 08             	mov    0x8(%eax),%edx
c01044f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01044f9:	8b 40 08             	mov    0x8(%eax),%eax
c01044fc:	01 c2                	add    %eax,%edx
c01044fe:	8b 45 08             	mov    0x8(%ebp),%eax
c0104501:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(p);
c0104504:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104507:	83 c0 04             	add    $0x4,%eax
c010450a:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
c0104511:	89 45 a0             	mov    %eax,-0x60(%ebp)
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void
clear_bit(int nr, volatile void *addr) {
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0104514:	8b 45 a0             	mov    -0x60(%ebp),%eax
c0104517:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c010451a:	0f b3 10             	btr    %edx,(%eax)
            list_del(&(p->page_link));
c010451d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104520:	83 c0 0c             	add    $0xc,%eax
c0104523:	89 45 dc             	mov    %eax,-0x24(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c0104526:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104529:	8b 40 04             	mov    0x4(%eax),%eax
c010452c:	8b 55 dc             	mov    -0x24(%ebp),%edx
c010452f:	8b 12                	mov    (%edx),%edx
c0104531:	89 55 a8             	mov    %edx,-0x58(%ebp)
c0104534:	89 45 a4             	mov    %eax,-0x5c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c0104537:	8b 45 a8             	mov    -0x58(%ebp),%eax
c010453a:	8b 55 a4             	mov    -0x5c(%ebp),%edx
c010453d:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c0104540:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0104543:	8b 55 a8             	mov    -0x58(%ebp),%edx
c0104546:	89 10                	mov    %edx,(%eax)
c0104548:	eb 7a                	jmp    c01045c4 <default_free_pages+0x21e>
        }
        else if (p + p->property == base) {
c010454a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010454d:	8b 50 08             	mov    0x8(%eax),%edx
c0104550:	89 d0                	mov    %edx,%eax
c0104552:	c1 e0 02             	shl    $0x2,%eax
c0104555:	01 d0                	add    %edx,%eax
c0104557:	c1 e0 02             	shl    $0x2,%eax
c010455a:	89 c2                	mov    %eax,%edx
c010455c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010455f:	01 d0                	add    %edx,%eax
c0104561:	3b 45 08             	cmp    0x8(%ebp),%eax
c0104564:	75 5e                	jne    c01045c4 <default_free_pages+0x21e>
            p->property += base->property;
c0104566:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104569:	8b 50 08             	mov    0x8(%eax),%edx
c010456c:	8b 45 08             	mov    0x8(%ebp),%eax
c010456f:	8b 40 08             	mov    0x8(%eax),%eax
c0104572:	01 c2                	add    %eax,%edx
c0104574:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104577:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(base);
c010457a:	8b 45 08             	mov    0x8(%ebp),%eax
c010457d:	83 c0 04             	add    $0x4,%eax
c0104580:	c7 45 cc 01 00 00 00 	movl   $0x1,-0x34(%ebp)
c0104587:	89 45 94             	mov    %eax,-0x6c(%ebp)
c010458a:	8b 45 94             	mov    -0x6c(%ebp),%eax
c010458d:	8b 55 cc             	mov    -0x34(%ebp),%edx
c0104590:	0f b3 10             	btr    %edx,(%eax)
            base = p;
c0104593:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104596:	89 45 08             	mov    %eax,0x8(%ebp)
            list_del(&(p->page_link));
c0104599:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010459c:	83 c0 0c             	add    $0xc,%eax
c010459f:	89 45 d8             	mov    %eax,-0x28(%ebp)
 * Note: list_empty() on @listelm does not return true after this, the entry is
 * in an undefined state.
 * */
static inline void
list_del(list_entry_t *listelm) {
    __list_del(listelm->prev, listelm->next);
c01045a2:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01045a5:	8b 40 04             	mov    0x4(%eax),%eax
c01045a8:	8b 55 d8             	mov    -0x28(%ebp),%edx
c01045ab:	8b 12                	mov    (%edx),%edx
c01045ad:	89 55 9c             	mov    %edx,-0x64(%ebp)
c01045b0:	89 45 98             	mov    %eax,-0x68(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c01045b3:	8b 45 9c             	mov    -0x64(%ebp),%eax
c01045b6:	8b 55 98             	mov    -0x68(%ebp),%edx
c01045b9:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c01045bc:	8b 45 98             	mov    -0x68(%ebp),%eax
c01045bf:	8b 55 9c             	mov    -0x64(%ebp),%edx
c01045c2:	89 10                	mov    %edx,(%eax)
	//设置头页
    base->property = n;
    SetPageProperty(base);
    list_entry_t *le = list_next(&free_list);
	//空闲块的合并
    while (le != &free_list) {
c01045c4:	81 7d f0 1c af 11 c0 	cmpl   $0xc011af1c,-0x10(%ebp)
c01045cb:	0f 85 eb fe ff ff    	jne    c01044bc <default_free_pages+0x116>
            ClearPageProperty(base);
            base = p;
            list_del(&(p->page_link));
        }
    }
    nr_free += n;
c01045d1:	8b 15 24 af 11 c0    	mov    0xc011af24,%edx
c01045d7:	8b 45 0c             	mov    0xc(%ebp),%eax
c01045da:	01 d0                	add    %edx,%eax
c01045dc:	a3 24 af 11 c0       	mov    %eax,0xc011af24
c01045e1:	c7 45 d0 1c af 11 c0 	movl   $0xc011af1c,-0x30(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c01045e8:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01045eb:	8b 40 04             	mov    0x4(%eax),%eax
	le=list_next(&free_list);
c01045ee:	89 45 f0             	mov    %eax,-0x10(%ebp)
	//按地址从小到大插入。
	while(le!=&free_list){
c01045f1:	eb 69                	jmp    c010465c <default_free_pages+0x2b6>
		p=le2page(le,page_link);
c01045f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01045f6:	83 e8 0c             	sub    $0xc,%eax
c01045f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
		if(base+base->property<=p){
c01045fc:	8b 45 08             	mov    0x8(%ebp),%eax
c01045ff:	8b 50 08             	mov    0x8(%eax),%edx
c0104602:	89 d0                	mov    %edx,%eax
c0104604:	c1 e0 02             	shl    $0x2,%eax
c0104607:	01 d0                	add    %edx,%eax
c0104609:	c1 e0 02             	shl    $0x2,%eax
c010460c:	89 c2                	mov    %eax,%edx
c010460e:	8b 45 08             	mov    0x8(%ebp),%eax
c0104611:	01 d0                	add    %edx,%eax
c0104613:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0104616:	77 35                	ja     c010464d <default_free_pages+0x2a7>
			assert(base+base->property!=p);
c0104618:	8b 45 08             	mov    0x8(%ebp),%eax
c010461b:	8b 50 08             	mov    0x8(%eax),%edx
c010461e:	89 d0                	mov    %edx,%eax
c0104620:	c1 e0 02             	shl    $0x2,%eax
c0104623:	01 d0                	add    %edx,%eax
c0104625:	c1 e0 02             	shl    $0x2,%eax
c0104628:	89 c2                	mov    %eax,%edx
c010462a:	8b 45 08             	mov    0x8(%ebp),%eax
c010462d:	01 d0                	add    %edx,%eax
c010462f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0104632:	75 33                	jne    c0104667 <default_free_pages+0x2c1>
c0104634:	68 c1 69 10 c0       	push   $0xc01069c1
c0104639:	68 5e 69 10 c0       	push   $0xc010695e
c010463e:	68 c3 00 00 00       	push   $0xc3
c0104643:	68 73 69 10 c0       	push   $0xc0106973
c0104648:	e8 96 bd ff ff       	call   c01003e3 <__panic>
c010464d:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104650:	89 45 c8             	mov    %eax,-0x38(%ebp)
c0104653:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0104656:	8b 40 04             	mov    0x4(%eax),%eax
			break;
		}
		le=list_next(le);
c0104659:	89 45 f0             	mov    %eax,-0x10(%ebp)
        }
    }
    nr_free += n;
	le=list_next(&free_list);
	//按地址从小到大插入。
	while(le!=&free_list){
c010465c:	81 7d f0 1c af 11 c0 	cmpl   $0xc011af1c,-0x10(%ebp)
c0104663:	75 8e                	jne    c01045f3 <default_free_pages+0x24d>
c0104665:	eb 01                	jmp    c0104668 <default_free_pages+0x2c2>
		p=le2page(le,page_link);
		if(base+base->property<=p){
			assert(base+base->property!=p);
			break;
c0104667:	90                   	nop
		}
		le=list_next(le);
	}
		
    list_add_before(le, &(base->page_link));
c0104668:	8b 45 08             	mov    0x8(%ebp),%eax
c010466b:	8d 50 0c             	lea    0xc(%eax),%edx
c010466e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104671:	89 45 c4             	mov    %eax,-0x3c(%ebp)
c0104674:	89 55 90             	mov    %edx,-0x70(%ebp)
 * Insert the new element @elm *before* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_before(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm->prev, listelm);
c0104677:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c010467a:	8b 00                	mov    (%eax),%eax
c010467c:	8b 55 90             	mov    -0x70(%ebp),%edx
c010467f:	89 55 8c             	mov    %edx,-0x74(%ebp)
c0104682:	89 45 88             	mov    %eax,-0x78(%ebp)
c0104685:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104688:	89 45 84             	mov    %eax,-0x7c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c010468b:	8b 45 84             	mov    -0x7c(%ebp),%eax
c010468e:	8b 55 8c             	mov    -0x74(%ebp),%edx
c0104691:	89 10                	mov    %edx,(%eax)
c0104693:	8b 45 84             	mov    -0x7c(%ebp),%eax
c0104696:	8b 10                	mov    (%eax),%edx
c0104698:	8b 45 88             	mov    -0x78(%ebp),%eax
c010469b:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c010469e:	8b 45 8c             	mov    -0x74(%ebp),%eax
c01046a1:	8b 55 84             	mov    -0x7c(%ebp),%edx
c01046a4:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c01046a7:	8b 45 8c             	mov    -0x74(%ebp),%eax
c01046aa:	8b 55 88             	mov    -0x78(%ebp),%edx
c01046ad:	89 10                	mov    %edx,(%eax)
}
c01046af:	90                   	nop
c01046b0:	c9                   	leave  
c01046b1:	c3                   	ret    

c01046b2 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void) {
c01046b2:	55                   	push   %ebp
c01046b3:	89 e5                	mov    %esp,%ebp
    return nr_free;
c01046b5:	a1 24 af 11 c0       	mov    0xc011af24,%eax
}
c01046ba:	5d                   	pop    %ebp
c01046bb:	c3                   	ret    

c01046bc <basic_check>:

static void
basic_check(void) {
c01046bc:	55                   	push   %ebp
c01046bd:	89 e5                	mov    %esp,%ebp
c01046bf:	83 ec 38             	sub    $0x38,%esp
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
c01046c2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c01046c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01046cc:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01046cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01046d2:	89 45 ec             	mov    %eax,-0x14(%ebp)
	//连续三次分配页，每次一页
    assert((p0 = alloc_page()) != NULL);
c01046d5:	83 ec 0c             	sub    $0xc,%esp
c01046d8:	6a 01                	push   $0x1
c01046da:	e8 65 e5 ff ff       	call   c0102c44 <alloc_pages>
c01046df:	83 c4 10             	add    $0x10,%esp
c01046e2:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01046e5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c01046e9:	75 19                	jne    c0104704 <basic_check+0x48>
c01046eb:	68 d8 69 10 c0       	push   $0xc01069d8
c01046f0:	68 5e 69 10 c0       	push   $0xc010695e
c01046f5:	68 d6 00 00 00       	push   $0xd6
c01046fa:	68 73 69 10 c0       	push   $0xc0106973
c01046ff:	e8 df bc ff ff       	call   c01003e3 <__panic>
    assert((p1 = alloc_page()) != NULL);
c0104704:	83 ec 0c             	sub    $0xc,%esp
c0104707:	6a 01                	push   $0x1
c0104709:	e8 36 e5 ff ff       	call   c0102c44 <alloc_pages>
c010470e:	83 c4 10             	add    $0x10,%esp
c0104711:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0104714:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0104718:	75 19                	jne    c0104733 <basic_check+0x77>
c010471a:	68 f4 69 10 c0       	push   $0xc01069f4
c010471f:	68 5e 69 10 c0       	push   $0xc010695e
c0104724:	68 d7 00 00 00       	push   $0xd7
c0104729:	68 73 69 10 c0       	push   $0xc0106973
c010472e:	e8 b0 bc ff ff       	call   c01003e3 <__panic>
    assert((p2 = alloc_page()) != NULL);
c0104733:	83 ec 0c             	sub    $0xc,%esp
c0104736:	6a 01                	push   $0x1
c0104738:	e8 07 e5 ff ff       	call   c0102c44 <alloc_pages>
c010473d:	83 c4 10             	add    $0x10,%esp
c0104740:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0104743:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0104747:	75 19                	jne    c0104762 <basic_check+0xa6>
c0104749:	68 10 6a 10 c0       	push   $0xc0106a10
c010474e:	68 5e 69 10 c0       	push   $0xc010695e
c0104753:	68 d8 00 00 00       	push   $0xd8
c0104758:	68 73 69 10 c0       	push   $0xc0106973
c010475d:	e8 81 bc ff ff       	call   c01003e3 <__panic>
	
	//两两不等
    assert(p0 != p1 && p0 != p2 && p1 != p2);
c0104762:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104765:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c0104768:	74 10                	je     c010477a <basic_check+0xbe>
c010476a:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010476d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0104770:	74 08                	je     c010477a <basic_check+0xbe>
c0104772:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104775:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0104778:	75 19                	jne    c0104793 <basic_check+0xd7>
c010477a:	68 2c 6a 10 c0       	push   $0xc0106a2c
c010477f:	68 5e 69 10 c0       	push   $0xc010695e
c0104784:	68 db 00 00 00       	push   $0xdb
c0104789:	68 73 69 10 c0       	push   $0xc0106973
c010478e:	e8 50 bc ff ff       	call   c01003e3 <__panic>
	//当钱物理页面被虚拟页面引用的次数都为0
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
c0104793:	83 ec 0c             	sub    $0xc,%esp
c0104796:	ff 75 ec             	pushl  -0x14(%ebp)
c0104799:	e8 0d f9 ff ff       	call   c01040ab <page_ref>
c010479e:	83 c4 10             	add    $0x10,%esp
c01047a1:	85 c0                	test   %eax,%eax
c01047a3:	75 24                	jne    c01047c9 <basic_check+0x10d>
c01047a5:	83 ec 0c             	sub    $0xc,%esp
c01047a8:	ff 75 f0             	pushl  -0x10(%ebp)
c01047ab:	e8 fb f8 ff ff       	call   c01040ab <page_ref>
c01047b0:	83 c4 10             	add    $0x10,%esp
c01047b3:	85 c0                	test   %eax,%eax
c01047b5:	75 12                	jne    c01047c9 <basic_check+0x10d>
c01047b7:	83 ec 0c             	sub    $0xc,%esp
c01047ba:	ff 75 f4             	pushl  -0xc(%ebp)
c01047bd:	e8 e9 f8 ff ff       	call   c01040ab <page_ref>
c01047c2:	83 c4 10             	add    $0x10,%esp
c01047c5:	85 c0                	test   %eax,%eax
c01047c7:	74 19                	je     c01047e2 <basic_check+0x126>
c01047c9:	68 50 6a 10 c0       	push   $0xc0106a50
c01047ce:	68 5e 69 10 c0       	push   $0xc010695e
c01047d3:	68 dd 00 00 00       	push   $0xdd
c01047d8:	68 73 69 10 c0       	push   $0xc0106973
c01047dd:	e8 01 bc ff ff       	call   c01003e3 <__panic>
	//转换为物理地址后都小于最大物理地址 896M
    assert(page2pa(p0) < npage * PGSIZE);
c01047e2:	83 ec 0c             	sub    $0xc,%esp
c01047e5:	ff 75 ec             	pushl  -0x14(%ebp)
c01047e8:	e8 ab f8 ff ff       	call   c0104098 <page2pa>
c01047ed:	83 c4 10             	add    $0x10,%esp
c01047f0:	89 c2                	mov    %eax,%edx
c01047f2:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c01047f7:	c1 e0 0c             	shl    $0xc,%eax
c01047fa:	39 c2                	cmp    %eax,%edx
c01047fc:	72 19                	jb     c0104817 <basic_check+0x15b>
c01047fe:	68 8c 6a 10 c0       	push   $0xc0106a8c
c0104803:	68 5e 69 10 c0       	push   $0xc010695e
c0104808:	68 df 00 00 00       	push   $0xdf
c010480d:	68 73 69 10 c0       	push   $0xc0106973
c0104812:	e8 cc bb ff ff       	call   c01003e3 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
c0104817:	83 ec 0c             	sub    $0xc,%esp
c010481a:	ff 75 f0             	pushl  -0x10(%ebp)
c010481d:	e8 76 f8 ff ff       	call   c0104098 <page2pa>
c0104822:	83 c4 10             	add    $0x10,%esp
c0104825:	89 c2                	mov    %eax,%edx
c0104827:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c010482c:	c1 e0 0c             	shl    $0xc,%eax
c010482f:	39 c2                	cmp    %eax,%edx
c0104831:	72 19                	jb     c010484c <basic_check+0x190>
c0104833:	68 a9 6a 10 c0       	push   $0xc0106aa9
c0104838:	68 5e 69 10 c0       	push   $0xc010695e
c010483d:	68 e0 00 00 00       	push   $0xe0
c0104842:	68 73 69 10 c0       	push   $0xc0106973
c0104847:	e8 97 bb ff ff       	call   c01003e3 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
c010484c:	83 ec 0c             	sub    $0xc,%esp
c010484f:	ff 75 f4             	pushl  -0xc(%ebp)
c0104852:	e8 41 f8 ff ff       	call   c0104098 <page2pa>
c0104857:	83 c4 10             	add    $0x10,%esp
c010485a:	89 c2                	mov    %eax,%edx
c010485c:	a1 80 ae 11 c0       	mov    0xc011ae80,%eax
c0104861:	c1 e0 0c             	shl    $0xc,%eax
c0104864:	39 c2                	cmp    %eax,%edx
c0104866:	72 19                	jb     c0104881 <basic_check+0x1c5>
c0104868:	68 c6 6a 10 c0       	push   $0xc0106ac6
c010486d:	68 5e 69 10 c0       	push   $0xc010695e
c0104872:	68 e1 00 00 00       	push   $0xe1
c0104877:	68 73 69 10 c0       	push   $0xc0106973
c010487c:	e8 62 bb ff ff       	call   c01003e3 <__panic>

    list_entry_t free_list_store = free_list;
c0104881:	a1 1c af 11 c0       	mov    0xc011af1c,%eax
c0104886:	8b 15 20 af 11 c0    	mov    0xc011af20,%edx
c010488c:	89 45 d0             	mov    %eax,-0x30(%ebp)
c010488f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c0104892:	c7 45 e4 1c af 11 c0 	movl   $0xc011af1c,-0x1c(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c0104899:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010489c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c010489f:	89 50 04             	mov    %edx,0x4(%eax)
c01048a2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01048a5:	8b 50 04             	mov    0x4(%eax),%edx
c01048a8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01048ab:	89 10                	mov    %edx,(%eax)
c01048ad:	c7 45 d8 1c af 11 c0 	movl   $0xc011af1c,-0x28(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
c01048b4:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01048b7:	8b 40 04             	mov    0x4(%eax),%eax
c01048ba:	39 45 d8             	cmp    %eax,-0x28(%ebp)
c01048bd:	0f 94 c0             	sete   %al
c01048c0:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
c01048c3:	85 c0                	test   %eax,%eax
c01048c5:	75 19                	jne    c01048e0 <basic_check+0x224>
c01048c7:	68 e3 6a 10 c0       	push   $0xc0106ae3
c01048cc:	68 5e 69 10 c0       	push   $0xc010695e
c01048d1:	68 e5 00 00 00       	push   $0xe5
c01048d6:	68 73 69 10 c0       	push   $0xc0106973
c01048db:	e8 03 bb ff ff       	call   c01003e3 <__panic>

    unsigned int nr_free_store = nr_free;
c01048e0:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c01048e5:	89 45 e0             	mov    %eax,-0x20(%ebp)
    nr_free = 0;
c01048e8:	c7 05 24 af 11 c0 00 	movl   $0x0,0xc011af24
c01048ef:	00 00 00 
	//检测当空页表为0时确认无法分配
    assert(alloc_page() == NULL);
c01048f2:	83 ec 0c             	sub    $0xc,%esp
c01048f5:	6a 01                	push   $0x1
c01048f7:	e8 48 e3 ff ff       	call   c0102c44 <alloc_pages>
c01048fc:	83 c4 10             	add    $0x10,%esp
c01048ff:	85 c0                	test   %eax,%eax
c0104901:	74 19                	je     c010491c <basic_check+0x260>
c0104903:	68 fa 6a 10 c0       	push   $0xc0106afa
c0104908:	68 5e 69 10 c0       	push   $0xc010695e
c010490d:	68 ea 00 00 00       	push   $0xea
c0104912:	68 73 69 10 c0       	push   $0xc0106973
c0104917:	e8 c7 ba ff ff       	call   c01003e3 <__panic>
	//释放三个页表并确认free操作正常
    free_page(p0);
c010491c:	83 ec 08             	sub    $0x8,%esp
c010491f:	6a 01                	push   $0x1
c0104921:	ff 75 ec             	pushl  -0x14(%ebp)
c0104924:	e8 59 e3 ff ff       	call   c0102c82 <free_pages>
c0104929:	83 c4 10             	add    $0x10,%esp
    free_page(p1);
c010492c:	83 ec 08             	sub    $0x8,%esp
c010492f:	6a 01                	push   $0x1
c0104931:	ff 75 f0             	pushl  -0x10(%ebp)
c0104934:	e8 49 e3 ff ff       	call   c0102c82 <free_pages>
c0104939:	83 c4 10             	add    $0x10,%esp
    free_page(p2);
c010493c:	83 ec 08             	sub    $0x8,%esp
c010493f:	6a 01                	push   $0x1
c0104941:	ff 75 f4             	pushl  -0xc(%ebp)
c0104944:	e8 39 e3 ff ff       	call   c0102c82 <free_pages>
c0104949:	83 c4 10             	add    $0x10,%esp
    assert(nr_free == 3);
c010494c:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104951:	83 f8 03             	cmp    $0x3,%eax
c0104954:	74 19                	je     c010496f <basic_check+0x2b3>
c0104956:	68 0f 6b 10 c0       	push   $0xc0106b0f
c010495b:	68 5e 69 10 c0       	push   $0xc010695e
c0104960:	68 ef 00 00 00       	push   $0xef
c0104965:	68 73 69 10 c0       	push   $0xc0106973
c010496a:	e8 74 ba ff ff       	call   c01003e3 <__panic>
	//释放后可再正常分配
    assert((p0 = alloc_page()) != NULL);
c010496f:	83 ec 0c             	sub    $0xc,%esp
c0104972:	6a 01                	push   $0x1
c0104974:	e8 cb e2 ff ff       	call   c0102c44 <alloc_pages>
c0104979:	83 c4 10             	add    $0x10,%esp
c010497c:	89 45 ec             	mov    %eax,-0x14(%ebp)
c010497f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c0104983:	75 19                	jne    c010499e <basic_check+0x2e2>
c0104985:	68 d8 69 10 c0       	push   $0xc01069d8
c010498a:	68 5e 69 10 c0       	push   $0xc010695e
c010498f:	68 f1 00 00 00       	push   $0xf1
c0104994:	68 73 69 10 c0       	push   $0xc0106973
c0104999:	e8 45 ba ff ff       	call   c01003e3 <__panic>
    assert((p1 = alloc_page()) != NULL);
c010499e:	83 ec 0c             	sub    $0xc,%esp
c01049a1:	6a 01                	push   $0x1
c01049a3:	e8 9c e2 ff ff       	call   c0102c44 <alloc_pages>
c01049a8:	83 c4 10             	add    $0x10,%esp
c01049ab:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01049ae:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c01049b2:	75 19                	jne    c01049cd <basic_check+0x311>
c01049b4:	68 f4 69 10 c0       	push   $0xc01069f4
c01049b9:	68 5e 69 10 c0       	push   $0xc010695e
c01049be:	68 f2 00 00 00       	push   $0xf2
c01049c3:	68 73 69 10 c0       	push   $0xc0106973
c01049c8:	e8 16 ba ff ff       	call   c01003e3 <__panic>
    assert((p2 = alloc_page()) != NULL);
c01049cd:	83 ec 0c             	sub    $0xc,%esp
c01049d0:	6a 01                	push   $0x1
c01049d2:	e8 6d e2 ff ff       	call   c0102c44 <alloc_pages>
c01049d7:	83 c4 10             	add    $0x10,%esp
c01049da:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01049dd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01049e1:	75 19                	jne    c01049fc <basic_check+0x340>
c01049e3:	68 10 6a 10 c0       	push   $0xc0106a10
c01049e8:	68 5e 69 10 c0       	push   $0xc010695e
c01049ed:	68 f3 00 00 00       	push   $0xf3
c01049f2:	68 73 69 10 c0       	push   $0xc0106973
c01049f7:	e8 e7 b9 ff ff       	call   c01003e3 <__panic>
	//再次分配失败
    assert(alloc_page() == NULL);
c01049fc:	83 ec 0c             	sub    $0xc,%esp
c01049ff:	6a 01                	push   $0x1
c0104a01:	e8 3e e2 ff ff       	call   c0102c44 <alloc_pages>
c0104a06:	83 c4 10             	add    $0x10,%esp
c0104a09:	85 c0                	test   %eax,%eax
c0104a0b:	74 19                	je     c0104a26 <basic_check+0x36a>
c0104a0d:	68 fa 6a 10 c0       	push   $0xc0106afa
c0104a12:	68 5e 69 10 c0       	push   $0xc010695e
c0104a17:	68 f5 00 00 00       	push   $0xf5
c0104a1c:	68 73 69 10 c0       	push   $0xc0106973
c0104a21:	e8 bd b9 ff ff       	call   c01003e3 <__panic>
	//分配后链表不为空
    free_page(p0);
c0104a26:	83 ec 08             	sub    $0x8,%esp
c0104a29:	6a 01                	push   $0x1
c0104a2b:	ff 75 ec             	pushl  -0x14(%ebp)
c0104a2e:	e8 4f e2 ff ff       	call   c0102c82 <free_pages>
c0104a33:	83 c4 10             	add    $0x10,%esp
c0104a36:	c7 45 e8 1c af 11 c0 	movl   $0xc011af1c,-0x18(%ebp)
c0104a3d:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0104a40:	8b 40 04             	mov    0x4(%eax),%eax
c0104a43:	39 45 e8             	cmp    %eax,-0x18(%ebp)
c0104a46:	0f 94 c0             	sete   %al
c0104a49:	0f b6 c0             	movzbl %al,%eax
    assert(!list_empty(&free_list));
c0104a4c:	85 c0                	test   %eax,%eax
c0104a4e:	74 19                	je     c0104a69 <basic_check+0x3ad>
c0104a50:	68 1c 6b 10 c0       	push   $0xc0106b1c
c0104a55:	68 5e 69 10 c0       	push   $0xc010695e
c0104a5a:	68 f8 00 00 00       	push   $0xf8
c0104a5f:	68 73 69 10 c0       	push   $0xc0106973
c0104a64:	e8 7a b9 ff ff       	call   c01003e3 <__panic>
	
    struct Page *p;
    assert((p = alloc_page()) == p0);
c0104a69:	83 ec 0c             	sub    $0xc,%esp
c0104a6c:	6a 01                	push   $0x1
c0104a6e:	e8 d1 e1 ff ff       	call   c0102c44 <alloc_pages>
c0104a73:	83 c4 10             	add    $0x10,%esp
c0104a76:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104a79:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104a7c:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c0104a7f:	74 19                	je     c0104a9a <basic_check+0x3de>
c0104a81:	68 34 6b 10 c0       	push   $0xc0106b34
c0104a86:	68 5e 69 10 c0       	push   $0xc010695e
c0104a8b:	68 fb 00 00 00       	push   $0xfb
c0104a90:	68 73 69 10 c0       	push   $0xc0106973
c0104a95:	e8 49 b9 ff ff       	call   c01003e3 <__panic>
    assert(alloc_page() == NULL);
c0104a9a:	83 ec 0c             	sub    $0xc,%esp
c0104a9d:	6a 01                	push   $0x1
c0104a9f:	e8 a0 e1 ff ff       	call   c0102c44 <alloc_pages>
c0104aa4:	83 c4 10             	add    $0x10,%esp
c0104aa7:	85 c0                	test   %eax,%eax
c0104aa9:	74 19                	je     c0104ac4 <basic_check+0x408>
c0104aab:	68 fa 6a 10 c0       	push   $0xc0106afa
c0104ab0:	68 5e 69 10 c0       	push   $0xc010695e
c0104ab5:	68 fc 00 00 00       	push   $0xfc
c0104aba:	68 73 69 10 c0       	push   $0xc0106973
c0104abf:	e8 1f b9 ff ff       	call   c01003e3 <__panic>

    assert(nr_free == 0);
c0104ac4:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104ac9:	85 c0                	test   %eax,%eax
c0104acb:	74 19                	je     c0104ae6 <basic_check+0x42a>
c0104acd:	68 4d 6b 10 c0       	push   $0xc0106b4d
c0104ad2:	68 5e 69 10 c0       	push   $0xc010695e
c0104ad7:	68 fe 00 00 00       	push   $0xfe
c0104adc:	68 73 69 10 c0       	push   $0xc0106973
c0104ae1:	e8 fd b8 ff ff       	call   c01003e3 <__panic>
    free_list = free_list_store;
c0104ae6:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104ae9:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104aec:	a3 1c af 11 c0       	mov    %eax,0xc011af1c
c0104af1:	89 15 20 af 11 c0    	mov    %edx,0xc011af20
    nr_free = nr_free_store;
c0104af7:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0104afa:	a3 24 af 11 c0       	mov    %eax,0xc011af24

    free_page(p);
c0104aff:	83 ec 08             	sub    $0x8,%esp
c0104b02:	6a 01                	push   $0x1
c0104b04:	ff 75 dc             	pushl  -0x24(%ebp)
c0104b07:	e8 76 e1 ff ff       	call   c0102c82 <free_pages>
c0104b0c:	83 c4 10             	add    $0x10,%esp
    free_page(p1);
c0104b0f:	83 ec 08             	sub    $0x8,%esp
c0104b12:	6a 01                	push   $0x1
c0104b14:	ff 75 f0             	pushl  -0x10(%ebp)
c0104b17:	e8 66 e1 ff ff       	call   c0102c82 <free_pages>
c0104b1c:	83 c4 10             	add    $0x10,%esp
    free_page(p2);
c0104b1f:	83 ec 08             	sub    $0x8,%esp
c0104b22:	6a 01                	push   $0x1
c0104b24:	ff 75 f4             	pushl  -0xc(%ebp)
c0104b27:	e8 56 e1 ff ff       	call   c0102c82 <free_pages>
c0104b2c:	83 c4 10             	add    $0x10,%esp
}
c0104b2f:	90                   	nop
c0104b30:	c9                   	leave  
c0104b31:	c3                   	ret    

c0104b32 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
c0104b32:	55                   	push   %ebp
c0104b33:	89 e5                	mov    %esp,%ebp
c0104b35:	81 ec 88 00 00 00    	sub    $0x88,%esp
    int count = 0, total = 0;
c0104b3b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0104b42:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    list_entry_t *le = &free_list;
c0104b49:	c7 45 ec 1c af 11 c0 	movl   $0xc011af1c,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
c0104b50:	eb 60                	jmp    c0104bb2 <default_check+0x80>
        struct Page *p = le2page(le, page_link);
c0104b52:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104b55:	83 e8 0c             	sub    $0xc,%eax
c0104b58:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        assert(PageProperty(p));
c0104b5b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104b5e:	83 c0 04             	add    $0x4,%eax
c0104b61:	c7 45 b0 01 00 00 00 	movl   $0x1,-0x50(%ebp)
c0104b68:	89 45 ac             	mov    %eax,-0x54(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104b6b:	8b 45 ac             	mov    -0x54(%ebp),%eax
c0104b6e:	8b 55 b0             	mov    -0x50(%ebp),%edx
c0104b71:	0f a3 10             	bt     %edx,(%eax)
c0104b74:	19 c0                	sbb    %eax,%eax
c0104b76:	89 45 a8             	mov    %eax,-0x58(%ebp)
    return oldbit != 0;
c0104b79:	83 7d a8 00          	cmpl   $0x0,-0x58(%ebp)
c0104b7d:	0f 95 c0             	setne  %al
c0104b80:	0f b6 c0             	movzbl %al,%eax
c0104b83:	85 c0                	test   %eax,%eax
c0104b85:	75 19                	jne    c0104ba0 <default_check+0x6e>
c0104b87:	68 5a 6b 10 c0       	push   $0xc0106b5a
c0104b8c:	68 5e 69 10 c0       	push   $0xc010695e
c0104b91:	68 0f 01 00 00       	push   $0x10f
c0104b96:	68 73 69 10 c0       	push   $0xc0106973
c0104b9b:	e8 43 b8 ff ff       	call   c01003e3 <__panic>
        count ++, total += p->property;
c0104ba0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
c0104ba4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104ba7:	8b 50 08             	mov    0x8(%eax),%edx
c0104baa:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104bad:	01 d0                	add    %edx,%eax
c0104baf:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0104bb2:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104bb5:	89 45 e0             	mov    %eax,-0x20(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c0104bb8:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0104bbb:	8b 40 04             	mov    0x4(%eax),%eax
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
c0104bbe:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0104bc1:	81 7d ec 1c af 11 c0 	cmpl   $0xc011af1c,-0x14(%ebp)
c0104bc8:	75 88                	jne    c0104b52 <default_check+0x20>
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
    }
    assert(total == nr_free_pages()); //以上检查首页标记
c0104bca:	e8 e8 e0 ff ff       	call   c0102cb7 <nr_free_pages>
c0104bcf:	89 c2                	mov    %eax,%edx
c0104bd1:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104bd4:	39 c2                	cmp    %eax,%edx
c0104bd6:	74 19                	je     c0104bf1 <default_check+0xbf>
c0104bd8:	68 6a 6b 10 c0       	push   $0xc0106b6a
c0104bdd:	68 5e 69 10 c0       	push   $0xc010695e
c0104be2:	68 12 01 00 00       	push   $0x112
c0104be7:	68 73 69 10 c0       	push   $0xc0106973
c0104bec:	e8 f2 b7 ff ff       	call   c01003e3 <__panic>

    basic_check();//对页表分配释放等基本操作的一系列检查
c0104bf1:	e8 c6 fa ff ff       	call   c01046bc <basic_check>

	//可以分配五个连续页表，并且头部标记清零
    struct Page *p0 = alloc_pages(5), *p1, *p2;
c0104bf6:	83 ec 0c             	sub    $0xc,%esp
c0104bf9:	6a 05                	push   $0x5
c0104bfb:	e8 44 e0 ff ff       	call   c0102c44 <alloc_pages>
c0104c00:	83 c4 10             	add    $0x10,%esp
c0104c03:	89 45 dc             	mov    %eax,-0x24(%ebp)
    assert(p0 != NULL);
c0104c06:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c0104c0a:	75 19                	jne    c0104c25 <default_check+0xf3>
c0104c0c:	68 83 6b 10 c0       	push   $0xc0106b83
c0104c11:	68 5e 69 10 c0       	push   $0xc010695e
c0104c16:	68 18 01 00 00       	push   $0x118
c0104c1b:	68 73 69 10 c0       	push   $0xc0106973
c0104c20:	e8 be b7 ff ff       	call   c01003e3 <__panic>
    assert(!PageProperty(p0));
c0104c25:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104c28:	83 c0 04             	add    $0x4,%eax
c0104c2b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
c0104c32:	89 45 a4             	mov    %eax,-0x5c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104c35:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0104c38:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0104c3b:	0f a3 10             	bt     %edx,(%eax)
c0104c3e:	19 c0                	sbb    %eax,%eax
c0104c40:	89 45 a0             	mov    %eax,-0x60(%ebp)
    return oldbit != 0;
c0104c43:	83 7d a0 00          	cmpl   $0x0,-0x60(%ebp)
c0104c47:	0f 95 c0             	setne  %al
c0104c4a:	0f b6 c0             	movzbl %al,%eax
c0104c4d:	85 c0                	test   %eax,%eax
c0104c4f:	74 19                	je     c0104c6a <default_check+0x138>
c0104c51:	68 8e 6b 10 c0       	push   $0xc0106b8e
c0104c56:	68 5e 69 10 c0       	push   $0xc010695e
c0104c5b:	68 19 01 00 00       	push   $0x119
c0104c60:	68 73 69 10 c0       	push   $0xc0106973
c0104c65:	e8 79 b7 ff ff       	call   c01003e3 <__panic>

    list_entry_t free_list_store = free_list;
c0104c6a:	a1 1c af 11 c0       	mov    0xc011af1c,%eax
c0104c6f:	8b 15 20 af 11 c0    	mov    0xc011af20,%edx
c0104c75:	89 45 80             	mov    %eax,-0x80(%ebp)
c0104c78:	89 55 84             	mov    %edx,-0x7c(%ebp)
c0104c7b:	c7 45 d0 1c af 11 c0 	movl   $0xc011af1c,-0x30(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c0104c82:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104c85:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0104c88:	89 50 04             	mov    %edx,0x4(%eax)
c0104c8b:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104c8e:	8b 50 04             	mov    0x4(%eax),%edx
c0104c91:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0104c94:	89 10                	mov    %edx,(%eax)
c0104c96:	c7 45 d8 1c af 11 c0 	movl   $0xc011af1c,-0x28(%ebp)
 * list_empty - tests whether a list is empty
 * @list:       the list to test.
 * */
static inline bool
list_empty(list_entry_t *list) {
    return list->next == list;
c0104c9d:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104ca0:	8b 40 04             	mov    0x4(%eax),%eax
c0104ca3:	39 45 d8             	cmp    %eax,-0x28(%ebp)
c0104ca6:	0f 94 c0             	sete   %al
c0104ca9:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
c0104cac:	85 c0                	test   %eax,%eax
c0104cae:	75 19                	jne    c0104cc9 <default_check+0x197>
c0104cb0:	68 e3 6a 10 c0       	push   $0xc0106ae3
c0104cb5:	68 5e 69 10 c0       	push   $0xc010695e
c0104cba:	68 1d 01 00 00       	push   $0x11d
c0104cbf:	68 73 69 10 c0       	push   $0xc0106973
c0104cc4:	e8 1a b7 ff ff       	call   c01003e3 <__panic>
    assert(alloc_page() == NULL);
c0104cc9:	83 ec 0c             	sub    $0xc,%esp
c0104ccc:	6a 01                	push   $0x1
c0104cce:	e8 71 df ff ff       	call   c0102c44 <alloc_pages>
c0104cd3:	83 c4 10             	add    $0x10,%esp
c0104cd6:	85 c0                	test   %eax,%eax
c0104cd8:	74 19                	je     c0104cf3 <default_check+0x1c1>
c0104cda:	68 fa 6a 10 c0       	push   $0xc0106afa
c0104cdf:	68 5e 69 10 c0       	push   $0xc010695e
c0104ce4:	68 1e 01 00 00       	push   $0x11e
c0104ce9:	68 73 69 10 c0       	push   $0xc0106973
c0104cee:	e8 f0 b6 ff ff       	call   c01003e3 <__panic>

    unsigned int nr_free_store = nr_free;
c0104cf3:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104cf8:	89 45 cc             	mov    %eax,-0x34(%ebp)
    nr_free = 0;
c0104cfb:	c7 05 24 af 11 c0 00 	movl   $0x0,0xc011af24
c0104d02:	00 00 00 

    free_pages(p0 + 2, 3);
c0104d05:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104d08:	83 c0 28             	add    $0x28,%eax
c0104d0b:	83 ec 08             	sub    $0x8,%esp
c0104d0e:	6a 03                	push   $0x3
c0104d10:	50                   	push   %eax
c0104d11:	e8 6c df ff ff       	call   c0102c82 <free_pages>
c0104d16:	83 c4 10             	add    $0x10,%esp
    assert(alloc_pages(4) == NULL);
c0104d19:	83 ec 0c             	sub    $0xc,%esp
c0104d1c:	6a 04                	push   $0x4
c0104d1e:	e8 21 df ff ff       	call   c0102c44 <alloc_pages>
c0104d23:	83 c4 10             	add    $0x10,%esp
c0104d26:	85 c0                	test   %eax,%eax
c0104d28:	74 19                	je     c0104d43 <default_check+0x211>
c0104d2a:	68 a0 6b 10 c0       	push   $0xc0106ba0
c0104d2f:	68 5e 69 10 c0       	push   $0xc010695e
c0104d34:	68 24 01 00 00       	push   $0x124
c0104d39:	68 73 69 10 c0       	push   $0xc0106973
c0104d3e:	e8 a0 b6 ff ff       	call   c01003e3 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
c0104d43:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104d46:	83 c0 28             	add    $0x28,%eax
c0104d49:	83 c0 04             	add    $0x4,%eax
c0104d4c:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
c0104d53:	89 45 9c             	mov    %eax,-0x64(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104d56:	8b 45 9c             	mov    -0x64(%ebp),%eax
c0104d59:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104d5c:	0f a3 10             	bt     %edx,(%eax)
c0104d5f:	19 c0                	sbb    %eax,%eax
c0104d61:	89 45 98             	mov    %eax,-0x68(%ebp)
    return oldbit != 0;
c0104d64:	83 7d 98 00          	cmpl   $0x0,-0x68(%ebp)
c0104d68:	0f 95 c0             	setne  %al
c0104d6b:	0f b6 c0             	movzbl %al,%eax
c0104d6e:	85 c0                	test   %eax,%eax
c0104d70:	74 0e                	je     c0104d80 <default_check+0x24e>
c0104d72:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104d75:	83 c0 28             	add    $0x28,%eax
c0104d78:	8b 40 08             	mov    0x8(%eax),%eax
c0104d7b:	83 f8 03             	cmp    $0x3,%eax
c0104d7e:	74 19                	je     c0104d99 <default_check+0x267>
c0104d80:	68 b8 6b 10 c0       	push   $0xc0106bb8
c0104d85:	68 5e 69 10 c0       	push   $0xc010695e
c0104d8a:	68 25 01 00 00       	push   $0x125
c0104d8f:	68 73 69 10 c0       	push   $0xc0106973
c0104d94:	e8 4a b6 ff ff       	call   c01003e3 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
c0104d99:	83 ec 0c             	sub    $0xc,%esp
c0104d9c:	6a 03                	push   $0x3
c0104d9e:	e8 a1 de ff ff       	call   c0102c44 <alloc_pages>
c0104da3:	83 c4 10             	add    $0x10,%esp
c0104da6:	89 45 c4             	mov    %eax,-0x3c(%ebp)
c0104da9:	83 7d c4 00          	cmpl   $0x0,-0x3c(%ebp)
c0104dad:	75 19                	jne    c0104dc8 <default_check+0x296>
c0104daf:	68 e4 6b 10 c0       	push   $0xc0106be4
c0104db4:	68 5e 69 10 c0       	push   $0xc010695e
c0104db9:	68 26 01 00 00       	push   $0x126
c0104dbe:	68 73 69 10 c0       	push   $0xc0106973
c0104dc3:	e8 1b b6 ff ff       	call   c01003e3 <__panic>
    assert(alloc_page() == NULL);
c0104dc8:	83 ec 0c             	sub    $0xc,%esp
c0104dcb:	6a 01                	push   $0x1
c0104dcd:	e8 72 de ff ff       	call   c0102c44 <alloc_pages>
c0104dd2:	83 c4 10             	add    $0x10,%esp
c0104dd5:	85 c0                	test   %eax,%eax
c0104dd7:	74 19                	je     c0104df2 <default_check+0x2c0>
c0104dd9:	68 fa 6a 10 c0       	push   $0xc0106afa
c0104dde:	68 5e 69 10 c0       	push   $0xc010695e
c0104de3:	68 27 01 00 00       	push   $0x127
c0104de8:	68 73 69 10 c0       	push   $0xc0106973
c0104ded:	e8 f1 b5 ff ff       	call   c01003e3 <__panic>
    assert(p0 + 2 == p1);
c0104df2:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104df5:	83 c0 28             	add    $0x28,%eax
c0104df8:	3b 45 c4             	cmp    -0x3c(%ebp),%eax
c0104dfb:	74 19                	je     c0104e16 <default_check+0x2e4>
c0104dfd:	68 02 6c 10 c0       	push   $0xc0106c02
c0104e02:	68 5e 69 10 c0       	push   $0xc010695e
c0104e07:	68 28 01 00 00       	push   $0x128
c0104e0c:	68 73 69 10 c0       	push   $0xc0106973
c0104e11:	e8 cd b5 ff ff       	call   c01003e3 <__panic>

    p2 = p0 + 1;
c0104e16:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104e19:	83 c0 14             	add    $0x14,%eax
c0104e1c:	89 45 c0             	mov    %eax,-0x40(%ebp)
    free_page(p0);//默认释放1个
c0104e1f:	83 ec 08             	sub    $0x8,%esp
c0104e22:	6a 01                	push   $0x1
c0104e24:	ff 75 dc             	pushl  -0x24(%ebp)
c0104e27:	e8 56 de ff ff       	call   c0102c82 <free_pages>
c0104e2c:	83 c4 10             	add    $0x10,%esp
    free_pages(p1, 3);
c0104e2f:	83 ec 08             	sub    $0x8,%esp
c0104e32:	6a 03                	push   $0x3
c0104e34:	ff 75 c4             	pushl  -0x3c(%ebp)
c0104e37:	e8 46 de ff ff       	call   c0102c82 <free_pages>
c0104e3c:	83 c4 10             	add    $0x10,%esp
    assert(PageProperty(p0) && p0->property == 1);
c0104e3f:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104e42:	83 c0 04             	add    $0x4,%eax
c0104e45:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
c0104e4c:	89 45 94             	mov    %eax,-0x6c(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104e4f:	8b 45 94             	mov    -0x6c(%ebp),%eax
c0104e52:	8b 55 c8             	mov    -0x38(%ebp),%edx
c0104e55:	0f a3 10             	bt     %edx,(%eax)
c0104e58:	19 c0                	sbb    %eax,%eax
c0104e5a:	89 45 90             	mov    %eax,-0x70(%ebp)
    return oldbit != 0;
c0104e5d:	83 7d 90 00          	cmpl   $0x0,-0x70(%ebp)
c0104e61:	0f 95 c0             	setne  %al
c0104e64:	0f b6 c0             	movzbl %al,%eax
c0104e67:	85 c0                	test   %eax,%eax
c0104e69:	74 0b                	je     c0104e76 <default_check+0x344>
c0104e6b:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104e6e:	8b 40 08             	mov    0x8(%eax),%eax
c0104e71:	83 f8 01             	cmp    $0x1,%eax
c0104e74:	74 19                	je     c0104e8f <default_check+0x35d>
c0104e76:	68 10 6c 10 c0       	push   $0xc0106c10
c0104e7b:	68 5e 69 10 c0       	push   $0xc010695e
c0104e80:	68 2d 01 00 00       	push   $0x12d
c0104e85:	68 73 69 10 c0       	push   $0xc0106973
c0104e8a:	e8 54 b5 ff ff       	call   c01003e3 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
c0104e8f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104e92:	83 c0 04             	add    $0x4,%eax
c0104e95:	c7 45 bc 01 00 00 00 	movl   $0x1,-0x44(%ebp)
c0104e9c:	89 45 8c             	mov    %eax,-0x74(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0104e9f:	8b 45 8c             	mov    -0x74(%ebp),%eax
c0104ea2:	8b 55 bc             	mov    -0x44(%ebp),%edx
c0104ea5:	0f a3 10             	bt     %edx,(%eax)
c0104ea8:	19 c0                	sbb    %eax,%eax
c0104eaa:	89 45 88             	mov    %eax,-0x78(%ebp)
    return oldbit != 0;
c0104ead:	83 7d 88 00          	cmpl   $0x0,-0x78(%ebp)
c0104eb1:	0f 95 c0             	setne  %al
c0104eb4:	0f b6 c0             	movzbl %al,%eax
c0104eb7:	85 c0                	test   %eax,%eax
c0104eb9:	74 0b                	je     c0104ec6 <default_check+0x394>
c0104ebb:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0104ebe:	8b 40 08             	mov    0x8(%eax),%eax
c0104ec1:	83 f8 03             	cmp    $0x3,%eax
c0104ec4:	74 19                	je     c0104edf <default_check+0x3ad>
c0104ec6:	68 38 6c 10 c0       	push   $0xc0106c38
c0104ecb:	68 5e 69 10 c0       	push   $0xc010695e
c0104ed0:	68 2e 01 00 00       	push   $0x12e
c0104ed5:	68 73 69 10 c0       	push   $0xc0106973
c0104eda:	e8 04 b5 ff ff       	call   c01003e3 <__panic>
	//对空闲页表按照地址从小到大排列的检测
    assert((p0 = alloc_page()) == p2 - 1);
c0104edf:	83 ec 0c             	sub    $0xc,%esp
c0104ee2:	6a 01                	push   $0x1
c0104ee4:	e8 5b dd ff ff       	call   c0102c44 <alloc_pages>
c0104ee9:	83 c4 10             	add    $0x10,%esp
c0104eec:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104eef:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0104ef2:	83 e8 14             	sub    $0x14,%eax
c0104ef5:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c0104ef8:	74 19                	je     c0104f13 <default_check+0x3e1>
c0104efa:	68 5e 6c 10 c0       	push   $0xc0106c5e
c0104eff:	68 5e 69 10 c0       	push   $0xc010695e
c0104f04:	68 30 01 00 00       	push   $0x130
c0104f09:	68 73 69 10 c0       	push   $0xc0106973
c0104f0e:	e8 d0 b4 ff ff       	call   c01003e3 <__panic>
    free_page(p0);
c0104f13:	83 ec 08             	sub    $0x8,%esp
c0104f16:	6a 01                	push   $0x1
c0104f18:	ff 75 dc             	pushl  -0x24(%ebp)
c0104f1b:	e8 62 dd ff ff       	call   c0102c82 <free_pages>
c0104f20:	83 c4 10             	add    $0x10,%esp
    assert((p0 = alloc_pages(2)) == p2 + 1);
c0104f23:	83 ec 0c             	sub    $0xc,%esp
c0104f26:	6a 02                	push   $0x2
c0104f28:	e8 17 dd ff ff       	call   c0102c44 <alloc_pages>
c0104f2d:	83 c4 10             	add    $0x10,%esp
c0104f30:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104f33:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0104f36:	83 c0 14             	add    $0x14,%eax
c0104f39:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c0104f3c:	74 19                	je     c0104f57 <default_check+0x425>
c0104f3e:	68 7c 6c 10 c0       	push   $0xc0106c7c
c0104f43:	68 5e 69 10 c0       	push   $0xc010695e
c0104f48:	68 32 01 00 00       	push   $0x132
c0104f4d:	68 73 69 10 c0       	push   $0xc0106973
c0104f52:	e8 8c b4 ff ff       	call   c01003e3 <__panic>

    free_pages(p0, 2);
c0104f57:	83 ec 08             	sub    $0x8,%esp
c0104f5a:	6a 02                	push   $0x2
c0104f5c:	ff 75 dc             	pushl  -0x24(%ebp)
c0104f5f:	e8 1e dd ff ff       	call   c0102c82 <free_pages>
c0104f64:	83 c4 10             	add    $0x10,%esp
    free_page(p2);
c0104f67:	83 ec 08             	sub    $0x8,%esp
c0104f6a:	6a 01                	push   $0x1
c0104f6c:	ff 75 c0             	pushl  -0x40(%ebp)
c0104f6f:	e8 0e dd ff ff       	call   c0102c82 <free_pages>
c0104f74:	83 c4 10             	add    $0x10,%esp
	//检查页表合并
    assert((p0 = alloc_pages(5)) != NULL);
c0104f77:	83 ec 0c             	sub    $0xc,%esp
c0104f7a:	6a 05                	push   $0x5
c0104f7c:	e8 c3 dc ff ff       	call   c0102c44 <alloc_pages>
c0104f81:	83 c4 10             	add    $0x10,%esp
c0104f84:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104f87:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c0104f8b:	75 19                	jne    c0104fa6 <default_check+0x474>
c0104f8d:	68 9c 6c 10 c0       	push   $0xc0106c9c
c0104f92:	68 5e 69 10 c0       	push   $0xc010695e
c0104f97:	68 37 01 00 00       	push   $0x137
c0104f9c:	68 73 69 10 c0       	push   $0xc0106973
c0104fa1:	e8 3d b4 ff ff       	call   c01003e3 <__panic>
    assert(alloc_page() == NULL);
c0104fa6:	83 ec 0c             	sub    $0xc,%esp
c0104fa9:	6a 01                	push   $0x1
c0104fab:	e8 94 dc ff ff       	call   c0102c44 <alloc_pages>
c0104fb0:	83 c4 10             	add    $0x10,%esp
c0104fb3:	85 c0                	test   %eax,%eax
c0104fb5:	74 19                	je     c0104fd0 <default_check+0x49e>
c0104fb7:	68 fa 6a 10 c0       	push   $0xc0106afa
c0104fbc:	68 5e 69 10 c0       	push   $0xc010695e
c0104fc1:	68 38 01 00 00       	push   $0x138
c0104fc6:	68 73 69 10 c0       	push   $0xc0106973
c0104fcb:	e8 13 b4 ff ff       	call   c01003e3 <__panic>

    assert(nr_free == 0);
c0104fd0:	a1 24 af 11 c0       	mov    0xc011af24,%eax
c0104fd5:	85 c0                	test   %eax,%eax
c0104fd7:	74 19                	je     c0104ff2 <default_check+0x4c0>
c0104fd9:	68 4d 6b 10 c0       	push   $0xc0106b4d
c0104fde:	68 5e 69 10 c0       	push   $0xc010695e
c0104fe3:	68 3a 01 00 00       	push   $0x13a
c0104fe8:	68 73 69 10 c0       	push   $0xc0106973
c0104fed:	e8 f1 b3 ff ff       	call   c01003e3 <__panic>
    nr_free = nr_free_store;
c0104ff2:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0104ff5:	a3 24 af 11 c0       	mov    %eax,0xc011af24

    free_list = free_list_store;
c0104ffa:	8b 45 80             	mov    -0x80(%ebp),%eax
c0104ffd:	8b 55 84             	mov    -0x7c(%ebp),%edx
c0105000:	a3 1c af 11 c0       	mov    %eax,0xc011af1c
c0105005:	89 15 20 af 11 c0    	mov    %edx,0xc011af20
    free_pages(p0, 5);
c010500b:	83 ec 08             	sub    $0x8,%esp
c010500e:	6a 05                	push   $0x5
c0105010:	ff 75 dc             	pushl  -0x24(%ebp)
c0105013:	e8 6a dc ff ff       	call   c0102c82 <free_pages>
c0105018:	83 c4 10             	add    $0x10,%esp

    le = &free_list;
c010501b:	c7 45 ec 1c af 11 c0 	movl   $0xc011af1c,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
c0105022:	eb 50                	jmp    c0105074 <default_check+0x542>
        assert(le->next->prev == le && le->prev->next == le);//对指针的检查
c0105024:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105027:	8b 40 04             	mov    0x4(%eax),%eax
c010502a:	8b 00                	mov    (%eax),%eax
c010502c:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c010502f:	75 0d                	jne    c010503e <default_check+0x50c>
c0105031:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105034:	8b 00                	mov    (%eax),%eax
c0105036:	8b 40 04             	mov    0x4(%eax),%eax
c0105039:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c010503c:	74 19                	je     c0105057 <default_check+0x525>
c010503e:	68 bc 6c 10 c0       	push   $0xc0106cbc
c0105043:	68 5e 69 10 c0       	push   $0xc010695e
c0105048:	68 42 01 00 00       	push   $0x142
c010504d:	68 73 69 10 c0       	push   $0xc0106973
c0105052:	e8 8c b3 ff ff       	call   c01003e3 <__panic>
        struct Page *p = le2page(le, page_link);
c0105057:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010505a:	83 e8 0c             	sub    $0xc,%eax
c010505d:	89 45 b4             	mov    %eax,-0x4c(%ebp)
        count --, total -= p->property;
c0105060:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
c0105064:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0105067:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c010506a:	8b 40 08             	mov    0x8(%eax),%eax
c010506d:	29 c2                	sub    %eax,%edx
c010506f:	89 d0                	mov    %edx,%eax
c0105071:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105074:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105077:	89 45 b8             	mov    %eax,-0x48(%ebp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
c010507a:	8b 45 b8             	mov    -0x48(%ebp),%eax
c010507d:	8b 40 04             	mov    0x4(%eax),%eax

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
c0105080:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0105083:	81 7d ec 1c af 11 c0 	cmpl   $0xc011af1c,-0x14(%ebp)
c010508a:	75 98                	jne    c0105024 <default_check+0x4f2>
        assert(le->next->prev == le && le->prev->next == le);//对指针的检查
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
    }
	//对空快与空页表总数的检查
    assert(count == 0);
c010508c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0105090:	74 19                	je     c01050ab <default_check+0x579>
c0105092:	68 e9 6c 10 c0       	push   $0xc0106ce9
c0105097:	68 5e 69 10 c0       	push   $0xc010695e
c010509c:	68 47 01 00 00       	push   $0x147
c01050a1:	68 73 69 10 c0       	push   $0xc0106973
c01050a6:	e8 38 b3 ff ff       	call   c01003e3 <__panic>
    assert(total == 0);
c01050ab:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c01050af:	74 19                	je     c01050ca <default_check+0x598>
c01050b1:	68 f4 6c 10 c0       	push   $0xc0106cf4
c01050b6:	68 5e 69 10 c0       	push   $0xc010695e
c01050bb:	68 48 01 00 00       	push   $0x148
c01050c0:	68 73 69 10 c0       	push   $0xc0106973
c01050c5:	e8 19 b3 ff ff       	call   c01003e3 <__panic>
}
c01050ca:	90                   	nop
c01050cb:	c9                   	leave  
c01050cc:	c3                   	ret    

c01050cd <strlen>:
 * @s:      the input string
 *
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
c01050cd:	55                   	push   %ebp
c01050ce:	89 e5                	mov    %esp,%ebp
c01050d0:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
c01050d3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (*s ++ != '\0') {
c01050da:	eb 04                	jmp    c01050e0 <strlen+0x13>
        cnt ++;
c01050dc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
c01050e0:	8b 45 08             	mov    0x8(%ebp),%eax
c01050e3:	8d 50 01             	lea    0x1(%eax),%edx
c01050e6:	89 55 08             	mov    %edx,0x8(%ebp)
c01050e9:	0f b6 00             	movzbl (%eax),%eax
c01050ec:	84 c0                	test   %al,%al
c01050ee:	75 ec                	jne    c01050dc <strlen+0xf>
        cnt ++;
    }
    return cnt;
c01050f0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c01050f3:	c9                   	leave  
c01050f4:	c3                   	ret    

c01050f5 <strnlen>:
 * The return value is strlen(s), if that is less than @len, or
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
c01050f5:	55                   	push   %ebp
c01050f6:	89 e5                	mov    %esp,%ebp
c01050f8:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
c01050fb:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (cnt < len && *s ++ != '\0') {
c0105102:	eb 04                	jmp    c0105108 <strnlen+0x13>
        cnt ++;
c0105104:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
c0105108:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010510b:	3b 45 0c             	cmp    0xc(%ebp),%eax
c010510e:	73 10                	jae    c0105120 <strnlen+0x2b>
c0105110:	8b 45 08             	mov    0x8(%ebp),%eax
c0105113:	8d 50 01             	lea    0x1(%eax),%edx
c0105116:	89 55 08             	mov    %edx,0x8(%ebp)
c0105119:	0f b6 00             	movzbl (%eax),%eax
c010511c:	84 c0                	test   %al,%al
c010511e:	75 e4                	jne    c0105104 <strnlen+0xf>
        cnt ++;
    }
    return cnt;
c0105120:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c0105123:	c9                   	leave  
c0105124:	c3                   	ret    

c0105125 <strcpy>:
 * To avoid overflows, the size of array pointed by @dst should be long enough to
 * contain the same string as @src (including the terminating null character), and
 * should not overlap in memory with @src.
 * */
char *
strcpy(char *dst, const char *src) {
c0105125:	55                   	push   %ebp
c0105126:	89 e5                	mov    %esp,%ebp
c0105128:	57                   	push   %edi
c0105129:	56                   	push   %esi
c010512a:	83 ec 20             	sub    $0x20,%esp
c010512d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105130:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0105133:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105136:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCPY
#define __HAVE_ARCH_STRCPY
static inline char *
__strcpy(char *dst, const char *src) {
    int d0, d1, d2;
    asm volatile (
c0105139:	8b 55 f0             	mov    -0x10(%ebp),%edx
c010513c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010513f:	89 d1                	mov    %edx,%ecx
c0105141:	89 c2                	mov    %eax,%edx
c0105143:	89 ce                	mov    %ecx,%esi
c0105145:	89 d7                	mov    %edx,%edi
c0105147:	ac                   	lods   %ds:(%esi),%al
c0105148:	aa                   	stos   %al,%es:(%edi)
c0105149:	84 c0                	test   %al,%al
c010514b:	75 fa                	jne    c0105147 <strcpy+0x22>
c010514d:	89 fa                	mov    %edi,%edx
c010514f:	89 f1                	mov    %esi,%ecx
c0105151:	89 4d ec             	mov    %ecx,-0x14(%ebp)
c0105154:	89 55 e8             	mov    %edx,-0x18(%ebp)
c0105157:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        "stosb;"
        "testb %%al, %%al;"
        "jne 1b;"
        : "=&S" (d0), "=&D" (d1), "=&a" (d2)
        : "0" (src), "1" (dst) : "memory");
    return dst;
c010515a:	8b 45 f4             	mov    -0xc(%ebp),%eax
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
c010515d:	90                   	nop
    char *p = dst;
    while ((*p ++ = *src ++) != '\0')
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
c010515e:	83 c4 20             	add    $0x20,%esp
c0105161:	5e                   	pop    %esi
c0105162:	5f                   	pop    %edi
c0105163:	5d                   	pop    %ebp
c0105164:	c3                   	ret    

c0105165 <strncpy>:
 * @len:    maximum number of characters to be copied from @src
 *
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
c0105165:	55                   	push   %ebp
c0105166:	89 e5                	mov    %esp,%ebp
c0105168:	83 ec 10             	sub    $0x10,%esp
    char *p = dst;
c010516b:	8b 45 08             	mov    0x8(%ebp),%eax
c010516e:	89 45 fc             	mov    %eax,-0x4(%ebp)
    while (len > 0) {
c0105171:	eb 21                	jmp    c0105194 <strncpy+0x2f>
        if ((*p = *src) != '\0') {
c0105173:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105176:	0f b6 10             	movzbl (%eax),%edx
c0105179:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010517c:	88 10                	mov    %dl,(%eax)
c010517e:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0105181:	0f b6 00             	movzbl (%eax),%eax
c0105184:	84 c0                	test   %al,%al
c0105186:	74 04                	je     c010518c <strncpy+0x27>
            src ++;
c0105188:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
        }
        p ++, len --;
c010518c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c0105190:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
    char *p = dst;
    while (len > 0) {
c0105194:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0105198:	75 d9                	jne    c0105173 <strncpy+0xe>
        if ((*p = *src) != '\0') {
            src ++;
        }
        p ++, len --;
    }
    return dst;
c010519a:	8b 45 08             	mov    0x8(%ebp),%eax
}
c010519d:	c9                   	leave  
c010519e:	c3                   	ret    

c010519f <strcmp>:
 * - A value greater than zero indicates that the first character that does
 *   not match has a greater value in @s1 than in @s2;
 * - And a value less than zero indicates the opposite.
 * */
int
strcmp(const char *s1, const char *s2) {
c010519f:	55                   	push   %ebp
c01051a0:	89 e5                	mov    %esp,%ebp
c01051a2:	57                   	push   %edi
c01051a3:	56                   	push   %esi
c01051a4:	83 ec 20             	sub    $0x20,%esp
c01051a7:	8b 45 08             	mov    0x8(%ebp),%eax
c01051aa:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01051ad:	8b 45 0c             	mov    0xc(%ebp),%eax
c01051b0:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCMP
#define __HAVE_ARCH_STRCMP
static inline int
__strcmp(const char *s1, const char *s2) {
    int d0, d1, ret;
    asm volatile (
c01051b3:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01051b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01051b9:	89 d1                	mov    %edx,%ecx
c01051bb:	89 c2                	mov    %eax,%edx
c01051bd:	89 ce                	mov    %ecx,%esi
c01051bf:	89 d7                	mov    %edx,%edi
c01051c1:	ac                   	lods   %ds:(%esi),%al
c01051c2:	ae                   	scas   %es:(%edi),%al
c01051c3:	75 08                	jne    c01051cd <strcmp+0x2e>
c01051c5:	84 c0                	test   %al,%al
c01051c7:	75 f8                	jne    c01051c1 <strcmp+0x22>
c01051c9:	31 c0                	xor    %eax,%eax
c01051cb:	eb 04                	jmp    c01051d1 <strcmp+0x32>
c01051cd:	19 c0                	sbb    %eax,%eax
c01051cf:	0c 01                	or     $0x1,%al
c01051d1:	89 fa                	mov    %edi,%edx
c01051d3:	89 f1                	mov    %esi,%ecx
c01051d5:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01051d8:	89 4d e8             	mov    %ecx,-0x18(%ebp)
c01051db:	89 55 e4             	mov    %edx,-0x1c(%ebp)
        "orb $1, %%al;"
        "3:"
        : "=a" (ret), "=&S" (d0), "=&D" (d1)
        : "1" (s1), "2" (s2)
        : "memory");
    return ret;
c01051de:	8b 45 ec             	mov    -0x14(%ebp),%eax
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
c01051e1:	90                   	nop
    while (*s1 != '\0' && *s1 == *s2) {
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
#endif /* __HAVE_ARCH_STRCMP */
}
c01051e2:	83 c4 20             	add    $0x20,%esp
c01051e5:	5e                   	pop    %esi
c01051e6:	5f                   	pop    %edi
c01051e7:	5d                   	pop    %ebp
c01051e8:	c3                   	ret    

c01051e9 <strncmp>:
 * they are equal to each other, it continues with the following pairs until
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
c01051e9:	55                   	push   %ebp
c01051ea:	89 e5                	mov    %esp,%ebp
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
c01051ec:	eb 0c                	jmp    c01051fa <strncmp+0x11>
        n --, s1 ++, s2 ++;
c01051ee:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
c01051f2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c01051f6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
c01051fa:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01051fe:	74 1a                	je     c010521a <strncmp+0x31>
c0105200:	8b 45 08             	mov    0x8(%ebp),%eax
c0105203:	0f b6 00             	movzbl (%eax),%eax
c0105206:	84 c0                	test   %al,%al
c0105208:	74 10                	je     c010521a <strncmp+0x31>
c010520a:	8b 45 08             	mov    0x8(%ebp),%eax
c010520d:	0f b6 10             	movzbl (%eax),%edx
c0105210:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105213:	0f b6 00             	movzbl (%eax),%eax
c0105216:	38 c2                	cmp    %al,%dl
c0105218:	74 d4                	je     c01051ee <strncmp+0x5>
        n --, s1 ++, s2 ++;
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
c010521a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c010521e:	74 18                	je     c0105238 <strncmp+0x4f>
c0105220:	8b 45 08             	mov    0x8(%ebp),%eax
c0105223:	0f b6 00             	movzbl (%eax),%eax
c0105226:	0f b6 d0             	movzbl %al,%edx
c0105229:	8b 45 0c             	mov    0xc(%ebp),%eax
c010522c:	0f b6 00             	movzbl (%eax),%eax
c010522f:	0f b6 c0             	movzbl %al,%eax
c0105232:	29 c2                	sub    %eax,%edx
c0105234:	89 d0                	mov    %edx,%eax
c0105236:	eb 05                	jmp    c010523d <strncmp+0x54>
c0105238:	b8 00 00 00 00       	mov    $0x0,%eax
}
c010523d:	5d                   	pop    %ebp
c010523e:	c3                   	ret    

c010523f <strchr>:
 *
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
c010523f:	55                   	push   %ebp
c0105240:	89 e5                	mov    %esp,%ebp
c0105242:	83 ec 04             	sub    $0x4,%esp
c0105245:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105248:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
c010524b:	eb 14                	jmp    c0105261 <strchr+0x22>
        if (*s == c) {
c010524d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105250:	0f b6 00             	movzbl (%eax),%eax
c0105253:	3a 45 fc             	cmp    -0x4(%ebp),%al
c0105256:	75 05                	jne    c010525d <strchr+0x1e>
            return (char *)s;
c0105258:	8b 45 08             	mov    0x8(%ebp),%eax
c010525b:	eb 13                	jmp    c0105270 <strchr+0x31>
        }
        s ++;
c010525d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
c0105261:	8b 45 08             	mov    0x8(%ebp),%eax
c0105264:	0f b6 00             	movzbl (%eax),%eax
c0105267:	84 c0                	test   %al,%al
c0105269:	75 e2                	jne    c010524d <strchr+0xe>
        if (*s == c) {
            return (char *)s;
        }
        s ++;
    }
    return NULL;
c010526b:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0105270:	c9                   	leave  
c0105271:	c3                   	ret    

c0105272 <strfind>:
 * The strfind() function is like strchr() except that if @c is
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
c0105272:	55                   	push   %ebp
c0105273:	89 e5                	mov    %esp,%ebp
c0105275:	83 ec 04             	sub    $0x4,%esp
c0105278:	8b 45 0c             	mov    0xc(%ebp),%eax
c010527b:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
c010527e:	eb 0f                	jmp    c010528f <strfind+0x1d>
        if (*s == c) {
c0105280:	8b 45 08             	mov    0x8(%ebp),%eax
c0105283:	0f b6 00             	movzbl (%eax),%eax
c0105286:	3a 45 fc             	cmp    -0x4(%ebp),%al
c0105289:	74 10                	je     c010529b <strfind+0x29>
            break;
        }
        s ++;
c010528b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
    while (*s != '\0') {
c010528f:	8b 45 08             	mov    0x8(%ebp),%eax
c0105292:	0f b6 00             	movzbl (%eax),%eax
c0105295:	84 c0                	test   %al,%al
c0105297:	75 e7                	jne    c0105280 <strfind+0xe>
c0105299:	eb 01                	jmp    c010529c <strfind+0x2a>
        if (*s == c) {
            break;
c010529b:	90                   	nop
        }
        s ++;
    }
    return (char *)s;
c010529c:	8b 45 08             	mov    0x8(%ebp),%eax
}
c010529f:	c9                   	leave  
c01052a0:	c3                   	ret    

c01052a1 <strtol>:
 * an optional "0x" or "0X" prefix.
 *
 * The strtol() function returns the converted integral number as a long int value.
 * */
long
strtol(const char *s, char **endptr, int base) {
c01052a1:	55                   	push   %ebp
c01052a2:	89 e5                	mov    %esp,%ebp
c01052a4:	83 ec 10             	sub    $0x10,%esp
    int neg = 0;
c01052a7:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    long val = 0;
c01052ae:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
c01052b5:	eb 04                	jmp    c01052bb <strtol+0x1a>
        s ++;
c01052b7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
strtol(const char *s, char **endptr, int base) {
    int neg = 0;
    long val = 0;

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
c01052bb:	8b 45 08             	mov    0x8(%ebp),%eax
c01052be:	0f b6 00             	movzbl (%eax),%eax
c01052c1:	3c 20                	cmp    $0x20,%al
c01052c3:	74 f2                	je     c01052b7 <strtol+0x16>
c01052c5:	8b 45 08             	mov    0x8(%ebp),%eax
c01052c8:	0f b6 00             	movzbl (%eax),%eax
c01052cb:	3c 09                	cmp    $0x9,%al
c01052cd:	74 e8                	je     c01052b7 <strtol+0x16>
        s ++;
    }

    // plus/minus sign
    if (*s == '+') {
c01052cf:	8b 45 08             	mov    0x8(%ebp),%eax
c01052d2:	0f b6 00             	movzbl (%eax),%eax
c01052d5:	3c 2b                	cmp    $0x2b,%al
c01052d7:	75 06                	jne    c01052df <strtol+0x3e>
        s ++;
c01052d9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c01052dd:	eb 15                	jmp    c01052f4 <strtol+0x53>
    }
    else if (*s == '-') {
c01052df:	8b 45 08             	mov    0x8(%ebp),%eax
c01052e2:	0f b6 00             	movzbl (%eax),%eax
c01052e5:	3c 2d                	cmp    $0x2d,%al
c01052e7:	75 0b                	jne    c01052f4 <strtol+0x53>
        s ++, neg = 1;
c01052e9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c01052ed:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)
    }

    // hex or octal base prefix
    if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x')) {
c01052f4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01052f8:	74 06                	je     c0105300 <strtol+0x5f>
c01052fa:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
c01052fe:	75 24                	jne    c0105324 <strtol+0x83>
c0105300:	8b 45 08             	mov    0x8(%ebp),%eax
c0105303:	0f b6 00             	movzbl (%eax),%eax
c0105306:	3c 30                	cmp    $0x30,%al
c0105308:	75 1a                	jne    c0105324 <strtol+0x83>
c010530a:	8b 45 08             	mov    0x8(%ebp),%eax
c010530d:	83 c0 01             	add    $0x1,%eax
c0105310:	0f b6 00             	movzbl (%eax),%eax
c0105313:	3c 78                	cmp    $0x78,%al
c0105315:	75 0d                	jne    c0105324 <strtol+0x83>
        s += 2, base = 16;
c0105317:	83 45 08 02          	addl   $0x2,0x8(%ebp)
c010531b:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
c0105322:	eb 2a                	jmp    c010534e <strtol+0xad>
    }
    else if (base == 0 && s[0] == '0') {
c0105324:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0105328:	75 17                	jne    c0105341 <strtol+0xa0>
c010532a:	8b 45 08             	mov    0x8(%ebp),%eax
c010532d:	0f b6 00             	movzbl (%eax),%eax
c0105330:	3c 30                	cmp    $0x30,%al
c0105332:	75 0d                	jne    c0105341 <strtol+0xa0>
        s ++, base = 8;
c0105334:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c0105338:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
c010533f:	eb 0d                	jmp    c010534e <strtol+0xad>
    }
    else if (base == 0) {
c0105341:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0105345:	75 07                	jne    c010534e <strtol+0xad>
        base = 10;
c0105347:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

    // digits
    while (1) {
        int dig;

        if (*s >= '0' && *s <= '9') {
c010534e:	8b 45 08             	mov    0x8(%ebp),%eax
c0105351:	0f b6 00             	movzbl (%eax),%eax
c0105354:	3c 2f                	cmp    $0x2f,%al
c0105356:	7e 1b                	jle    c0105373 <strtol+0xd2>
c0105358:	8b 45 08             	mov    0x8(%ebp),%eax
c010535b:	0f b6 00             	movzbl (%eax),%eax
c010535e:	3c 39                	cmp    $0x39,%al
c0105360:	7f 11                	jg     c0105373 <strtol+0xd2>
            dig = *s - '0';
c0105362:	8b 45 08             	mov    0x8(%ebp),%eax
c0105365:	0f b6 00             	movzbl (%eax),%eax
c0105368:	0f be c0             	movsbl %al,%eax
c010536b:	83 e8 30             	sub    $0x30,%eax
c010536e:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0105371:	eb 48                	jmp    c01053bb <strtol+0x11a>
        }
        else if (*s >= 'a' && *s <= 'z') {
c0105373:	8b 45 08             	mov    0x8(%ebp),%eax
c0105376:	0f b6 00             	movzbl (%eax),%eax
c0105379:	3c 60                	cmp    $0x60,%al
c010537b:	7e 1b                	jle    c0105398 <strtol+0xf7>
c010537d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105380:	0f b6 00             	movzbl (%eax),%eax
c0105383:	3c 7a                	cmp    $0x7a,%al
c0105385:	7f 11                	jg     c0105398 <strtol+0xf7>
            dig = *s - 'a' + 10;
c0105387:	8b 45 08             	mov    0x8(%ebp),%eax
c010538a:	0f b6 00             	movzbl (%eax),%eax
c010538d:	0f be c0             	movsbl %al,%eax
c0105390:	83 e8 57             	sub    $0x57,%eax
c0105393:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0105396:	eb 23                	jmp    c01053bb <strtol+0x11a>
        }
        else if (*s >= 'A' && *s <= 'Z') {
c0105398:	8b 45 08             	mov    0x8(%ebp),%eax
c010539b:	0f b6 00             	movzbl (%eax),%eax
c010539e:	3c 40                	cmp    $0x40,%al
c01053a0:	7e 3c                	jle    c01053de <strtol+0x13d>
c01053a2:	8b 45 08             	mov    0x8(%ebp),%eax
c01053a5:	0f b6 00             	movzbl (%eax),%eax
c01053a8:	3c 5a                	cmp    $0x5a,%al
c01053aa:	7f 32                	jg     c01053de <strtol+0x13d>
            dig = *s - 'A' + 10;
c01053ac:	8b 45 08             	mov    0x8(%ebp),%eax
c01053af:	0f b6 00             	movzbl (%eax),%eax
c01053b2:	0f be c0             	movsbl %al,%eax
c01053b5:	83 e8 37             	sub    $0x37,%eax
c01053b8:	89 45 f4             	mov    %eax,-0xc(%ebp)
        }
        else {
            break;
        }
        if (dig >= base) {
c01053bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01053be:	3b 45 10             	cmp    0x10(%ebp),%eax
c01053c1:	7d 1a                	jge    c01053dd <strtol+0x13c>
            break;
        }
        s ++, val = (val * base) + dig;
c01053c3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
c01053c7:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01053ca:	0f af 45 10          	imul   0x10(%ebp),%eax
c01053ce:	89 c2                	mov    %eax,%edx
c01053d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01053d3:	01 d0                	add    %edx,%eax
c01053d5:	89 45 f8             	mov    %eax,-0x8(%ebp)
        // we don't properly detect overflow!
    }
c01053d8:	e9 71 ff ff ff       	jmp    c010534e <strtol+0xad>
        }
        else {
            break;
        }
        if (dig >= base) {
            break;
c01053dd:	90                   	nop
        }
        s ++, val = (val * base) + dig;
        // we don't properly detect overflow!
    }

    if (endptr) {
c01053de:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c01053e2:	74 08                	je     c01053ec <strtol+0x14b>
        *endptr = (char *) s;
c01053e4:	8b 45 0c             	mov    0xc(%ebp),%eax
c01053e7:	8b 55 08             	mov    0x8(%ebp),%edx
c01053ea:	89 10                	mov    %edx,(%eax)
    }
    return (neg ? -val : val);
c01053ec:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
c01053f0:	74 07                	je     c01053f9 <strtol+0x158>
c01053f2:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01053f5:	f7 d8                	neg    %eax
c01053f7:	eb 03                	jmp    c01053fc <strtol+0x15b>
c01053f9:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
c01053fc:	c9                   	leave  
c01053fd:	c3                   	ret    

c01053fe <memset>:
 * @n:      number of bytes to be set to the value
 *
 * The memset() function returns @s.
 * */
void *
memset(void *s, char c, size_t n) {
c01053fe:	55                   	push   %ebp
c01053ff:	89 e5                	mov    %esp,%ebp
c0105401:	57                   	push   %edi
c0105402:	83 ec 24             	sub    $0x24,%esp
c0105405:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105408:	88 45 d8             	mov    %al,-0x28(%ebp)
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
c010540b:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
c010540f:	8b 55 08             	mov    0x8(%ebp),%edx
c0105412:	89 55 f8             	mov    %edx,-0x8(%ebp)
c0105415:	88 45 f7             	mov    %al,-0x9(%ebp)
c0105418:	8b 45 10             	mov    0x10(%ebp),%eax
c010541b:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_MEMSET
#define __HAVE_ARCH_MEMSET
static inline void *
__memset(void *s, char c, size_t n) {
    int d0, d1;
    asm volatile (
c010541e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
c0105421:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
c0105425:	8b 55 f8             	mov    -0x8(%ebp),%edx
c0105428:	89 d7                	mov    %edx,%edi
c010542a:	f3 aa                	rep stos %al,%es:(%edi)
c010542c:	89 fa                	mov    %edi,%edx
c010542e:	89 4d ec             	mov    %ecx,-0x14(%ebp)
c0105431:	89 55 e8             	mov    %edx,-0x18(%ebp)
        "rep; stosb;"
        : "=&c" (d0), "=&D" (d1)
        : "0" (n), "a" (c), "1" (s)
        : "memory");
    return s;
c0105434:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0105437:	90                   	nop
    while (n -- > 0) {
        *p ++ = c;
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
c0105438:	83 c4 24             	add    $0x24,%esp
c010543b:	5f                   	pop    %edi
c010543c:	5d                   	pop    %ebp
c010543d:	c3                   	ret    

c010543e <memmove>:
 * @n:      number of bytes to copy
 *
 * The memmove() function returns @dst.
 * */
void *
memmove(void *dst, const void *src, size_t n) {
c010543e:	55                   	push   %ebp
c010543f:	89 e5                	mov    %esp,%ebp
c0105441:	57                   	push   %edi
c0105442:	56                   	push   %esi
c0105443:	53                   	push   %ebx
c0105444:	83 ec 30             	sub    $0x30,%esp
c0105447:	8b 45 08             	mov    0x8(%ebp),%eax
c010544a:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010544d:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105450:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0105453:	8b 45 10             	mov    0x10(%ebp),%eax
c0105456:	89 45 e8             	mov    %eax,-0x18(%ebp)

#ifndef __HAVE_ARCH_MEMMOVE
#define __HAVE_ARCH_MEMMOVE
static inline void *
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
c0105459:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010545c:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c010545f:	73 42                	jae    c01054a3 <memmove+0x65>
c0105461:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105464:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0105467:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010546a:	89 45 e0             	mov    %eax,-0x20(%ebp)
c010546d:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105470:	89 45 dc             	mov    %eax,-0x24(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
c0105473:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105476:	c1 e8 02             	shr    $0x2,%eax
c0105479:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
c010547b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c010547e:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105481:	89 d7                	mov    %edx,%edi
c0105483:	89 c6                	mov    %eax,%esi
c0105485:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
c0105487:	8b 4d dc             	mov    -0x24(%ebp),%ecx
c010548a:	83 e1 03             	and    $0x3,%ecx
c010548d:	74 02                	je     c0105491 <memmove+0x53>
c010548f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c0105491:	89 f0                	mov    %esi,%eax
c0105493:	89 fa                	mov    %edi,%edx
c0105495:	89 4d d8             	mov    %ecx,-0x28(%ebp)
c0105498:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c010549b:	89 45 d0             	mov    %eax,-0x30(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
c010549e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
#ifdef __HAVE_ARCH_MEMMOVE
    return __memmove(dst, src, n);
c01054a1:	eb 36                	jmp    c01054d9 <memmove+0x9b>
    asm volatile (
        "std;"
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
c01054a3:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01054a6:	8d 50 ff             	lea    -0x1(%eax),%edx
c01054a9:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01054ac:	01 c2                	add    %eax,%edx
c01054ae:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01054b1:	8d 48 ff             	lea    -0x1(%eax),%ecx
c01054b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01054b7:	8d 1c 01             	lea    (%ecx,%eax,1),%ebx
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
        return __memcpy(dst, src, n);
    }
    int d0, d1, d2;
    asm volatile (
c01054ba:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01054bd:	89 c1                	mov    %eax,%ecx
c01054bf:	89 d8                	mov    %ebx,%eax
c01054c1:	89 d6                	mov    %edx,%esi
c01054c3:	89 c7                	mov    %eax,%edi
c01054c5:	fd                   	std    
c01054c6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c01054c8:	fc                   	cld    
c01054c9:	89 f8                	mov    %edi,%eax
c01054cb:	89 f2                	mov    %esi,%edx
c01054cd:	89 4d cc             	mov    %ecx,-0x34(%ebp)
c01054d0:	89 55 c8             	mov    %edx,-0x38(%ebp)
c01054d3:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        "rep; movsb;"
        "cld;"
        : "=&c" (d0), "=&S" (d1), "=&D" (d2)
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
        : "memory");
    return dst;
c01054d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
            *d ++ = *s ++;
        }
    }
    return dst;
#endif /* __HAVE_ARCH_MEMMOVE */
}
c01054d9:	83 c4 30             	add    $0x30,%esp
c01054dc:	5b                   	pop    %ebx
c01054dd:	5e                   	pop    %esi
c01054de:	5f                   	pop    %edi
c01054df:	5d                   	pop    %ebp
c01054e0:	c3                   	ret    

c01054e1 <memcpy>:
 * it always copies exactly @n bytes. To avoid overflows, the size of arrays pointed
 * by both @src and @dst, should be at least @n bytes, and should not overlap
 * (for overlapping memory area, memmove is a safer approach).
 * */
void *
memcpy(void *dst, const void *src, size_t n) {
c01054e1:	55                   	push   %ebp
c01054e2:	89 e5                	mov    %esp,%ebp
c01054e4:	57                   	push   %edi
c01054e5:	56                   	push   %esi
c01054e6:	83 ec 20             	sub    $0x20,%esp
c01054e9:	8b 45 08             	mov    0x8(%ebp),%eax
c01054ec:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01054ef:	8b 45 0c             	mov    0xc(%ebp),%eax
c01054f2:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01054f5:	8b 45 10             	mov    0x10(%ebp),%eax
c01054f8:	89 45 ec             	mov    %eax,-0x14(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
c01054fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01054fe:	c1 e8 02             	shr    $0x2,%eax
c0105501:	89 c1                	mov    %eax,%ecx
#ifndef __HAVE_ARCH_MEMCPY
#define __HAVE_ARCH_MEMCPY
static inline void *
__memcpy(void *dst, const void *src, size_t n) {
    int d0, d1, d2;
    asm volatile (
c0105503:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105506:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105509:	89 d7                	mov    %edx,%edi
c010550b:	89 c6                	mov    %eax,%esi
c010550d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
c010550f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
c0105512:	83 e1 03             	and    $0x3,%ecx
c0105515:	74 02                	je     c0105519 <memcpy+0x38>
c0105517:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c0105519:	89 f0                	mov    %esi,%eax
c010551b:	89 fa                	mov    %edi,%edx
c010551d:	89 4d e8             	mov    %ecx,-0x18(%ebp)
c0105520:	89 55 e4             	mov    %edx,-0x1c(%ebp)
c0105523:	89 45 e0             	mov    %eax,-0x20(%ebp)
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
        : "memory");
    return dst;
c0105526:	8b 45 f4             	mov    -0xc(%ebp),%eax
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
c0105529:	90                   	nop
    while (n -- > 0) {
        *d ++ = *s ++;
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
c010552a:	83 c4 20             	add    $0x20,%esp
c010552d:	5e                   	pop    %esi
c010552e:	5f                   	pop    %edi
c010552f:	5d                   	pop    %ebp
c0105530:	c3                   	ret    

c0105531 <memcmp>:
 *   match in both memory blocks has a greater value in @v1 than in @v2
 *   as if evaluated as unsigned char values;
 * - And a value less than zero indicates the opposite.
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
c0105531:	55                   	push   %ebp
c0105532:	89 e5                	mov    %esp,%ebp
c0105534:	83 ec 10             	sub    $0x10,%esp
    const char *s1 = (const char *)v1;
c0105537:	8b 45 08             	mov    0x8(%ebp),%eax
c010553a:	89 45 fc             	mov    %eax,-0x4(%ebp)
    const char *s2 = (const char *)v2;
c010553d:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105540:	89 45 f8             	mov    %eax,-0x8(%ebp)
    while (n -- > 0) {
c0105543:	eb 30                	jmp    c0105575 <memcmp+0x44>
        if (*s1 != *s2) {
c0105545:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0105548:	0f b6 10             	movzbl (%eax),%edx
c010554b:	8b 45 f8             	mov    -0x8(%ebp),%eax
c010554e:	0f b6 00             	movzbl (%eax),%eax
c0105551:	38 c2                	cmp    %al,%dl
c0105553:	74 18                	je     c010556d <memcmp+0x3c>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
c0105555:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0105558:	0f b6 00             	movzbl (%eax),%eax
c010555b:	0f b6 d0             	movzbl %al,%edx
c010555e:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0105561:	0f b6 00             	movzbl (%eax),%eax
c0105564:	0f b6 c0             	movzbl %al,%eax
c0105567:	29 c2                	sub    %eax,%edx
c0105569:	89 d0                	mov    %edx,%eax
c010556b:	eb 1a                	jmp    c0105587 <memcmp+0x56>
        }
        s1 ++, s2 ++;
c010556d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
c0105571:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
c0105575:	8b 45 10             	mov    0x10(%ebp),%eax
c0105578:	8d 50 ff             	lea    -0x1(%eax),%edx
c010557b:	89 55 10             	mov    %edx,0x10(%ebp)
c010557e:	85 c0                	test   %eax,%eax
c0105580:	75 c3                	jne    c0105545 <memcmp+0x14>
        if (*s1 != *s2) {
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
    }
    return 0;
c0105582:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0105587:	c9                   	leave  
c0105588:	c3                   	ret    

c0105589 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
c0105589:	55                   	push   %ebp
c010558a:	89 e5                	mov    %esp,%ebp
c010558c:	83 ec 38             	sub    $0x38,%esp
c010558f:	8b 45 10             	mov    0x10(%ebp),%eax
c0105592:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0105595:	8b 45 14             	mov    0x14(%ebp),%eax
c0105598:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    unsigned long long result = num;
c010559b:	8b 45 d0             	mov    -0x30(%ebp),%eax
c010559e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01055a1:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01055a4:	89 55 ec             	mov    %edx,-0x14(%ebp)
    unsigned mod = do_div(result, base);
c01055a7:	8b 45 18             	mov    0x18(%ebp),%eax
c01055aa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c01055ad:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01055b0:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01055b3:	89 45 e0             	mov    %eax,-0x20(%ebp)
c01055b6:	89 55 f0             	mov    %edx,-0x10(%ebp)
c01055b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01055bc:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01055bf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c01055c3:	74 1c                	je     c01055e1 <printnum+0x58>
c01055c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01055c8:	ba 00 00 00 00       	mov    $0x0,%edx
c01055cd:	f7 75 e4             	divl   -0x1c(%ebp)
c01055d0:	89 55 f4             	mov    %edx,-0xc(%ebp)
c01055d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01055d6:	ba 00 00 00 00       	mov    $0x0,%edx
c01055db:	f7 75 e4             	divl   -0x1c(%ebp)
c01055de:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01055e1:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01055e4:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01055e7:	f7 75 e4             	divl   -0x1c(%ebp)
c01055ea:	89 45 e0             	mov    %eax,-0x20(%ebp)
c01055ed:	89 55 dc             	mov    %edx,-0x24(%ebp)
c01055f0:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01055f3:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01055f6:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01055f9:	89 55 ec             	mov    %edx,-0x14(%ebp)
c01055fc:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01055ff:	89 45 d8             	mov    %eax,-0x28(%ebp)

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
c0105602:	8b 45 18             	mov    0x18(%ebp),%eax
c0105605:	ba 00 00 00 00       	mov    $0x0,%edx
c010560a:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c010560d:	77 41                	ja     c0105650 <printnum+0xc7>
c010560f:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
c0105612:	72 05                	jb     c0105619 <printnum+0x90>
c0105614:	3b 45 d0             	cmp    -0x30(%ebp),%eax
c0105617:	77 37                	ja     c0105650 <printnum+0xc7>
        printnum(putch, putdat, result, base, width - 1, padc);
c0105619:	8b 45 1c             	mov    0x1c(%ebp),%eax
c010561c:	83 e8 01             	sub    $0x1,%eax
c010561f:	83 ec 04             	sub    $0x4,%esp
c0105622:	ff 75 20             	pushl  0x20(%ebp)
c0105625:	50                   	push   %eax
c0105626:	ff 75 18             	pushl  0x18(%ebp)
c0105629:	ff 75 ec             	pushl  -0x14(%ebp)
c010562c:	ff 75 e8             	pushl  -0x18(%ebp)
c010562f:	ff 75 0c             	pushl  0xc(%ebp)
c0105632:	ff 75 08             	pushl  0x8(%ebp)
c0105635:	e8 4f ff ff ff       	call   c0105589 <printnum>
c010563a:	83 c4 20             	add    $0x20,%esp
c010563d:	eb 1b                	jmp    c010565a <printnum+0xd1>
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
            putch(padc, putdat);
c010563f:	83 ec 08             	sub    $0x8,%esp
c0105642:	ff 75 0c             	pushl  0xc(%ebp)
c0105645:	ff 75 20             	pushl  0x20(%ebp)
c0105648:	8b 45 08             	mov    0x8(%ebp),%eax
c010564b:	ff d0                	call   *%eax
c010564d:	83 c4 10             	add    $0x10,%esp
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
c0105650:	83 6d 1c 01          	subl   $0x1,0x1c(%ebp)
c0105654:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
c0105658:	7f e5                	jg     c010563f <printnum+0xb6>
            putch(padc, putdat);
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
c010565a:	8b 45 d8             	mov    -0x28(%ebp),%eax
c010565d:	05 b0 6d 10 c0       	add    $0xc0106db0,%eax
c0105662:	0f b6 00             	movzbl (%eax),%eax
c0105665:	0f be c0             	movsbl %al,%eax
c0105668:	83 ec 08             	sub    $0x8,%esp
c010566b:	ff 75 0c             	pushl  0xc(%ebp)
c010566e:	50                   	push   %eax
c010566f:	8b 45 08             	mov    0x8(%ebp),%eax
c0105672:	ff d0                	call   *%eax
c0105674:	83 c4 10             	add    $0x10,%esp
}
c0105677:	90                   	nop
c0105678:	c9                   	leave  
c0105679:	c3                   	ret    

c010567a <getuint>:
 * getuint - get an unsigned int of various possible sizes from a varargs list
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static unsigned long long
getuint(va_list *ap, int lflag) {
c010567a:	55                   	push   %ebp
c010567b:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
c010567d:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
c0105681:	7e 14                	jle    c0105697 <getuint+0x1d>
        return va_arg(*ap, unsigned long long);
c0105683:	8b 45 08             	mov    0x8(%ebp),%eax
c0105686:	8b 00                	mov    (%eax),%eax
c0105688:	8d 48 08             	lea    0x8(%eax),%ecx
c010568b:	8b 55 08             	mov    0x8(%ebp),%edx
c010568e:	89 0a                	mov    %ecx,(%edx)
c0105690:	8b 50 04             	mov    0x4(%eax),%edx
c0105693:	8b 00                	mov    (%eax),%eax
c0105695:	eb 30                	jmp    c01056c7 <getuint+0x4d>
    }
    else if (lflag) {
c0105697:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c010569b:	74 16                	je     c01056b3 <getuint+0x39>
        return va_arg(*ap, unsigned long);
c010569d:	8b 45 08             	mov    0x8(%ebp),%eax
c01056a0:	8b 00                	mov    (%eax),%eax
c01056a2:	8d 48 04             	lea    0x4(%eax),%ecx
c01056a5:	8b 55 08             	mov    0x8(%ebp),%edx
c01056a8:	89 0a                	mov    %ecx,(%edx)
c01056aa:	8b 00                	mov    (%eax),%eax
c01056ac:	ba 00 00 00 00       	mov    $0x0,%edx
c01056b1:	eb 14                	jmp    c01056c7 <getuint+0x4d>
    }
    else {
        return va_arg(*ap, unsigned int);
c01056b3:	8b 45 08             	mov    0x8(%ebp),%eax
c01056b6:	8b 00                	mov    (%eax),%eax
c01056b8:	8d 48 04             	lea    0x4(%eax),%ecx
c01056bb:	8b 55 08             	mov    0x8(%ebp),%edx
c01056be:	89 0a                	mov    %ecx,(%edx)
c01056c0:	8b 00                	mov    (%eax),%eax
c01056c2:	ba 00 00 00 00       	mov    $0x0,%edx
    }
}
c01056c7:	5d                   	pop    %ebp
c01056c8:	c3                   	ret    

c01056c9 <getint>:
 * getint - same as getuint but signed, we can't use getuint because of sign extension
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static long long
getint(va_list *ap, int lflag) {
c01056c9:	55                   	push   %ebp
c01056ca:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
c01056cc:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
c01056d0:	7e 14                	jle    c01056e6 <getint+0x1d>
        return va_arg(*ap, long long);
c01056d2:	8b 45 08             	mov    0x8(%ebp),%eax
c01056d5:	8b 00                	mov    (%eax),%eax
c01056d7:	8d 48 08             	lea    0x8(%eax),%ecx
c01056da:	8b 55 08             	mov    0x8(%ebp),%edx
c01056dd:	89 0a                	mov    %ecx,(%edx)
c01056df:	8b 50 04             	mov    0x4(%eax),%edx
c01056e2:	8b 00                	mov    (%eax),%eax
c01056e4:	eb 28                	jmp    c010570e <getint+0x45>
    }
    else if (lflag) {
c01056e6:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c01056ea:	74 12                	je     c01056fe <getint+0x35>
        return va_arg(*ap, long);
c01056ec:	8b 45 08             	mov    0x8(%ebp),%eax
c01056ef:	8b 00                	mov    (%eax),%eax
c01056f1:	8d 48 04             	lea    0x4(%eax),%ecx
c01056f4:	8b 55 08             	mov    0x8(%ebp),%edx
c01056f7:	89 0a                	mov    %ecx,(%edx)
c01056f9:	8b 00                	mov    (%eax),%eax
c01056fb:	99                   	cltd   
c01056fc:	eb 10                	jmp    c010570e <getint+0x45>
    }
    else {
        return va_arg(*ap, int);
c01056fe:	8b 45 08             	mov    0x8(%ebp),%eax
c0105701:	8b 00                	mov    (%eax),%eax
c0105703:	8d 48 04             	lea    0x4(%eax),%ecx
c0105706:	8b 55 08             	mov    0x8(%ebp),%edx
c0105709:	89 0a                	mov    %ecx,(%edx)
c010570b:	8b 00                	mov    (%eax),%eax
c010570d:	99                   	cltd   
    }
}
c010570e:	5d                   	pop    %ebp
c010570f:	c3                   	ret    

c0105710 <printfmt>:
 * @putch:      specified putch function, print a single character
 * @putdat:     used by @putch function
 * @fmt:        the format string to use
 * */
void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
c0105710:	55                   	push   %ebp
c0105711:	89 e5                	mov    %esp,%ebp
c0105713:	83 ec 18             	sub    $0x18,%esp
    va_list ap;

    va_start(ap, fmt);
c0105716:	8d 45 14             	lea    0x14(%ebp),%eax
c0105719:	89 45 f4             	mov    %eax,-0xc(%ebp)
    vprintfmt(putch, putdat, fmt, ap);
c010571c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010571f:	50                   	push   %eax
c0105720:	ff 75 10             	pushl  0x10(%ebp)
c0105723:	ff 75 0c             	pushl  0xc(%ebp)
c0105726:	ff 75 08             	pushl  0x8(%ebp)
c0105729:	e8 06 00 00 00       	call   c0105734 <vprintfmt>
c010572e:	83 c4 10             	add    $0x10,%esp
    va_end(ap);
}
c0105731:	90                   	nop
c0105732:	c9                   	leave  
c0105733:	c3                   	ret    

c0105734 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
c0105734:	55                   	push   %ebp
c0105735:	89 e5                	mov    %esp,%ebp
c0105737:	56                   	push   %esi
c0105738:	53                   	push   %ebx
c0105739:	83 ec 20             	sub    $0x20,%esp
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
c010573c:	eb 17                	jmp    c0105755 <vprintfmt+0x21>
            if (ch == '\0') {
c010573e:	85 db                	test   %ebx,%ebx
c0105740:	0f 84 8e 03 00 00    	je     c0105ad4 <vprintfmt+0x3a0>
                return;
            }
            putch(ch, putdat);
c0105746:	83 ec 08             	sub    $0x8,%esp
c0105749:	ff 75 0c             	pushl  0xc(%ebp)
c010574c:	53                   	push   %ebx
c010574d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105750:	ff d0                	call   *%eax
c0105752:	83 c4 10             	add    $0x10,%esp
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
c0105755:	8b 45 10             	mov    0x10(%ebp),%eax
c0105758:	8d 50 01             	lea    0x1(%eax),%edx
c010575b:	89 55 10             	mov    %edx,0x10(%ebp)
c010575e:	0f b6 00             	movzbl (%eax),%eax
c0105761:	0f b6 d8             	movzbl %al,%ebx
c0105764:	83 fb 25             	cmp    $0x25,%ebx
c0105767:	75 d5                	jne    c010573e <vprintfmt+0xa>
            }
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
c0105769:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
        width = precision = -1;
c010576d:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
c0105774:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105777:	89 45 e8             	mov    %eax,-0x18(%ebp)
        lflag = altflag = 0;
c010577a:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0105781:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105784:	89 45 e0             	mov    %eax,-0x20(%ebp)

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
c0105787:	8b 45 10             	mov    0x10(%ebp),%eax
c010578a:	8d 50 01             	lea    0x1(%eax),%edx
c010578d:	89 55 10             	mov    %edx,0x10(%ebp)
c0105790:	0f b6 00             	movzbl (%eax),%eax
c0105793:	0f b6 d8             	movzbl %al,%ebx
c0105796:	8d 43 dd             	lea    -0x23(%ebx),%eax
c0105799:	83 f8 55             	cmp    $0x55,%eax
c010579c:	0f 87 05 03 00 00    	ja     c0105aa7 <vprintfmt+0x373>
c01057a2:	8b 04 85 d4 6d 10 c0 	mov    -0x3fef922c(,%eax,4),%eax
c01057a9:	ff e0                	jmp    *%eax

        // flag to pad on the right
        case '-':
            padc = '-';
c01057ab:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
            goto reswitch;
c01057af:	eb d6                	jmp    c0105787 <vprintfmt+0x53>

        // flag to pad with 0's instead of spaces
        case '0':
            padc = '0';
c01057b1:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
            goto reswitch;
c01057b5:	eb d0                	jmp    c0105787 <vprintfmt+0x53>

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
c01057b7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
                precision = precision * 10 + ch - '0';
c01057be:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01057c1:	89 d0                	mov    %edx,%eax
c01057c3:	c1 e0 02             	shl    $0x2,%eax
c01057c6:	01 d0                	add    %edx,%eax
c01057c8:	01 c0                	add    %eax,%eax
c01057ca:	01 d8                	add    %ebx,%eax
c01057cc:	83 e8 30             	sub    $0x30,%eax
c01057cf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
                ch = *fmt;
c01057d2:	8b 45 10             	mov    0x10(%ebp),%eax
c01057d5:	0f b6 00             	movzbl (%eax),%eax
c01057d8:	0f be d8             	movsbl %al,%ebx
                if (ch < '0' || ch > '9') {
c01057db:	83 fb 2f             	cmp    $0x2f,%ebx
c01057de:	7e 39                	jle    c0105819 <vprintfmt+0xe5>
c01057e0:	83 fb 39             	cmp    $0x39,%ebx
c01057e3:	7f 34                	jg     c0105819 <vprintfmt+0xe5>
            padc = '0';
            goto reswitch;

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
c01057e5:	83 45 10 01          	addl   $0x1,0x10(%ebp)
                precision = precision * 10 + ch - '0';
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
c01057e9:	eb d3                	jmp    c01057be <vprintfmt+0x8a>
            goto process_precision;

        case '*':
            precision = va_arg(ap, int);
c01057eb:	8b 45 14             	mov    0x14(%ebp),%eax
c01057ee:	8d 50 04             	lea    0x4(%eax),%edx
c01057f1:	89 55 14             	mov    %edx,0x14(%ebp)
c01057f4:	8b 00                	mov    (%eax),%eax
c01057f6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            goto process_precision;
c01057f9:	eb 1f                	jmp    c010581a <vprintfmt+0xe6>

        case '.':
            if (width < 0)
c01057fb:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c01057ff:	79 86                	jns    c0105787 <vprintfmt+0x53>
                width = 0;
c0105801:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
            goto reswitch;
c0105808:	e9 7a ff ff ff       	jmp    c0105787 <vprintfmt+0x53>

        case '#':
            altflag = 1;
c010580d:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
            goto reswitch;
c0105814:	e9 6e ff ff ff       	jmp    c0105787 <vprintfmt+0x53>
                ch = *fmt;
                if (ch < '0' || ch > '9') {
                    break;
                }
            }
            goto process_precision;
c0105819:	90                   	nop
        case '#':
            altflag = 1;
            goto reswitch;

        process_precision:
            if (width < 0)
c010581a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c010581e:	0f 89 63 ff ff ff    	jns    c0105787 <vprintfmt+0x53>
                width = precision, precision = -1;
c0105824:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105827:	89 45 e8             	mov    %eax,-0x18(%ebp)
c010582a:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
            goto reswitch;
c0105831:	e9 51 ff ff ff       	jmp    c0105787 <vprintfmt+0x53>

        // long flag (doubled for long long)
        case 'l':
            lflag ++;
c0105836:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
            goto reswitch;
c010583a:	e9 48 ff ff ff       	jmp    c0105787 <vprintfmt+0x53>

        // character
        case 'c':
            putch(va_arg(ap, int), putdat);
c010583f:	8b 45 14             	mov    0x14(%ebp),%eax
c0105842:	8d 50 04             	lea    0x4(%eax),%edx
c0105845:	89 55 14             	mov    %edx,0x14(%ebp)
c0105848:	8b 00                	mov    (%eax),%eax
c010584a:	83 ec 08             	sub    $0x8,%esp
c010584d:	ff 75 0c             	pushl  0xc(%ebp)
c0105850:	50                   	push   %eax
c0105851:	8b 45 08             	mov    0x8(%ebp),%eax
c0105854:	ff d0                	call   *%eax
c0105856:	83 c4 10             	add    $0x10,%esp
            break;
c0105859:	e9 71 02 00 00       	jmp    c0105acf <vprintfmt+0x39b>

        // error message
        case 'e':
            err = va_arg(ap, int);
c010585e:	8b 45 14             	mov    0x14(%ebp),%eax
c0105861:	8d 50 04             	lea    0x4(%eax),%edx
c0105864:	89 55 14             	mov    %edx,0x14(%ebp)
c0105867:	8b 18                	mov    (%eax),%ebx
            if (err < 0) {
c0105869:	85 db                	test   %ebx,%ebx
c010586b:	79 02                	jns    c010586f <vprintfmt+0x13b>
                err = -err;
c010586d:	f7 db                	neg    %ebx
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
c010586f:	83 fb 06             	cmp    $0x6,%ebx
c0105872:	7f 0b                	jg     c010587f <vprintfmt+0x14b>
c0105874:	8b 34 9d 94 6d 10 c0 	mov    -0x3fef926c(,%ebx,4),%esi
c010587b:	85 f6                	test   %esi,%esi
c010587d:	75 19                	jne    c0105898 <vprintfmt+0x164>
                printfmt(putch, putdat, "error %d", err);
c010587f:	53                   	push   %ebx
c0105880:	68 c1 6d 10 c0       	push   $0xc0106dc1
c0105885:	ff 75 0c             	pushl  0xc(%ebp)
c0105888:	ff 75 08             	pushl  0x8(%ebp)
c010588b:	e8 80 fe ff ff       	call   c0105710 <printfmt>
c0105890:	83 c4 10             	add    $0x10,%esp
            }
            else {
                printfmt(putch, putdat, "%s", p);
            }
            break;
c0105893:	e9 37 02 00 00       	jmp    c0105acf <vprintfmt+0x39b>
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
                printfmt(putch, putdat, "error %d", err);
            }
            else {
                printfmt(putch, putdat, "%s", p);
c0105898:	56                   	push   %esi
c0105899:	68 ca 6d 10 c0       	push   $0xc0106dca
c010589e:	ff 75 0c             	pushl  0xc(%ebp)
c01058a1:	ff 75 08             	pushl  0x8(%ebp)
c01058a4:	e8 67 fe ff ff       	call   c0105710 <printfmt>
c01058a9:	83 c4 10             	add    $0x10,%esp
            }
            break;
c01058ac:	e9 1e 02 00 00       	jmp    c0105acf <vprintfmt+0x39b>

        // string
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
c01058b1:	8b 45 14             	mov    0x14(%ebp),%eax
c01058b4:	8d 50 04             	lea    0x4(%eax),%edx
c01058b7:	89 55 14             	mov    %edx,0x14(%ebp)
c01058ba:	8b 30                	mov    (%eax),%esi
c01058bc:	85 f6                	test   %esi,%esi
c01058be:	75 05                	jne    c01058c5 <vprintfmt+0x191>
                p = "(null)";
c01058c0:	be cd 6d 10 c0       	mov    $0xc0106dcd,%esi
            }
            if (width > 0 && padc != '-') {
c01058c5:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c01058c9:	7e 76                	jle    c0105941 <vprintfmt+0x20d>
c01058cb:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
c01058cf:	74 70                	je     c0105941 <vprintfmt+0x20d>
                for (width -= strnlen(p, precision); width > 0; width --) {
c01058d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01058d4:	83 ec 08             	sub    $0x8,%esp
c01058d7:	50                   	push   %eax
c01058d8:	56                   	push   %esi
c01058d9:	e8 17 f8 ff ff       	call   c01050f5 <strnlen>
c01058de:	83 c4 10             	add    $0x10,%esp
c01058e1:	89 c2                	mov    %eax,%edx
c01058e3:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01058e6:	29 d0                	sub    %edx,%eax
c01058e8:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01058eb:	eb 17                	jmp    c0105904 <vprintfmt+0x1d0>
                    putch(padc, putdat);
c01058ed:	0f be 45 db          	movsbl -0x25(%ebp),%eax
c01058f1:	83 ec 08             	sub    $0x8,%esp
c01058f4:	ff 75 0c             	pushl  0xc(%ebp)
c01058f7:	50                   	push   %eax
c01058f8:	8b 45 08             	mov    0x8(%ebp),%eax
c01058fb:	ff d0                	call   *%eax
c01058fd:	83 c4 10             	add    $0x10,%esp
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
                p = "(null)";
            }
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
c0105900:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
c0105904:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0105908:	7f e3                	jg     c01058ed <vprintfmt+0x1b9>
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
c010590a:	eb 35                	jmp    c0105941 <vprintfmt+0x20d>
                if (altflag && (ch < ' ' || ch > '~')) {
c010590c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c0105910:	74 1c                	je     c010592e <vprintfmt+0x1fa>
c0105912:	83 fb 1f             	cmp    $0x1f,%ebx
c0105915:	7e 05                	jle    c010591c <vprintfmt+0x1e8>
c0105917:	83 fb 7e             	cmp    $0x7e,%ebx
c010591a:	7e 12                	jle    c010592e <vprintfmt+0x1fa>
                    putch('?', putdat);
c010591c:	83 ec 08             	sub    $0x8,%esp
c010591f:	ff 75 0c             	pushl  0xc(%ebp)
c0105922:	6a 3f                	push   $0x3f
c0105924:	8b 45 08             	mov    0x8(%ebp),%eax
c0105927:	ff d0                	call   *%eax
c0105929:	83 c4 10             	add    $0x10,%esp
c010592c:	eb 0f                	jmp    c010593d <vprintfmt+0x209>
                }
                else {
                    putch(ch, putdat);
c010592e:	83 ec 08             	sub    $0x8,%esp
c0105931:	ff 75 0c             	pushl  0xc(%ebp)
c0105934:	53                   	push   %ebx
c0105935:	8b 45 08             	mov    0x8(%ebp),%eax
c0105938:	ff d0                	call   *%eax
c010593a:	83 c4 10             	add    $0x10,%esp
            if (width > 0 && padc != '-') {
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
c010593d:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
c0105941:	89 f0                	mov    %esi,%eax
c0105943:	8d 70 01             	lea    0x1(%eax),%esi
c0105946:	0f b6 00             	movzbl (%eax),%eax
c0105949:	0f be d8             	movsbl %al,%ebx
c010594c:	85 db                	test   %ebx,%ebx
c010594e:	74 26                	je     c0105976 <vprintfmt+0x242>
c0105950:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0105954:	78 b6                	js     c010590c <vprintfmt+0x1d8>
c0105956:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
c010595a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c010595e:	79 ac                	jns    c010590c <vprintfmt+0x1d8>
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
c0105960:	eb 14                	jmp    c0105976 <vprintfmt+0x242>
                putch(' ', putdat);
c0105962:	83 ec 08             	sub    $0x8,%esp
c0105965:	ff 75 0c             	pushl  0xc(%ebp)
c0105968:	6a 20                	push   $0x20
c010596a:	8b 45 08             	mov    0x8(%ebp),%eax
c010596d:	ff d0                	call   *%eax
c010596f:	83 c4 10             	add    $0x10,%esp
                }
                else {
                    putch(ch, putdat);
                }
            }
            for (; width > 0; width --) {
c0105972:	83 6d e8 01          	subl   $0x1,-0x18(%ebp)
c0105976:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c010597a:	7f e6                	jg     c0105962 <vprintfmt+0x22e>
                putch(' ', putdat);
            }
            break;
c010597c:	e9 4e 01 00 00       	jmp    c0105acf <vprintfmt+0x39b>

        // (signed) decimal
        case 'd':
            num = getint(&ap, lflag);
c0105981:	83 ec 08             	sub    $0x8,%esp
c0105984:	ff 75 e0             	pushl  -0x20(%ebp)
c0105987:	8d 45 14             	lea    0x14(%ebp),%eax
c010598a:	50                   	push   %eax
c010598b:	e8 39 fd ff ff       	call   c01056c9 <getint>
c0105990:	83 c4 10             	add    $0x10,%esp
c0105993:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105996:	89 55 f4             	mov    %edx,-0xc(%ebp)
            if ((long long)num < 0) {
c0105999:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010599c:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010599f:	85 d2                	test   %edx,%edx
c01059a1:	79 23                	jns    c01059c6 <vprintfmt+0x292>
                putch('-', putdat);
c01059a3:	83 ec 08             	sub    $0x8,%esp
c01059a6:	ff 75 0c             	pushl  0xc(%ebp)
c01059a9:	6a 2d                	push   $0x2d
c01059ab:	8b 45 08             	mov    0x8(%ebp),%eax
c01059ae:	ff d0                	call   *%eax
c01059b0:	83 c4 10             	add    $0x10,%esp
                num = -(long long)num;
c01059b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01059b6:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01059b9:	f7 d8                	neg    %eax
c01059bb:	83 d2 00             	adc    $0x0,%edx
c01059be:	f7 da                	neg    %edx
c01059c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01059c3:	89 55 f4             	mov    %edx,-0xc(%ebp)
            }
            base = 10;
c01059c6:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
c01059cd:	e9 9f 00 00 00       	jmp    c0105a71 <vprintfmt+0x33d>

        // unsigned decimal
        case 'u':
            num = getuint(&ap, lflag);
c01059d2:	83 ec 08             	sub    $0x8,%esp
c01059d5:	ff 75 e0             	pushl  -0x20(%ebp)
c01059d8:	8d 45 14             	lea    0x14(%ebp),%eax
c01059db:	50                   	push   %eax
c01059dc:	e8 99 fc ff ff       	call   c010567a <getuint>
c01059e1:	83 c4 10             	add    $0x10,%esp
c01059e4:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01059e7:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 10;
c01059ea:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
c01059f1:	eb 7e                	jmp    c0105a71 <vprintfmt+0x33d>

        // (unsigned) octal
        case 'o':
            num = getuint(&ap, lflag);
c01059f3:	83 ec 08             	sub    $0x8,%esp
c01059f6:	ff 75 e0             	pushl  -0x20(%ebp)
c01059f9:	8d 45 14             	lea    0x14(%ebp),%eax
c01059fc:	50                   	push   %eax
c01059fd:	e8 78 fc ff ff       	call   c010567a <getuint>
c0105a02:	83 c4 10             	add    $0x10,%esp
c0105a05:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105a08:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 8;
c0105a0b:	c7 45 ec 08 00 00 00 	movl   $0x8,-0x14(%ebp)
            goto number;
c0105a12:	eb 5d                	jmp    c0105a71 <vprintfmt+0x33d>

        // pointer
        case 'p':
            putch('0', putdat);
c0105a14:	83 ec 08             	sub    $0x8,%esp
c0105a17:	ff 75 0c             	pushl  0xc(%ebp)
c0105a1a:	6a 30                	push   $0x30
c0105a1c:	8b 45 08             	mov    0x8(%ebp),%eax
c0105a1f:	ff d0                	call   *%eax
c0105a21:	83 c4 10             	add    $0x10,%esp
            putch('x', putdat);
c0105a24:	83 ec 08             	sub    $0x8,%esp
c0105a27:	ff 75 0c             	pushl  0xc(%ebp)
c0105a2a:	6a 78                	push   $0x78
c0105a2c:	8b 45 08             	mov    0x8(%ebp),%eax
c0105a2f:	ff d0                	call   *%eax
c0105a31:	83 c4 10             	add    $0x10,%esp
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
c0105a34:	8b 45 14             	mov    0x14(%ebp),%eax
c0105a37:	8d 50 04             	lea    0x4(%eax),%edx
c0105a3a:	89 55 14             	mov    %edx,0x14(%ebp)
c0105a3d:	8b 00                	mov    (%eax),%eax
c0105a3f:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105a42:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
            base = 16;
c0105a49:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
            goto number;
c0105a50:	eb 1f                	jmp    c0105a71 <vprintfmt+0x33d>

        // (unsigned) hexadecimal
        case 'x':
            num = getuint(&ap, lflag);
c0105a52:	83 ec 08             	sub    $0x8,%esp
c0105a55:	ff 75 e0             	pushl  -0x20(%ebp)
c0105a58:	8d 45 14             	lea    0x14(%ebp),%eax
c0105a5b:	50                   	push   %eax
c0105a5c:	e8 19 fc ff ff       	call   c010567a <getuint>
c0105a61:	83 c4 10             	add    $0x10,%esp
c0105a64:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105a67:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 16;
c0105a6a:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
        number:
            printnum(putch, putdat, num, base, width, padc);
c0105a71:	0f be 55 db          	movsbl -0x25(%ebp),%edx
c0105a75:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105a78:	83 ec 04             	sub    $0x4,%esp
c0105a7b:	52                   	push   %edx
c0105a7c:	ff 75 e8             	pushl  -0x18(%ebp)
c0105a7f:	50                   	push   %eax
c0105a80:	ff 75 f4             	pushl  -0xc(%ebp)
c0105a83:	ff 75 f0             	pushl  -0x10(%ebp)
c0105a86:	ff 75 0c             	pushl  0xc(%ebp)
c0105a89:	ff 75 08             	pushl  0x8(%ebp)
c0105a8c:	e8 f8 fa ff ff       	call   c0105589 <printnum>
c0105a91:	83 c4 20             	add    $0x20,%esp
            break;
c0105a94:	eb 39                	jmp    c0105acf <vprintfmt+0x39b>

        // escaped '%' character
        case '%':
            putch(ch, putdat);
c0105a96:	83 ec 08             	sub    $0x8,%esp
c0105a99:	ff 75 0c             	pushl  0xc(%ebp)
c0105a9c:	53                   	push   %ebx
c0105a9d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105aa0:	ff d0                	call   *%eax
c0105aa2:	83 c4 10             	add    $0x10,%esp
            break;
c0105aa5:	eb 28                	jmp    c0105acf <vprintfmt+0x39b>

        // unrecognized escape sequence - just print it literally
        default:
            putch('%', putdat);
c0105aa7:	83 ec 08             	sub    $0x8,%esp
c0105aaa:	ff 75 0c             	pushl  0xc(%ebp)
c0105aad:	6a 25                	push   $0x25
c0105aaf:	8b 45 08             	mov    0x8(%ebp),%eax
c0105ab2:	ff d0                	call   *%eax
c0105ab4:	83 c4 10             	add    $0x10,%esp
            for (fmt --; fmt[-1] != '%'; fmt --)
c0105ab7:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
c0105abb:	eb 04                	jmp    c0105ac1 <vprintfmt+0x38d>
c0105abd:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
c0105ac1:	8b 45 10             	mov    0x10(%ebp),%eax
c0105ac4:	83 e8 01             	sub    $0x1,%eax
c0105ac7:	0f b6 00             	movzbl (%eax),%eax
c0105aca:	3c 25                	cmp    $0x25,%al
c0105acc:	75 ef                	jne    c0105abd <vprintfmt+0x389>
                /* do nothing */;
            break;
c0105ace:	90                   	nop
        }
    }
c0105acf:	e9 68 fc ff ff       	jmp    c010573c <vprintfmt+0x8>
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
            if (ch == '\0') {
                return;
c0105ad4:	90                   	nop
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
c0105ad5:	8d 65 f8             	lea    -0x8(%ebp),%esp
c0105ad8:	5b                   	pop    %ebx
c0105ad9:	5e                   	pop    %esi
c0105ada:	5d                   	pop    %ebp
c0105adb:	c3                   	ret    

c0105adc <sprintputch>:
 * sprintputch - 'print' a single character in a buffer
 * @ch:         the character will be printed
 * @b:          the buffer to place the character @ch
 * */
static void
sprintputch(int ch, struct sprintbuf *b) {
c0105adc:	55                   	push   %ebp
c0105add:	89 e5                	mov    %esp,%ebp
    b->cnt ++;
c0105adf:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105ae2:	8b 40 08             	mov    0x8(%eax),%eax
c0105ae5:	8d 50 01             	lea    0x1(%eax),%edx
c0105ae8:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105aeb:	89 50 08             	mov    %edx,0x8(%eax)
    if (b->buf < b->ebuf) {
c0105aee:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105af1:	8b 10                	mov    (%eax),%edx
c0105af3:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105af6:	8b 40 04             	mov    0x4(%eax),%eax
c0105af9:	39 c2                	cmp    %eax,%edx
c0105afb:	73 12                	jae    c0105b0f <sprintputch+0x33>
        *b->buf ++ = ch;
c0105afd:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105b00:	8b 00                	mov    (%eax),%eax
c0105b02:	8d 48 01             	lea    0x1(%eax),%ecx
c0105b05:	8b 55 0c             	mov    0xc(%ebp),%edx
c0105b08:	89 0a                	mov    %ecx,(%edx)
c0105b0a:	8b 55 08             	mov    0x8(%ebp),%edx
c0105b0d:	88 10                	mov    %dl,(%eax)
    }
}
c0105b0f:	90                   	nop
c0105b10:	5d                   	pop    %ebp
c0105b11:	c3                   	ret    

c0105b12 <snprintf>:
 * @str:        the buffer to place the result into
 * @size:       the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * */
int
snprintf(char *str, size_t size, const char *fmt, ...) {
c0105b12:	55                   	push   %ebp
c0105b13:	89 e5                	mov    %esp,%ebp
c0105b15:	83 ec 18             	sub    $0x18,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
c0105b18:	8d 45 14             	lea    0x14(%ebp),%eax
c0105b1b:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vsnprintf(str, size, fmt, ap);
c0105b1e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105b21:	50                   	push   %eax
c0105b22:	ff 75 10             	pushl  0x10(%ebp)
c0105b25:	ff 75 0c             	pushl  0xc(%ebp)
c0105b28:	ff 75 08             	pushl  0x8(%ebp)
c0105b2b:	e8 0b 00 00 00       	call   c0105b3b <vsnprintf>
c0105b30:	83 c4 10             	add    $0x10,%esp
c0105b33:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
c0105b36:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0105b39:	c9                   	leave  
c0105b3a:	c3                   	ret    

c0105b3b <vsnprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want snprintf() instead.
 * */
int
vsnprintf(char *str, size_t size, const char *fmt, va_list ap) {
c0105b3b:	55                   	push   %ebp
c0105b3c:	89 e5                	mov    %esp,%ebp
c0105b3e:	83 ec 18             	sub    $0x18,%esp
    struct sprintbuf b = {str, str + size - 1, 0};
c0105b41:	8b 45 08             	mov    0x8(%ebp),%eax
c0105b44:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0105b47:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105b4a:	8d 50 ff             	lea    -0x1(%eax),%edx
c0105b4d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105b50:	01 d0                	add    %edx,%eax
c0105b52:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105b55:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if (str == NULL || b.buf > b.ebuf) {
c0105b5c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0105b60:	74 0a                	je     c0105b6c <vsnprintf+0x31>
c0105b62:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0105b65:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105b68:	39 c2                	cmp    %eax,%edx
c0105b6a:	76 07                	jbe    c0105b73 <vsnprintf+0x38>
        return -E_INVAL;
c0105b6c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
c0105b71:	eb 20                	jmp    c0105b93 <vsnprintf+0x58>
    }
    // print the string to the buffer
    vprintfmt((void*)sprintputch, &b, fmt, ap);
c0105b73:	ff 75 14             	pushl  0x14(%ebp)
c0105b76:	ff 75 10             	pushl  0x10(%ebp)
c0105b79:	8d 45 ec             	lea    -0x14(%ebp),%eax
c0105b7c:	50                   	push   %eax
c0105b7d:	68 dc 5a 10 c0       	push   $0xc0105adc
c0105b82:	e8 ad fb ff ff       	call   c0105734 <vprintfmt>
c0105b87:	83 c4 10             	add    $0x10,%esp
    // null terminate the buffer
    *b.buf = '\0';
c0105b8a:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105b8d:	c6 00 00             	movb   $0x0,(%eax)
    return b.cnt;
c0105b90:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0105b93:	c9                   	leave  
c0105b94:	c3                   	ret    
