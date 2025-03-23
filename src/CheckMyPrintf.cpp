#include <stdio.h>
#include "COLOR.h"
extern "C" void MyPrintf(const char* format, ...);

int main ()
{
    MyPrintf ("%t\n", 0xDED);

    // MyPrintf ("\n\t\t\t\t"  "My printf ():"  "\n"
    //           "\t\t\tFirst    arg: "  "%x"  "\n"
    //           "\t\t\tSecond   arg: "  "%o"  "\n"
    //           "\t\t\tThird    arg: "  "%b"  "\n"
    //           "\t\t\tFourth   arg: "  "%c"  "\n"
    //           "\t\t\tFifth    arg: "  "%b"  "\n"
    //           "\t\t\tSixth    arg: "  "%x"  "\n"
    //           "\t\t\tSeventh  arg: "  "%c"  "\n"
    //           "\t\t\tEigth    arg: "  "%b"  "\n", 0x34, 01234567, 0b100100100100, 65, 25, 0xDED, 33, 0b1010);

    // MyPrintf ("\n\t\t\t\t" YELLOW "My printf ():" RESET "\n"
    //         "\t\t\tFirst    arg: " GREEN "%x" RESET "\n"
    //         "\t\t\tSecond   arg: " GREEN "%o" RESET "\n"
    //         "\t\t\tThird    arg: " GREEN "%b" RESET "\n"
    //         "\t\t\tFourth   arg: " GREEN "%c" RESET "\n"
    //         "\t\t\tFifth    arg: " GREEN "%b" RESET "\n"
    //         "\t\t\tSixth    arg: " GREEN "%x" RESET "\n"
    //         "\t\t\tSeventh  arg: " GREEN "%c" RESET "\n"
    //         "\t\t\tEigth    arg: " GREEN "%b" RESET "\n\n", 0x34, 01234567, 0b100100100100, 65, 25, 0xDED, 33, 0b1010);

    // printf ("\n\t\t\t\t" YELLOW "Std printf ():" RESET "\n"
    //           "\t\t\tFirst    arg: " GREEN "%x" RESET "\n"
    //           "\t\t\tSecond   arg: " GREEN "%o" RESET "\n"
    //           "\t\t\tThird    arg: " GREEN "%b" RESET "\n"
    //           "\t\t\tFourth   arg: " GREEN "%c" RESET "\n"
    //           "\t\t\tFifth    arg: " GREEN "%b" RESET "\n"
    //           "\t\t\tSixth    arg: " GREEN "%x" RESET "\n"
    //           "\t\t\tSeventh  arg: " GREEN "%c" RESET "\n"
    //           "\t\t\tEigth    arg: " GREEN "%b" RESET "\n\n", 0x34, 01234567, 0b100100100100, 65, 25, 0xDED, 33, 0b1010);

}

