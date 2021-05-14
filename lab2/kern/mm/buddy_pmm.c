#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
//���Բο����ϵ�һЩ�궨��
#define LEFT_LEAF(index) ((index) * 2 + 1)
#define RIGHT_LEAF(index) ((index) * 2 + 2)
#define PARENT(index) ( ((index) + 1) / 2 - 1)

#define IS_POWER_OF_2(x) (!((x)&((x)-1)))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define UINT32_SHR_OR(a,n)      ((a)|((a)>>(n)))//����nλ  

#define UINT32_MASK(a)          (UINT32_SHR_OR(UINT32_SHR_OR(UINT32_SHR_OR(UINT32_SHR_OR(UINT32_SHR_OR(a,1),2),4),8),16))    
#define UINT32_REMAINDER(a)     ((a)&(UINT32_MASK(a)>>1))
#define UINT32_ROUND_DOWN(a)    (UINT32_REMAINDER(a)?((a)-UINT32_REMAINDER(a)):(a))//С��a������2^k
//����size����С2���ݴ�
static unsigned fixsize(unsigned size) {
    size |= size >> 1;
    size |= size >> 2;
    size |= size >> 4;
    size |= size >> 8;
    size |= size >> 16;
    return size + 1;
}
//ÿ���ڵ������size��Ϊ0�����������ڵ��ڹ����ڴ棬longest��������ڵ�����ڴ�Ĵ�С
struct buddy2 {
    unsigned size;//���������ڴ�
    unsigned longest;
};
struct buddy2 root[80000];//��Ŷ����������飬�����ڴ����

free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

struct allocRecord//��¼��������Ϣ
{
    struct Page* base;
    int offset;
    size_t nr;//���С
};

struct allocRecord rec[80000];//���ƫ����������
int nr_block;//�ѷ���Ŀ���

static void buddy_init()
{
    list_init(&free_list);
    nr_free = 0;
}

//��ʼ���������ϵĽڵ�
void buddy2_new(int size) {
    unsigned node_size;
    int i;
    nr_block = 0;
    if (size < 1 || !IS_POWER_OF_2(size))//�����ڻ�δ���䣬�ټ�
        return;

    root[0].size = size;//���ڵ�������õĿ���ҳ��
    node_size = size * 2;//����*2��Ϊ�������ѭ����ʼ��root��longest

    for (i = 0; i < 2 * size - 1; ++i) {
        if (IS_POWER_OF_2(i + 1))
            node_size /= 2;
        root[i].longest = node_size;
    }
    return;
}

//��ʼ���ڴ�ӳ���ϵ
static void
buddy_init_memmap(struct Page* base, size_t n)
{
    assert(n > 0);
    struct Page* p = base;
    for (; p != base + n; p++)
    {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 1;
        set_page_ref(p, 0);
        SetPageProperty(p);//��ÿ������ҳ����Ϊ��
        list_add_before(&free_list, &(p->page_link));//��ÿ��page����ձ�
    }
    nr_free += n;
    int allocpages = UINT32_ROUND_DOWN(n);//��size��2���ݴ�����ȡ��
    buddy2_new(allocpages);
}
//�ڴ����
int buddy2_alloc(struct buddy2* self, int size) {//self=root
    unsigned index = 0;//�ڵ�ı��
    unsigned node_size;
    unsigned offset = 0;

    if (self == NULL)//�޷�����
        return -1;

    if (size <= 0)//���䲻����
        size = 1;
    else if (!IS_POWER_OF_2(size))//��Ϊ2����ʱ��ȡ��size�����2��n����
        size = fixsize(size);

    if (self[index].longest < size)//�ɷ����ڴ治��
        return -1;

    for (node_size = self->size; node_size != size; node_size /= 2) {
        if (self[LEFT_LEAF(index)].longest >= size)
        {
            if (self[RIGHT_LEAF(index)].longest >= size)
            {
                index = self[LEFT_LEAF(index)].longest <= self[RIGHT_LEAF(index)].longest ? LEFT_LEAF(index) : RIGHT_LEAF(index);
                //�ҵ���������ϵĽڵ����ڴ��С�Ľ��
            }
            else
            {
                index = LEFT_LEAF(index);
            }
        }
        else
            index = RIGHT_LEAF(index);
    }

    self[index].longest = 0;//��ǽڵ�Ϊ��ʹ��
    offset = (index + 1) * node_size - self->size;
    while (index) {
        index = PARENT(index);
        self[index].longest =
            MAX(self[LEFT_LEAF(index)].longest, self[RIGHT_LEAF(index)].longest);
    }
    //����ˢ�£��޸����������ֵ
    return offset;
}

static struct Page*
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free)
        return NULL;
    struct Page* page = NULL;
    struct Page* p;
    list_entry_t* le = &free_list, * len;
    rec[nr_block].offset = buddy2_alloc(root, n);//��¼ƫ����
    int i;
    for (i = 0; i < rec[nr_block].offset + 1; i++)
        le = list_next(le);
    page = le2page(le, page_link);
    int allocpages;
    if (!IS_POWER_OF_2(n))
        allocpages = fixsize(n);
    else
    {
        allocpages = n;
    }
    //��������n�õ����С
    rec[nr_block].base = page;//��¼�������ҳ
    rec[nr_block].nr = allocpages;//��¼�����ҳ��
    nr_block++;
    for (i = 0; i < allocpages; i++)
    {
        len = list_next(le);
        p = le2page(le, page_link);
        ClearPageProperty(p);
        le = len;
    }//�޸�ÿһҳ��״̬
    nr_free -= allocpages;//��ȥ�ѱ������ҳ��
    page->property = n;//���п��õ���Ŀ                                  
    return page;
}

void buddy_free_pages(struct Page* base, size_t n) {
    unsigned node_size, index = 0;
    unsigned left_longest, right_longest;
    struct buddy2* self = root;

    list_entry_t* le = list_next(&free_list);
    int i = 0;
    for (i = 0; i < nr_block; i++)//�ҵ���
    {
        if (rec[i].base == base)
            break;
    }
    int offset = rec[i].offset;
    int pos = i;//�ݴ�i
    i = 0;
    while (i < offset)
    {
        le = list_next(le);
        i++;
    }
    int allocpages;
    if (!IS_POWER_OF_2(n))
        allocpages = fixsize(n);
    else
    {
        allocpages = n;
    }
    assert(self && offset >= 0 && offset < self->size);//�Ƿ�Ϸ�
    node_size = 1;
    index = offset + self->size - 1;
    nr_free += allocpages;//���¿���ҳ������
    struct Page* p;
    self[index].longest = allocpages;
    for (i = 0; i < allocpages; i++)//�����ѷ����ҳ
    {
        p = le2page(le, page_link);
        p->flags = 0;
        p->property = 1;
        SetPageProperty(p);
        le = list_next(le);
    }
    while (index) {//���Ϻϲ����޸�����ڵ�ļ�¼ֵ
        index = PARENT(index);
        node_size *= 2;

        left_longest = self[LEFT_LEAF(index)].longest;
        right_longest = self[RIGHT_LEAF(index)].longest;

        if (left_longest + right_longest == node_size)
            self[index].longest = node_size;
        else
            self[index].longest = MAX(left_longest, right_longest);
    }
    for (i = pos; i < nr_block - 1; i++)//����˴εķ����¼
    {
        rec[i] = rec[i + 1];
    }
    nr_block--;//���·��������ֵ
}

static size_t
buddy_nr_free_pages(void) {
    return nr_free;
}

//������һ�����Ժ���
static void
      buddy_check(void) {
    struct Page* p0, * A, * B, * C, * D;
    p0 = A = B = C = D = NULL;

    assert((p0 = alloc_page()) != NULL);
    assert((A = alloc_page()) != NULL);
    assert((B = alloc_page()) != NULL);

    assert(p0 != A && p0 != B && A != B);
    assert(page_ref(p0) == 0 && page_ref(A) == 0 && page_ref(B) == 0);
    free_page(p0);
    free_page(A);
    free_page(B);

    A = alloc_pages(500);
    B = alloc_pages(500);
    cprintf("A %p\n", A);
    cprintf("B %p\n", B);
    free_pages(A, 250);
    free_pages(B, 500);
    free_pages(A + 250, 250);

    p0 = alloc_pages(1024);
    cprintf("p0 %p\n", p0);
    assert(p0 == A);
    //�����Ǹ��������е��������Ա�д��
    A = alloc_pages(70);
    B = alloc_pages(35);
    assert(A + 128 == B);//����Ƿ�����
    cprintf("A %p\n", A);
    cprintf("B %p\n", B);
    C = alloc_pages(80);
    assert(A + 256 == C);//���C��û�к�A�ص�
    cprintf("C %p\n", C);
    free_pages(A, 70);//�ͷ�A
    cprintf("B %p\n", B);
    D = alloc_pages(60);
    cprintf("D %p\n", D);
    assert(B + 64 == D);//���B��D�Ƿ�����
    free_pages(B, 35);
    cprintf("D %p\n", D);
    free_pages(D, 60);
    cprintf("C %p\n", C);
    free_pages(C, 80);
    free_pages(p0, 1000);//ȫ���ͷ�
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
