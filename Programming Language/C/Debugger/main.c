#include <stdio.h>
void Print(int i)
{
    printf("hello GDB测试 %d\n", i);
}
int main(int argc, char const *argv[])
{
    int i = 0;
    for (i = 1; i < 3; i++)
    {
        Print(i);
    }
    return 0;
}